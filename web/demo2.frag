precision mediump float;

//#define SHADOW_VSM 1
//#define DISSOLVE
//#define RIMLIGHT
  
const float PI = 3.14159265358979323846264;

varying vec3 vNormal;
varying vec4 vVertex;

uniform mat4 _ViewMatrix;
uniform vec4 _Color;

uniform mat4 lightProj, lightView;
uniform mat3 lightRot;
uniform float lightFar,lightNear;
uniform float lightConeAngle;
uniform sampler2D sLightDepth;



/// Pack a floating point value into an RGBA (32bpp).
/// Used by SSM, PCF, and ESM.
///
/// Note that video cards apply some sort of bias (error?) to pixels,
/// so we must correct for that by subtracting the next component's
/// value from the previous component.
/// @see http://devmaster.net/posts/3002/shader-effects-shadow-mapping#sthash.l86Qm4bE.dpuf
vec4 pack (float depth) {
  const vec4 bias = vec4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
  float r = depth;
  float g = fract(r * 255.0);
  float b = fract(g * 255.0);
  float a = fract(b * 255.0);
  vec4 colour = vec4(r, g, b, a);
  return colour - (colour.yzww * bias);
}


/// Unpack an RGBA pixel to floating point value.
float unpack (vec4 colour) {
  const vec4 bitShifts = vec4(1.0, 1.0 / 255.0, 1.0 / (255.0 * 255.0), 1.0 / (255.0 * 255.0 * 255.0));
  return dot(colour, bitShifts);
}

/// Pack a floating point value into a vec2 (16bpp).
/// Used by VSM.
vec2 packHalf (float depth) {
  const vec2 bias = vec2(1.0 / 255.0, 0.0);
  vec2 colour = vec2(depth, fract(depth * 255.0));
  return colour - (colour.yy * bias);
}

/// Unpack a vec2 to a floating point (used by VSM).
float unpackHalf (vec2 colour) {
  return colour.x + (colour.y / 255.0);
}

float depthOf(vec3 lPosition) {
  //float depth = lPosition.z / lightFar;
  float depth = (length(lPosition) - lightNear)/(lightFar - lightNear);
  return clamp(depth, 0.0, 1.0);
}

vec2 depthUV(vec3 lPosition) {
  vec4 lightDevice = lightProj * vec4(lPosition, 1.0);
  vec2 lightDeviceNormal = lightDevice.xy/lightDevice.w;
  return lightDeviceNormal*0.5+0.5;
}

vec4 depthFromTexture(vec3 lPosition) {
  return texture2D(sLightDepth, depthUV(lPosition));
}

/// Calculate Chebychev's inequality.
///  moments.x = mean
///  moments.y = mean^2
///  `t` Current depth value.
/// returns The upper bound (0.0, 1.0), or rather the amount
/// to shadow the current fragment colour.
float ChebychevInequality (vec2 moments, float t) {
  // No shadow if depth of fragment is in front
  if ( t <= moments.x ) return 1.0;
  // Calculate variance, which is actually the amount of
  // error due to precision loss from fp32 to RG/BA
  // (moment1 / moment2)
  float variance = moments.y - (moments.x * moments.x);
  variance = max(variance, 0.02);
  // Calculate the upper bound
  float d = t - moments.x;
  return variance / (variance + d * d);
}

/// VSM can suffer from light bleeding when shadows overlap. This method
/// tweaks the chebychev upper bound to eliminate the bleeding, but at the
/// expense of creating a shadow with sharper, darker edges.
float VsmFixLightBleed (float pMax, float amount) {
  return clamp((pMax - amount) / (1.0 - amount), 0.0, 1.0);
}
 
float shadowOf(vec3 lPosition) {
  vec4 texel = depthFromTexture(lPosition);
  float depth = depthOf(lPosition);

#ifdef SHADOW_VSM
  // Variance shadow map algorithm
  vec2 moments = vec2(unpackHalf(texel.xy), unpackHalf(texel.zw));
  return ChebychevInequality(moments, depth);
  //shadow = VsmFixLightBleed(shadow, 0.1);
#else
  // hard shadow
  float bias = 0.01;
  return step(depth, unpack(texel) + bias);
#endif
}

float attenuation(vec3 dir){
  float dist = length(dir);
  float radiance = 1.0/(1.0+pow(dist/10.0, 2.0));
  return clamp(radiance*10.0, 0.0, 1.0);
}
  
float influence(vec3 normal, float coneAngle){
  float minConeAngle = ((360.0-coneAngle-10.0)/360.0)*PI;
  float maxConeAngle = ((360.0-coneAngle)/360.0)*PI;
  return smoothstep(minConeAngle, maxConeAngle, acos(normal.z));
}

float lambert(vec3 surfaceNormal, vec3 lightDirNormal){
  return max(0.0, dot(surfaceNormal, lightDirNormal));
}
  
vec3 skyLight(vec3 normal){
  return vec3(smoothstep(0.0, PI, PI-acos(normal.y)))*0.4;
}


const float rimStart = 0.5;
const float rimEnd = 1.0;
const float rimMultiplier = 0.1;
vec3  rimColor = vec3(0.0, 0.0, 0.5);

vec3 rimLight(vec3 viewPos, vec3 normal, vec3 position) {
  float normalToCam = 1.0 - dot(normalize(normal), normalize(viewPos.xyz - position.xyz));
  float rim = smoothstep(rimStart, rimEnd, normalToCam) * rimMultiplier;
  return (rimColor * rim);
}

uniform float time;

varying vec2 vTexCoord0;
uniform sampler2D _DissolveMap0;
uniform sampler2D _DissolveMap1;
uniform sampler2D _DissolveMap2;

float dissolve(float threshold, vec2 uv, sampler2D dissolveMap) {
  float v = texture2D(dissolveMap, uv).r;
  if (v < threshold) discard;
  return v;
}

void main(){
  vec3 normal = normalize(vNormal);
  
  vec3 camPos = (_ViewMatrix * vVertex).xyz;
  vec3 lPosition = (lightView * vVertex).xyz;
  vec3 lightPosNormal = normalize(lPosition);
  vec3 lightSurfaceNormal = lightRot * normal;

  // shadow calculation
  float lighting = (
    lambert(lightSurfaceNormal, -lightPosNormal) *
    influence(lightPosNormal, lightConeAngle) *
    attenuation(lPosition) *
    shadowOf(lPosition)
  );
  float r = 0.0;
#ifdef DISSOLVE
  r = mod(time,1000.0)/1000.0;
  float v = dissolve(r, vTexCoord0, _DissolveMap0);
  r = ((v - r) < 0.05)? r : 0.0;
#endif  
  vec3 excident = (
    skyLight(normal) +
#ifdef RIMLIGHT    
    rimLight(camPos, normal, vVertex.xyz) +
#endif
    clamp(lighting, 0.6, 1.0) * _Color.rgb
  );

  gl_FragColor.rgb = excident;
  gl_FragColor.r += r;
  gl_FragColor.a = _Color.a;
}
