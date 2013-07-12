#ifdef GL_ES
precision highp float;
#endif

varying vec4 vColor;

//uniform sampler2D _Tex0;
//uniform sampler2D _Tex1;
//...
//uniform sampler2D _Tex31;

void main(void) {
  gl_FragColor = vColor;
} 