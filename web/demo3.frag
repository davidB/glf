#ifdef GL_ES
precision highp float;
#endif

varying vec4 vColor;
varying vec4 vNormal;

//uniform sampler2D _Tex0;
//uniform sampler2D _Tex1;
uniform sampler2D _Tex3;
//...
//uniform sampler2D _Tex31;

void main(void) {
  vec3 diffuseColor = texture2D(_Tex3, vec2(normalize(vNormal).xyz * vec3(0.495) + vec3(0.5))).rgb;
  //gl_FragColor = vColor;
  gl_FragColor.rgb = diffuseColor;
  gl_FragColor.a = 1.0;
} 