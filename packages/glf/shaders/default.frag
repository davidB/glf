precision highp float;

uniform vec4 _Color;

//uniform sampler2D _Tex0;
//uniform sampler2D _Tex1;
//...
//uniform sampler2D _Tex31;

void main(void) {
  gl_FragColor = _Color;
} 