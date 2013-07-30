#ifdef GL_ES
precision mediump float;
#endif

const float PI = 3.14159265358979323846264;

varying vec3 normal;
varying vec4 position;

uniform mat4 _ViewMatrix;
uniform mat4 lightProj, lightView;
uniform mat3 lightRot;
uniform float lightFar;
uniform float lightConeAngle;
uniform sampler2D sLightDepth;
uniform vec3 _Color;

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

void main(){
  vec3 worldNormal = normalize(normal);

  vec3 camPos = (_ViewMatrix * position).xyz;
  vec3 lightPos = (lightView * position).xyz;
  vec3 lightPosNormal = normalize(lightPos);
  vec3 lightSurfaceNormal = lightRot * worldNormal;
  vec4 lightDevice = lightProj * vec4(lightPos, 1.0);
  vec2 lightDeviceNormal = lightDevice.xy/lightDevice.w;
  vec2 lightUV = lightDeviceNormal*0.5+0.5;

  // shadow calculation
  float lightDepth1 = texture2D(sLightDepth, lightUV).r;
  float lightDepth2 = clamp(length(lightPos)/(lightFar * 1.01), 0.0, 1.0);
  float bias = 0.001;
  float illuminated = step(lightDepth2, lightDepth1+bias);
  
  vec3 excident = (
    skyLight(worldNormal) +
    lambert(lightSurfaceNormal, -lightPosNormal) *
    influence(lightPosNormal, lightConeAngle) *
    attenuation(lightPos) *
    illuminated * _Color
  );
  gl_FragColor = vec4(gamma(excident), 1.0);
}
