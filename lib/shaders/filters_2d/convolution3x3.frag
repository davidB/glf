// from http://www.html5rocks.com/en/tutorials/webgl/webgl_fundamentals/
precision mediump float;

uniform sampler2D _Tex0;
varying vec2 vTexCoord0;
uniform vec3 _PixelSize; // (1.0/width, 1.0/height, width/height)
uniform float _Kernel[9];

vec3 convolution(sampler2D image, vec2 uv, vec2 onePixel, float kernel[9]) {
  vec4 colorSum =
    texture2D(image, uv + onePixel * vec2(-1, -1)) * kernel[0] +
    texture2D(image, uv + onePixel * vec2( 0, -1)) * kernel[1] +
    texture2D(image, uv + onePixel * vec2( 1, -1)) * kernel[2] +
    texture2D(image, uv + onePixel * vec2(-1,  0)) * kernel[3] +
    texture2D(image, uv + onePixel * vec2( 0,  0)) * kernel[4] +
    texture2D(image, uv + onePixel * vec2( 1,  0)) * kernel[5] +
    texture2D(image, uv + onePixel * vec2(-1,  1)) * kernel[6] +
    texture2D(image, uv + onePixel * vec2( 0,  1)) * kernel[7] +
    texture2D(image, uv + onePixel * vec2( 1,  1)) * kernel[8] ;
  float kernelWeight =
    kernel[0] +
    kernel[1] +
    kernel[2] +
    kernel[3] +
    kernel[4] +
    kernel[5] +
    kernel[6] +
    kernel[7] +
    kernel[8] ;

  if (kernelWeight <= 0.0) {
    kernelWeight = 1.0;
  }

  // Divide the sum by the weight but just use rgb
  return (colorSum / kernelWeight).rgb;
}

void main(void) {
  gl_FragColor.rgb = convolution(_Tex0, vTexCoord0, _PixelSize.xy, _Kernel);
  //gl_FragColor.r =_PixelSize.y * 100.0; 
  gl_FragColor.a = 1.0;
}