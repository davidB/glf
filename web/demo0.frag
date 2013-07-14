#ifdef GL_ES
precision mediump float;
#endif

varying vec2 vTexCoord0;
varying vec3 vNormal;
varying vec3 vLightColor;
varying vec3 vLightDirection;

uniform sampler2D _Tex0;
uniform sampler2D _Tex1;

void main(void) {
  //vec4 normalColor = texture2D(_Tex1, vec2(vTexCoord0.s, vTexCoord0.t));
  vec3 normal = vNormal;
  //vec3 normal = normalColor.xyz * vNormal;
  float finalDirection = max(dot(normal, vLightDirection), 0.0);
  vec3 vLightLevel = finalDirection * vLightColor;
  vec4 texelColor = texture2D(_Tex0, vec2(vTexCoord0.s, vTexCoord0.t));
  //vec4 texelColor = vec4(0.5, 1.0, 1.0, 0.5);
  //gl_FragColor = texelColor;
  gl_FragColor = vec4(texelColor.rgb /** vLightLevel*/, texelColor.a);
}