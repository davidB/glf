precision highp float;

#define NORMALMAP

varying vec4 vColor;
varying vec3 vNormal;
varying vec2 vTexCoord0;
varying vec2 vViewDirN;

//uniform sampler2D _Tex0;
//uniform sampler2D _Tex1;
//uniform sampler2D _Tex3;
//...
//uniform sampler2D _Tex31;
uniform sampler2D _MatCap0;
uniform sampler2D _MatCap1;
uniform sampler2D _MatCap2;

#ifdef NORMALMAP
uniform sampler2D _NormalMap0;
varying vec3 mat;
#endif


void main(void) {
#ifdef NORMALMAP
  vec3 normalM = normalize(texture2D(_NormalMap0, vTexCoord0).rgb * 2.0 - 1.0);
  vec3 normal = normalize(mat * normalM);
#else  
  vec3 normal = normalize(vNormal);
#endif
  vec3 diffuseColor = texture2D(_MatCap0, vec2(normal * vec3(0.495) + vec3(0.5))).rgb;
  //gl_FragColor = vColor;
  gl_FragColor.rgb = diffuseColor;
  gl_FragColor.a = 1.0;
} 