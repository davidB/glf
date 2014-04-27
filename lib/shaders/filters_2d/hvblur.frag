// from http://www.gamerendering.com/2008/10/11/gaussian-radius-filter-shader/
// from https://github.com/mattdesl/lwjgl-basics/wiki/ShaderLesson5
// for an other (more perf) try http://xissburg.com/faster-gaussian-radius-in-glsl/
precision mediump float;

uniform sampler2D _Tex0;
varying vec2 vTexCoord0;
uniform vec3 _PixelSize; // (1.0/width, 1.0/height, width/height)

uniform float radius;
uniform vec2 dir;

void main() {

    //our original texcoord for this fragment
    vec2 tc = vTexCoord0;

    //the amount to radius, i.e. how far off center to sample from 
    //1.0 -> radius by one pixel
    //2.0 -> radius by two pixels, etc.

    //the direction of our radius
    //(1.0, 0.0) -> x-axis radius
    //(0.0, 1.0) -> y-axis radius
    float hstep = dir.x * _PixelSize.x;
    float vstep = dir.y * _PixelSize.y;

    //apply radiusring, using a 9-tap filter with predefined gaussian weights

    vec4 sum = vec4(0.0);
    sum += texture2D(_Tex0, vec2(tc.x - 4.0*radius*hstep, tc.y - 4.0*radius*vstep)) * 0.0162162162;
    sum += texture2D(_Tex0, vec2(tc.x - 3.0*radius*hstep, tc.y - 3.0*radius*vstep)) * 0.0540540541;
    sum += texture2D(_Tex0, vec2(tc.x - 2.0*radius*hstep, tc.y - 2.0*radius*vstep)) * 0.1216216216;
    sum += texture2D(_Tex0, vec2(tc.x - 1.0*radius*hstep, tc.y - 1.0*radius*vstep)) * 0.1945945946;

    sum += texture2D(_Tex0, vec2(tc.x, tc.y)) * 0.2270270270;

    sum += texture2D(_Tex0, vec2(tc.x + 1.0*radius*hstep, tc.y + 1.0*radius*vstep)) * 0.1945945946;
    sum += texture2D(_Tex0, vec2(tc.x + 2.0*radius*hstep, tc.y + 2.0*radius*vstep)) * 0.1216216216;
    sum += texture2D(_Tex0, vec2(tc.x + 3.0*radius*hstep, tc.y + 3.0*radius*vstep)) * 0.0540540541;
    sum += texture2D(_Tex0, vec2(tc.x + 4.0*radius*hstep, tc.y + 4.0*radius*vstep)) * 0.0162162162;

    gl_FragColor = vec4(sum.rgb, 1.0);
}