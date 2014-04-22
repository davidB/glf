/// Fragment shader to modify brightness, contrast, and gamma of an image.
/// See :
/// * because webgl doesn't have SRGB like in
///   http://gamedevelopment.tutsplus.com/articles/gamma-correction-and-why-it-matters--gamedev-14466
/// * http://devmaster.net/posts/3022/shader-effects-gamma-correction
/// * http://devmaster.net/posts/3095/shader-effects-screen-space-ambient-occlusion
precision highp float;

const vec3 vcontrast = vec3(0.5);

uniform float _Brightness; // 0 is the centre. < 0 = darken, > 0 = brighten
uniform float _Contrast; // 0 is the centre. < 0 = lower contrast, > 0 is raise contrast
uniform float _InvGamma; // Inverse gamma correction applied to the pixel
uniform sampler2D _Tex0; // Colour texture to modify
varying vec2 vTexCoord0;

void main () {
  vec4 color = texture2D(_Tex0, vTexCoord0);
  // Adjust the brightness
  color.xyz = color.xyz + _Brightness;
  
  // Adjust the contrast
  color.xyz = (color.xyz - vcontrast) * (_Contrast + 1.0) + vcontrast;
  
  color.xyz = clamp(color.xyz, 0.0, 1.0);
  
  // Apply gamma correction, except for the alpha channel
  color.xyz = pow(color.xyz, vec3(_InvGamma));
  
  gl_FragColor = color;
}