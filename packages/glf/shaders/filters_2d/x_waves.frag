precision highp float;

uniform sampler2D _Tex0;
varying vec2 vTexCoord0;

uniform float _Offset;
 
void main(void) {
  vec2 texcoord = vTexCoord0;
  texcoord.x += sin(texcoord.y * 4.0 * 2.0 * 3.14159 + _Offset) / 100.0;
  gl_FragColor = texture2D(_Tex0, texcoord);
}