/// Fragment shader to modify brightness, contrast, and gamma of an image.
/// See more at: http://devmaster.net/posts/3095/shader-effects-screen-space-ambient-occlusion
precision highp float;

const vec3 vcontrast = vec3(0.5);

uniform float _Brightness; // 0 is the centre. < 0 = darken, > 1 = brighten
uniform float _Contrast; // 1 is the centre. < 1 = lower contrast, > 1 is raise contrast
uniform float _InvGamma; // Inverse gamma correction applied to the pixel
uniform sampler2D _Tex0; // Colour texture to modify
varying vec2 vTexCoord0;
//uniform vec2 _PixelSize; // (1.0/width, 1.0/height)

void main () {
  vec4 color = texture2D(_Tex0, vTexCoord0);
  // Adjust the brightness
  color.xyz = color.xyz + _Brightness;
  
  // Adjust the contrast
  color.xyz = (color.xyz - vcontrast) * _Contrast + vcontrast;
  
  color.xyz = clamp(color.xyz, 0.0, 1.0);
  
  // Apply gamma correction, except for the alpha channel
  color.xyz = pow(color.xyz, vec3(_InvGamma));
  
  gl_FragColor = color;
}