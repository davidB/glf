precision mediump float;


/// LIB BEGIN /////////////////////////////////////////////////////////////////
const float PI = 3.14159265358979323846264;

/// Pack a floating point value into an RGBA (32bpp).
/// Used by SSM, PCF, and ESM.
///
/// Note that video cards apply some sort of bias (error?) to pixels,
/// so we must correct for that by subtracting the next component's
/// value from the previous component.
/// @see http://devmaster.net/posts/3002/shader-effects-shadow-mapping#sthash.l86Qm4bE.dpuf
vec4 pack (float v) {
  const vec4 bias = vec4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
  float r = v;
  float g = fract(r * 255.0);
  float b = fract(g * 255.0);
  float a = fract(b * 255.0);
  vec4 color = vec4(r, g, b, a);
  return color - (color.yzww * bias);
}


/// Unpack an RGBA pixel to floating point value.
float unpack (vec4 color) {
  const vec4 bitShifts = vec4(1.0, 1.0 / 255.0, 1.0 / (255.0 * 255.0), 1.0 / (255.0 * 255.0 * 255.0));
  return dot(color, bitShifts);
}

/// Pack a floating point value into a vec2 (16bpp).
/// Used by VSM.
vec2 packHalf (float v) {
  const vec2 bias = vec2(1.0 / 255.0, 0.0);
  vec2 color = vec2(v, fract(v * 255.0));
  return color - (color.yy * bias);
}

/// Unpack a vec2 to a floating point (used by VSM).
float unpackHalf (vec2 color) {
  return color.x + (color.y / 255.0);
}

float depthOf(vec3 position, float near, float far) {
  //float depth = (position.z - near) / (far - near);
  float depth = (length(position) - near)/(far - near);
  return clamp(depth, 0.0, 1.0);
}

///------------ Light (basic)

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

vec3 gamma(vec3 color){
  return pow(color, vec3(2.2));
}

const float rimStart = 0.5;
const float rimEnd = 1.0;
const float rimMultiplier = 0.1;
vec3  rimColor = vec3(0.0, 0.0, 0.5);

vec3 rimLight(vec3 position, vec3 normal, vec3 viewPos) {
  float normalToCam = 1.0 - dot(normalize(normal), normalize(viewPos.xyz - position.xyz));
  float rim = smoothstep(rimStart, rimEnd, normalToCam) * rimMultiplier;
  return (rimColor * rim);
}

///---------- Depth (for shadow, ...)

vec2 uvProjection(vec3 position, mat4 proj) {
  vec4 device = proj * vec4(position, 1.0);
  vec2 deviceNormal = device.xy / device.w;
  return deviceNormal * 0.5 + 0.5;
}

vec4 valueFromTexture(vec3 position, mat4 proj, sampler2D tex) {
  return texture2D(tex, uvProjection(position, proj));
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
 
float shadowOf(vec3 position, mat4 texProj, sampler2D tex, float near, float far, float bias) {
  vec4 texel = valueFromTexture(position, texProj, tex);
  float depth = depthOf(position, near, far);

#ifdef SHADOW_VSM
  // Variance shadow map algorithm
  vec2 moments = vec2(unpackHalf(texel.xy), unpackHalf(texel.zw));
  return ChebychevInequality(moments, depth);
  //shadow = VsmFixLightBleed(shadow, 0.1);
#else
  // hard shadow
  //float bias = 0.001;
  return step(depth, unpack(texel) + bias);
#endif
}

///--- Animation Effect

//uniform float time;

uniform sampler2D dissolveMap;

float dissolve(float threshold, vec2 uv) {
  float v = texture2D(dissolveMap, uv).r;
  if (v < threshold) discard;
  return v;
}
/// LIB END   /////////////////////////////////////////////////////////////////

//#define SHADOW_VSM

uniform mat4 _ProjectionMatrix, _ViewMatrix;
uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

varying vec4 vVertex;
varying vec3 vNormal;
varying vec2 vTexCoord0;

uniform float lightFar, lightNear;

void main(){
  mat4 lightView = _ViewMatrix;
  vec3 lPosition = (lightView * vVertex).xyz;
  //vec3 lPosition = vVertex.xyz;
  float depth = depthOf(lPosition, lightNear, lightFar);
#ifdef SHADOW_VSM
  float moment2 = depth * depth;
  gl_FragColor = vec4(packHalf(depth), packHalf(moment2));
#else
  gl_FragColor =  pack(depth);
#endif
}

