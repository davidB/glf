precision mediump float;

//uniform vec2 _PixelSize; // (1.0/width, 1.0/height)
uniform sampler2D _Tex0;
varying vec2 vTexCoord0;

void main(void) {
  gl_FragColor = texture2D(_Tex0, vTexCoord0);
}