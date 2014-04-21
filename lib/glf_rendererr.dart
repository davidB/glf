/// see https://www.shadertoy.com/view/Xds3zN
library glf_rendererr;

import 'dart:collection';
import 'dart:html';
import 'dart:web_gl' as webgl;
import 'package:glf/glf.dart' as glf;
import 'package:vector_math/vector_math.dart';
import 'package:html_toolbox/html_toolbox.dart';

const rayMarchingVert0 = glf.Filter2D.VERT_SRC_2D;


/// Pack a floating point value into a vec2 (16bpp).
/// glsl: vec2 packHalf(float v)
packHalf(l) {
  l.add('''
vec2 packHalf(float v) {
  const vec2 bias = vec2(1.0 / 256.0, 0.0);
  vec2 rg = vec2(v, fract(v * 256.0));
  return rg - (rg.gg * bias);
}
''');
}

/// Unpack a vec2 to a floating point (used by VSM).
/// glsl: float unpackHalf(vec2 rg)
unpackHalf(l) {
  l.add('''
float unpackHalf(vec2 rg) {
  return rg.r + (rg.g / 256.0);
}
''');
}

enable_standard_derivatives(l) {
  l.add('''
#ifdef GL_OES_standard_derivatives
#extension GL_OES_standard_derivatives : enable
#endif
  ''');
}
/// Replacement for RSL's 'filterstep()', with fwidth() done right.
/// 'threshold ' is constant , 'value ' is smoothly varying
/// from http://webstaff.itn.liu.se/~stegu/OpenGLinsights/shadertutorial.html
aastep(l) {
  enable_standard_derivatives(l);
  l.add('''
float aastep (float threshold , float value) {
#ifdef GL_OES_standard_derivatives
  float afwidth = 0.7 * length(vec2(dFdx(value), dFdy(value)));
#else
  float afwidth = frequency * (1.0/200.0) / uScale / cos(uYrot);
#endif
  // GLSL 's fwidth(value) is abs(dFdx(value)) + abs(dFdy(value))
  return smoothstep(threshold-afwidth, threshold+afwidth, value);
}
  ''');
}

/// rotate vector
/// see https://code.google.com/p/kri/wiki/Quaternions
/// glsl: vec3 qrot(vec4 q, vec3 v)
qrot(l) {
  l.add('''
vec3 qrot(vec4 q, vec3 v) {
  return v + 2.0*cross(q.xyz, cross(q.xyz,v) + q.w*v);
}
  ''');
}

/// rotate vector
/// glsl: vec3 qrotinv(vec4 q, vec3 v)
qrotinv(l) {
  l.add('''
vec3 qrotinv(vec4 q, vec3 v) {
  vec3 dir = -q.xyz; 
  return v + 2.0*cross(dir, cross(dir,v) + q.w*v);
}
  ''');
}

/// rotate vector (alternative)
/// see https://code.google.com/p/kri/wiki/Quaternions
/// glsl: vec3 qrot_2(vec4 q, vec3 v)
qrot_2(l) {
  l.add('''
vec3 qrot_2(vec4 q, vec3 v) {
  return v*(q.w*q.w - dot(q.xyz,q.xyz)) + 2.0*q.xyz*dot(q.xyz,v) + 2.0*q.w*cross(q.xyz,v);
}
  ''');
}

/// combine quaternions
/// see https://code.google.com/p/kri/wiki/Quaternions
/// glsl: vec4 qmul(vec4 a, vec4 b)
qmul(l) {
  l.add('''
vec4 qmul(vec4 a, vec4 b) {
  return vec4(cross(a.xyz,b.xyz) + a.xyz*b.w + b.xyz*a.w, a.w*b.w - dot(a.xyz,b.xyz));
}
  ''');
}

/// inverse quaternion
/// see https://code.google.com/p/kri/wiki/Quaternions
/// glsl: vec4 qinv(vec4 q)
qinv(l) {
  l.add('''
vec4 qinv(vec4 q) {
  return vec4(-q.xyz,q.w);
}
  ''');
}

/// perspective project
/// see https://code.google.com/p/kri/wiki/Quaternions
/// glsl: vec4 get_projection(vec3 v, vec4 pr)
get_projection(l) {
  l.add('''
vec4 get_projection(vec3 v, vec4 pr) {
  return vec4( v.xy * pr.xy, v.z*pr.z + pr.w, -v.z);
}
  ''');
}

////// transform by Spatial forward
////// see https://code.google.com/p/kri/wiki/Quaternions
//qrot(l) {
//  l.add('''
//vec3 trans_for(vec3 v, Spatial s)       {
//        return qrot(s.rot, v*s.pos.w) + s.pos.xyz;
//}
//  ''');
//}

////// transform by Spatial inverse
////// see https://code.google.com/p/kri/wiki/Quaternions
//trans_inv(l) {
//  l.add('''
//vec3 trans_inv(vec3 v, Spatial s)       {
//        return qrot( vec4(-s.rot.xyz, s.rot.w), (v-s.pos.xyz)/s.pos.w );
//}
//  ''');
//}

/// Distance map contour texturing, Stefan Gustavson 2011
/// from https://github.com/OpenGLInsights/OpenGLInsightsCode/ (public domain)
/// glsl: float sd_tex2d(vec2 st, sampler2D tex, float oneu, float onev, float texw, float texh)
sd_tex2d(l) {
  aastep(l);
  unpackHalf(l);
  l.add(
    '''
float sd_tex2d(vec2 st, sampler2D tex, float oneu, float onev, float texw, float texh) {
  // Scale texcoords to range ([0,texw], [0,texh])
  vec2 uv = st * vec2(texw, texh);

  // Compute texel-local (u,v) coordinates for the four closest texels
  vec2 uv00 = floor(uv - vec2(0.5)); // Lower left corner of lower left texel
  vec2 uvlerp = uv - uv00 - vec2(0.5); // Texel-local lerp blends [0,1]

  // Perform explicit texture interpolation of distance value.
  // This is required for the split RG encoding of the 8.8 fixed-point value,
  // and as a bonus it works around the bad texture interpolation precision
  // in at least some ATI hardware.

  // Center st00 on lower left texel and rescale to [0,1] for texture lookup
  vec2 st00 = (uv00 + vec2(0.5)) * vec2(oneu, onev);

  // Compute interpolated value from four closest 8-bit RGBA texels
  vec4 D00 = texture2D(tex, st00);
  vec4 D10 = texture2D(tex, st00 + vec2(oneu, 0.0));
  vec4 D01 = texture2D(tex, st00 + vec2(0.0, onev));
  vec4 D11 = texture2D(tex, st00 + vec2(oneu, onev));

  //vec4 G = vec4(unpackHalf(D00.rg), unpackHalf(D01.rg), unpackHalf(D10.rg), unpackHalf(D11.rg));
  vec4 G = vec4(D00.b, D01.b, D10.b, D11.b);
  
  // Interpolate along v
  G.xy = mix(G.xz, G.yw, uvlerp.y);
  
  // Interpolate along u
  float g = mix(G.x, G.y, uvlerp.x);

  return g; //aastep(0.0, g);
}
  ''');
}

/// glsl: float sd_tex(vec3 p, sampler2D tex, float dz, float halfz, vec2 offxy, float iu, float u)
sd_tex(int size) {
  return (l) {
    sd_tex2d(l);
    l.add('''
float sd_tex(vec3 p, sampler2D tex, vec3 center, float zSize, float iu, float u) {
  vec3 pt = p - center;
  vec2 st = (pt.xy * iu) * 0.5 + 0.5;
  vec4 data = texture2D(tex, st);
  //float d = unpackHalf(data.rg);
  float d = sd_tex2d(st, tex, 1.0/${size}.0, 1.0/${size}.0, ${size}.0, ${size}.0);
  float z = max(0.0, abs(pt.z) - (zSize * 0.5));
  return sqrt(d * d + z * z);
}
    ''');
  };
}

/// glsl: vec3 n_tex2d(vec3 p, sampler2D tex, vec3 center, float zSize, float iu, float u)
n_tex2d(l) {
  l.add('''
vec3 n_tex2d(vec3 p, sampler2D tex, vec3 center, float zSize, float iu, float u) {
  vec3 pt = p - center;
  float z = max(0.0, abs(pt.z) - (zSize * 0.5));
  if (z > 0.0) {
    return normalize(vec3(0.0, 0.0, pt.z));
  } else {
    vec2 st = (pt.xy * iu) * 0.5 + 0.5;
    vec4 data = texture2D(tex, st);
    return vec3(data.r, data.g, 0.0);
  }
}
  ''');
  return l;
}

/// glsl: float sd_flatFloor(in vec3 p)
sd_flatFloor(h) {
  return (l) => l.add('''
float sd_flatFloor(in vec3 p) {
  return p.z+ $h;
}
  ''');
}

/// glsl: float sd_box(vec3 p, vec3 b)
sd_box(l) {
  l.add('''
float sd_box(vec3 p, vec3 b) {
  vec3 d = abs(p) - b;
  //return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
  return min(max(d.x,max(d.y,d.z)), length(max(d,0.0)));
}
''');
}

/// glsl: float ud_roundBox( vec3 p, vec3 b, float r )
ud_roundBox(l) {
  l.add('''
float ud_roundBox( vec3 p, vec3 b, float r ) {
  return length(max(abs(p)-b,0.0))-r;
}
''');
}

/// glsl: float sd_sphere(in vec3 p, float r)
sd_sphere(l) {
  l.add('''
float sd_sphere(in vec3 p, float r) {
  return length(p)-r;
}
''');
}

/// glsl: float sd_torus( vec3 p, vec2 t )
sd_torus(l) {
  l.add('''
float sd_torus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
  ''');
}

/// glsl: sd_cylinder( vec3 p, float radius, float halfH)
sd_cylinder(l) {
//    float cyl(vec3 p, float r, float c) {
//      return max(length(p.xz)-r, abs(p.y)-c);
//    }
  l.add('''
float sd_cylinder( vec3 p, float radius, float halfH ) {
  return max(length(p.xy)-radius, abs(p.z)-halfH);
}
  ''');
}

/// glsl: float distance2(vec2 v, vec2 w)
distance2(l) {
  l.add('''
float distance2(vec2 v, vec2 w) {
  float x = w.x - v.x;
  float y = w.y - v.y;
  return x * x + y * y;
}
''');
}

/// glsl: float ud_segXY2(vec2 p, vec2 v, vec2 w)
ud_segXY2(l) {
  distance2(l);
  l.add('''
float ud_segXY2(vec2 p, vec2 v, vec2 w) {
  float l = distance2(v, w);
  if (l < 0.001) return distance2(p, v);
  float t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l;
  if (t < 0.0) return distance2(p, v);
  if (t > 1.0) return distance2(p, w);
  return distance2(p, vec2(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)));
}
''');
}

/// glsl: float ud_seg(vec3 p, vec2 v, vec2 w, float dz)
ud_seg(l) {
  ud_segXY2(l);
  l.add('''
float ud_seg(vec3 p, vec2 v, vec2 w, float dz) {
  return sqrt(ud_segXY2(p.xy, v, w));
}
  ''');
}

/// glsl: float sd_segXY(vec2 p, vec2 v, vec2 w)
sd_segXY(l) {
  distance2(l);
  l.add('''
float sd_segXY(vec2 p, vec2 v, vec2 w) {
  float l = distance2(v, w);
  if (l < 0.001) return sqrt(distance2(p, v));
  float t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l;
  if (t < 0.0) return sqrt(distance2(p, v));
  if (t > 1.0) return sqrt(distance2(p, w));
  // dir = sign(dot(normalOf(w-v), (p-v)))
  float dir = sign((p.x - v.x) * (- w.y + v.y) + (p.y - v.y) * (w.x - v.x));
  return dir * sqrt(distance2(p, vec2(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y))));
}
  ''');
}

/// glsl: float sd_lineXY(vec2 p, vec2 v, vec2 w)
sd_lineXY(l) {
  distance2(l);
  l.add('''
float sd_lineXY(vec2 p, vec2 v, vec2 w) {
  float l = distance2(v, w);
  return ((p.x - v.x) * (- w.y + v.y) + (p.y - v.y) * (w.x - v.x)) / sqrt(l);
}     
  ''');
}

/// glsl: color mat_chessboardXY0(in vec3 p)
mat_chessboardXY0(size, Vector4 color0, Vector4 color1) {
  var c = 0.5 / size;
  return (l) => l.add('''
color mat_chessboardXY0(in vec3 p) {
  //float m = p.x + p.y; // pattern for line
  //float m = fract(p.x) + fract(p.y); // pattern for triangle + m > 1.0
  float m = step(0.5, fract(p.x * $c)) + step(0.5, fract(p.y * $c)) ;
  return mix(vec4(${color1.r}, ${color1.g}, ${color1.b}, ${color1.a}), vec4(${color0.r}, ${color0.g}, ${color0.b}, ${color0.a}) ,m);
}
''');
}

/// glsl: color mat_chessboardXY1(in vec3 p)
mat_chessboardXY1(ratiox, ratioy, Vector4 color0, Vector4 color1, Vector4 color2, Vector4 color3) {
  return (l) => l.add('''
color mat_chessboardXY1(in vec3 p){
  if (fract(p.x*$ratiox)>$ratiox){
    if (fract(p.y*$ratioy)>$ratioy)
      return vec4(${color0.r}, ${color0.g}, ${color0.b}, ${color0.a});
    else
      return vec4(${color1.r}, ${color1.g}, ${color1.b}, ${color1.a});
  } else {
    if (fract(p.y*$ratioy)>$ratioy)
      return vec4(${color2.r}, ${color2.g}, ${color2.b}, ${color2.a});
    else
      return vec4(${color3.r}, ${color3.g}, ${color3.b}, ${color3.a});
   }
}
''');
}

const sdHeaderFrag0 = '''
// based on
// http://geeks3d.developpez.com/GLSL/raymarching/
// http://9bitscience.blogspot.fr/2013/07/raymarching-distance-fields_14.html
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// https://www.shadertoy.com/view/MsXGWr
precision mediump float;

const float PI = 3.14159265358979323846264;
const float surface = 0.001;
const vec3 eps = vec3(surface*0.5,0.0,0.0);

\${obj_uniforms}

varying vec2 vTexCoord0;
uniform vec3 ${glf.SFNAME_PIXELSIZE};
uniform vec3 ${glf.SFNAME_VIEWPOSITION}, ${glf.SFNAME_VIEWUP}, ${glf.SFNAME_FOCUSPOSITION};
uniform float ${glf.SFNAME_NEAR}, ${glf.SFNAME_FAR};

// ro  : the ray origin position (eg: the camera position)
// rd  : the ray direction for the current pixel
// rd0 : the camera direction (that is the ray direction at the center of the screen) 
// t   : distance traveled
// p   : a position 3D
// de(): distance estimator function (~ map() or f())
// sd_xxxx() : a signed distance function
// ud_xxxx() : a unisigned distance function
// o   : an object
// obj.x : distance of the object
// obj.y : id of the object 's material

// type alias
#define obj vec2
#define color vec4

#define MAXSTEP \${stepmax}
#define EPSILON_DE \${epsilon_de}
//------------------------------------------------------------------------------
// primitive shape (distance functions)


//------------------------------------------------------------------------------
// Domain operations

// rotation/translation
vec3 opTx( vec3 p, mat4 m) {
    return (m * vec4(p, 1.0)).xyz;
    //return (inverse(m) * vec4(p, 1.0)).xyz;
}
//------------------------------------------------------------------------------
// Objects definitions (distance functions)

\${obj_sds}

//------------------------------------------------------------------------------
// Distance estimator
float matIdIgnored = -1.0;
obj obj_union(obj o, float d, float matId) {
  //if (matIdIgnored != matId && abs(o.x) > abs(d)) { obj(d, matId);}
  float update = step(abs(d), abs(o.x)) * (step(matId, matIdIgnored) + step(matIdIgnored, matId));
  return mix(o, vec2(d, matId), update);
}

obj de(in vec3 p) {
  obj o = vec2(${glf.SFNAME_FAR}, 0.0);
  \${obj_des}
  return o;
}
''';

const distanceFieldFrag0 = '''
${sdHeaderFrag0}

vec2 packHalf(float v) {
  const vec2 bias = vec2(1.0 / 255.0, 0.0);
  vec2 rg = vec2(v, fract(v * 255.0));
  return rg - (rg.gg * bias);
}

void main(void) {
  float far = ${glf.SFNAME_FAR};
  vec3 ro = ${glf.SFNAME_VIEWPOSITION};

  // Configuration de la camera.
  vec2 q = vTexCoord0.xy;
  vec2 vPos = -1.0 + 2.0 * q;
  //vec3 rd = vPos.x * u * ${glf.SFNAME_PIXELSIZE}.z + vPos.y * v;
  vec3 rd = vec3(vPos.x * far * ${glf.SFNAME_PIXELSIZE}.z, vPos.y * far, 0.0);


  vec3 p = ro + rd;
  obj o = de(p);
  float d = o.x;
  //gl_FragColor.r = abs(p.y);
  //gl_FragColor.r = clamp(o.x, 0.0, 1.0);
  //vec2 d2 = packHalf(d);
  //vec3 n = n_de2d(p);
  //gl_FragColor.r = d2.r;
  //gl_FragColor.g = d2.g;
  gl_FragColor.b = d;
  gl_FragColor.a = 1.0;
}
''';

const rayMarchingFrag0 = '''
${sdHeaderFrag0}

//------------------------------------------------------------------------------
// Shading

\${obj_mats}


color shade(obj o, vec3 p, float t, vec3 rd) {
  \${obj_shs}
  return color(0.0, 0.0, 0.0, 0.0);
}

// front to back
// GL_ONE_MINUS_DST_ALPHA, GL_ONE
color blend2(color front, color back) {
  vec4 c;
  //if (back.a < 0.2) return front;
  //c.rgb = mix(front.rgb, back.rgb, front.a);
  c.rgb = (1.0 - front.a) * back.a * (back.rgb) + front.rgb * front.a;
  c.a = front.a + (1.0 - front.a) * back.a;//(1.0 - src.a) * dst.a;
  //c.a = max(front.a, back.a);
  //c.a = 1.0;
  return c;
}
// try http://en.wikipedia.org/wiki/Alpha_compositing
color blend(color front, color back) {
  vec4 c;
  c.a = front.a + (1.0 - front.a) * back.a;
  c.rgb = ((1.0 - front.a) * back.a * back.rgb + front.rgb * front.a) * (1.0/c.a);
  return c;
}

void main(void) {
  float far = ${glf.SFNAME_FAR};
  float near= ${glf.SFNAME_NEAR};
  vec3 ro= ${glf.SFNAME_VIEWPOSITION};

  // Configuration de la camera.
  vec3 vuv = ${glf.SFNAME_VIEWUP};
  vec3 vpn = normalize(${glf.SFNAME_FOCUSPOSITION} - ro);
  vec3 u = -normalize(cross(vuv,vpn));
  vec3 v = -cross(vpn,u);
  vec3 vcv = (ro+vpn);
  vec2 q = vTexCoord0.xy;
  vec2 vPos = -1.0 + 2.0 * q;
  //vec3 scrCoord=vcv+vPos.x*u*_PixelSize.x+vPos.y*v*_PixelSize.y;
  vec3 scrCoord = vcv+vPos.x*u* ${glf.SFNAME_PIXELSIZE}.z + vPos.y*v;
  vec3 rd=normalize(scrCoord-ro);


  // Raymarching.
  vec2 o = obj(0.0, 0.0);
  float t = near;
  vec3 p;
  vec4 c = vec4(0.0,0.5,0.5,0.0);
  for(int i=0;i< MAXSTEP;i++) {
    p = ro + rd * t;
    o = de(p);
    if (abs(o.x) < EPSILON_DE) {
      matIdIgnored = -1.0;
      //c.rgb = vec3((t - near)/(far - near));  //display distance (z)
      c = blend(c, shade(o, p, t, rd));
      //c.rgb = vec3(0.0,0.0,0.5);
      //c.rgb = vec3(o.y*0.1, 0.0, 0.0); //display matId
      //c.a = 1.0;
      if (c.a >= 0.9) break;
      o.x = 0.0;
      matIdIgnored = o.y;
    }
    t += abs(o.x);
    if (t > far) break;
  }
  //c.a = 1.0;
  //gl_FragColor= vec4((t - near)/(far - near), 0.0, 0.0, 1.0);  //check last distance
  //gl_FragColor= vec4(rd, 1.0); // check ray direction 
  gl_FragColor= c;
}
''';

lightSegment0(l){
  l.add('''
vec3 lightSegment(vec3 p) {
  return -p;
}
  ''');
}

lightSegment_spotAt(Vector3 v) {
  return (l) {
    l.add('''
vec3 lightSegment(vec3 p) {
  return vec3(${v.x}, ${v.y}, ${v.z}) - p;
}
  ''');
  };
}

lightSegment_directional(Vector3 v) {
  return (l) {
    l.add('''
vec3 lightSegment(vec3 p) {
  return vec3(${v.x}, ${v.y}, ${v.z});
}
  ''');
  };
}

lightSegment_spotGrid(size) {
  var invsize = 1.0 / size;
  return (l) {
    l.add('''
vec3 lightSegment(vec3 p) {
  //return (fract(p * $invsize) * $size);
  return mod(p, $size);
}
  ''');
  };
}

/// glsl: float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
softshadow(l) {
  l.add('''
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k ) {
  float res = 1.0;
  float t = mint;
  for( int i=0; i<30; i++ ) {
//    if( t<maxt ) {
//        float h = de( ro + rd*t ).x;
//        res = min( res, k*h/t );
//        t += 0.02;
//    }
    float h = de(ro + rd*t).x;
    res = min( res, k*h/t );
    t += clamp( h, 0.02, 2.0 );
  }
  //return res;
  return clamp(res,0.5,1.0);
}
  ''');
  return l;
}

/// calcul normal from gradient via de(..)
/// glsl: vec3 n_de(vec2 o, vec3 p) {
n_de(l) {
  l.add('''
vec3 n_de(vec2 o, vec3 p) {
  vec3 nor;
  nor.x = de(p+eps.xyy).x - de(p-eps.xyy).x;
  nor.y = de(p+eps.yxy).x - de(p-eps.yxy).x;
  nor.z = de(p+eps.yyx).x - de(p-eps.yyx).x;
  return normalize(nor);
}
''');

//vec3 getNormal(vec2 d, vec3 p) {
//  vec3 n = vec3(
//    d.x-de(p-e.xyy).x,
//    d.x-de(p-e.yxy).x,
//    d.x-de(p-e.yyx).x
//  );
//  return normalize(n);
//}
}

/// glsl: float ao_de(in vec3 p, in vec3 n)
/// alternative at http://www.pouet.net/topic.php?which=7931&page=1
/// sss = 1.0 - ao(p,rd); (rd or lightDir ?)
ao_de(l) {
  l.add('''
float ao_de(in vec3 p, in vec3 n){
  float totao = 0.0;
  float sca = 1.0;
  for (int aoi=0; aoi<5; aoi++ ) {
    float hr = 0.01 + 0.05*float(aoi);
    vec3 aopos =  n * hr + p;
    float dd = de( aopos ).x;
    totao += -(dd-hr)*sca;
    sca *= 0.75;
  }
  return clamp( 1.0 - 4.0*totao, 0.0, 1.0 );
}
  ''');
}

lightSeg_spot(l){
  l.add('''
#DEFINE lightSeg_spot(p, lightPosition) lightPosition - p
  ''');
}

/// glsl: color shade0(color c, vec3 p, vec3 n)
shade0(l) {
  softshadow(l);
  l.add('''
color shade0(color c, vec3 p, vec3 n) {
  vec3 lightDir = normalize(lightSegment(p));
  float ambient = 0.5;
  float lightIntensity = max(0.0, dot(n, lightDir));
//    c.rgb = lightIntensity * c.rgb;
//    c.rgb = (c.rgb + pow(lightIntensity,10.0))*(1.0-length(lightSegment)*.01);
  //float sha = 1.0;
  float sha = softshadow( p+0.01*n, lightDir, 0.0005, 10.0, 32.0 );
  c.rgb = c.rgb * max(ambient, (sha * lightIntensity));
  //c.a = c.a*sha;
  return c;
}
  ''');
}

shade1(l) {
  softshadow(l);
  ao_de(l);
  l.add('''
color shade1(color c, vec3 p, vec3 n, float t, vec3 rd) {
  float ao = ao_de(p, n);

  vec3 lig = normalize( lightSegment(p) );
  float amb = clamp( 0.5+0.5*n.y, 0.0, 1.0 );
  float dif = clamp( dot( n, lig ), 0.0, 1.0 );
  float bac = clamp( dot( n, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-p.y,0.0,1.0);

  float sh = 1.0;
  if( dif>0.02 ) { sh = softshadow( p, lig, 0.02, 10.0, 7.0 ); dif *= sh; }

  vec3 brdf = vec3(0.0);
  brdf += 0.20*amb*vec3(0.10,0.11,0.13)*ao;
  brdf += 0.20*bac*vec3(0.15,0.15,0.15)*ao;
  brdf += 1.20*dif*vec3(1.00,0.90,0.70);

  float pp = clamp(dot(reflect(rd, n), lig), 0.0, 1.0 );
  float spe = sh*pow(pp, 16.0);
  float fre = ao*pow(clamp(1.0+dot(n, rd),0.0,1.0), 2.0 );

  vec3 col = c.rgb;
  col = col*brdf + col * vec3(1.0)*spe + 0.2*fre*(0.5+0.5*col);
  col *= exp( -0.01*t*t );
  c.rgb = col;
  return c;
}
  ''');
}

/// glsl: color shadeOutdoor(color material, vec3 p, vec3 n, vec3 lightSegment)
shadeOutdoor(l) {
  softshadow(l);
  ao_de(l);
  l.add('''
color shadeOutdoor(color c, vec3 p, vec3 n) {
  // lighting terms
  float occ = ao_de(p, n);
  vec3 sunDir = normalize(lightSegment(p));
  float sha = softshadow(p, sunDir, 0.02, 10.0, 7.0);
  float sun = clamp(dot(n, sunDir), 0.0, 1.0);
  float sky = clamp(0.5 + 0.5*n.y, 0.0, 1.0);
  float ind = clamp(dot(n, normalize(sunDir*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0);
  
  // compute lighting
  vec3 lin = sun*vec3(1.64,1.27,0.99)*pow(vec3(sha),vec3(1.0,1.2,1.5));
  lin += sky*vec3(0.16,0.20,0.28)*occ;
  lin += ind*vec3(0.40,0.28,0.20)*occ;
  
  // multiply lighting and materials
  vec3 col = c.rgb * lin;
  
  // apply fog
  //col = doWonderfullFog(col, p);
  
  // gamma correction
  col = pow(col, vec3(1.0/2.2) );
  c.rgb = col;
  return c;
}
  ''');
}

/// glsl: color normalToColor(vec3 n)
normalToColor(l) {
  l.add('''
color normalToColor(vec3 n) {
  return vec4(n.xy* 0.5 + 0.5,  n.z* 0.4 + 0.6, 1.0);
}
  ''');
}

matIdToColor(l) {
  l.add('''
color matIdToColor(float m) {
  return vec4(vec3(0.6) + 0.4*sin( vec3(0.05,0.08,0.10)*(m-1.0) ), 1.0);
}
  ''');
}

/// glsl: color normalToColor(vec3 n)
aoToColor(l) {
  ao_de(l);
  l.add('''
color aoToColor(vec3 p, vec3 n) {
  return vec4(vec3(ao_de(p, n)), 1.0);
}
  ''');
}

class ObjectInfo {
  /// code used to inject uniform declaration into the shader
  String uniforms;
  /// distance estimator fragment to insert into the distance estimator
  /// function as second arg of obj_union to define the distance of the object
  /// it is the place that should call function define in sd
  /// + some op (opScale, opTx) with the right args
  String de;
  String de2;
  /// codes of the signed distance of the object (shape)
  List<String> sds;
  /// shade fragment to insert into the shade
  String sh;
  /// codes of the material of the object
  List<String> mats;
  /// update to run at each frame rendering, eg to update uniforms
  glf.RunOnProgramContext at;
}

makeShader(List<ObjectInfo> os, {String tmpl: rayMarchingFrag0, stepmax:256, epsilon_de: 0.005, lightSegment}) {
  var kv = {
   'stepmax' : stepmax,
   'epsilon_de': epsilon_de,
  };

  var matss = new LinkedHashSet();
  var sh0s = [];
  var shs = [];
  var sdss = new LinkedHashSet();
  var des = [];
  if (lightSegment != null) {
    lightSegment(matss);
  }
  // merge objInfo definitions
  os.forEach((o) {
    if (o.mats != null && o.mats.isNotEmpty) {
      o.mats.forEach((mat){
        if (mat != null) {
          mat(matss);
        }
      });
    }
    var matId = shs.indexOf(o.sh) + 1;
    if (o.sh != null && sh0s.indexOf(o.sh) < 1) {
      matId = sh0s.length + 1;
      var str = '';
      if (matId > 1) {
        str += 'else ';
      }
      str += "if (o.y == " + matId.toString() + ".0) {" + o.sh + "}";
      sh0s.add(o.sh);
      shs.add(str);
    }
    if (o.sds != null && o.sds.isNotEmpty) {
      o.sds.forEach((sd){
        if (sd != null) {
          sd(sdss);
        }
      });
    }
    if (o.de2 != null) {
      des.add(o.de2);
    } else if (o.de != null) {
      des.add("o = obj_union(o, " + o.de +"," + matId.toString() +".0);");
    }
  });
  kv['obj_uniforms'] = os.fold('', (acc, x) => (x.uniforms == null)? acc : (acc + x.uniforms + '\n'));
  kv['obj_sds'] = sdss.fold('', (acc, x) => acc + x + '\n');
  kv['obj_des'] = des.fold('', (acc, x) => acc + x + '\n');
  kv['obj_shs'] = shs.fold('', (acc, x) => acc + x + '\n');
  kv['obj_mats'] = matss.fold('', (acc, x) => acc + x + '\n');
  return interpolate(tmpl, kv);
}

/// out.mats and out.sh are not set
makeExtrudeZinTex(gl, textures, String utex, Vector3 center, double zSize, double unit, List<ObjectInfo> objs, {Vector4 color}){
  unit = unit * 0.5;
  var fbo = new glf.FBO(gl);
  //TODO provide an alternative to type FLOAT (support of OES_texture_float)
  fbo.makeP2(powerOf2:11, type: webgl.FLOAT, hasDepthBuff: false, magFilter: webgl.NEAREST, minFilter: webgl.NEAREST);
  var runner = new RendererR(gl, fboTarget: fbo);
  runner.camera = new glf.CameraInfo()
  ..near = 0.0
  ..far = unit
  ..position.setFrom(center)
  ;
  runner.tmpl = distanceFieldFrag0;
  var nb = 4;
  var w = 1.0; //unit/ (nb * 2.0);
  var h = 0.5; //unit/ (nb * 0.5);
  objs.forEach((obj) => runner.register(obj));
  runner.updateShader();
  runner.run();
  runner.dispose();

  var tex = fbo.texture;
  var texw = fbo.width;
  fbo.dispose(deleteTex : false);

  var n = "n_tex2d(p, ${utex}, vec3(${center.x}, ${center.y}, ${center.z}), $zSize, ${1/unit}, ${unit})";
  var sh = (color == null)
      ? """return normalToColor($n);"""
      : """return shade0(vec4(${color.r}, ${color.g}, ${color.b}, ${color.a}), p, $n);"""
      ;
  return new ObjectInfo()
  ..uniforms='''
  uniform sampler2D ${utex};
  '''
  ..sds = [sd_tex(texw)]
  ..de = "(sd_tex(p, ${utex}, vec3(${center.x}, ${center.y}, ${center.z}), ${zSize}, ${1/unit}, ${unit}))"
  ..at = (ctx) {
    textures.inject(ctx, tex, utex);
  }
  ;
}

class RendererR {
  final gl;
  glf.Filter2DRunner _post2d;
  List<glf.Filter2D>  get filters2d => _post2d.filters;
  glf.CameraInfo camera;
  var tmpl = rayMarchingFrag0;
  var stepmax = 256;
  var epsilon_de = 0.005;
  var debugPrintFragShader = false;
  var lightSegment = lightSegment0;
  final _os = new List<ObjectInfo>();
  var _needShaderUpdate = true;
  var _runningFrag;
  var _makeShader;

  get os => _os;
  get needShaderUpdate => _needShaderUpdate;
  get fragment => _runningFrag;

  var _exts = [];
  RendererR(gl, {glf.FBO fboTarget, makeShader : makeShader}) : this.gl = gl{
    if (fboTarget != null) {
      _post2d = new glf.Filter2DRunner.intoFBO(gl, fboTarget);
    } else {
      var view2d = new glf.ViewportPlan()..fullCanvas(gl.canvas);
      _post2d = new glf.Filter2DRunner(gl, view2d);
    }
    //TODO provide an alternative to type FLOAT (support of OES_texture_float)
    // reserve placeholder for raymarching shader
    _exts.add(gl.getExtension("OES_standard_derivatives"));
    _exts.add(gl.getExtension("OES_texture_float"));
    _makeShader = makeShader;
    _post2d.filters.add(null);
  }

  register(ObjectInfo o) {
    _os.add(o);
    _needShaderUpdate = true;
    print("register : ${o.de}");
  }

  unregister(ObjectInfo o) {
    _os.remove(o);
    _needShaderUpdate = true;
  }

  updateShader() {
    var t0 = window.performance.now();
    String frag = _makeShader(_os, tmpl:tmpl, stepmax: stepmax, epsilon_de:epsilon_de, lightSegment: lightSegment);
    if (debugPrintFragShader) {
      print("_updateShader : compiling ${frag != _runningFrag}");
    }
    if (frag != _runningFrag) {
      _post2d.filters[0] = new glf.Filter2D(gl, frag, (ctx){
        ctx.gl.uniform1f(ctx.getUniformLocation(glf.SFNAME_NEAR), camera.near);
        ctx.gl.uniform1f(ctx.getUniformLocation(glf.SFNAME_FAR), camera.far);
        ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_VIEWPOSITION), camera.position.storage);
        ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_VIEWUP), camera.upDirection.storage);
        ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_FOCUSPOSITION), camera.focusPosition.storage);
        _os.forEach((x){if (x.at != null) { x.at(ctx); }});
      });
      _runningFrag = frag;
//      if (debugPrintFragShader) {
//        var hasher = new MD5()..add(frag.codeUnits);
//        var bytes = hasher.close();
//        var hash = CryptoUtils.bytesToBase64(bytes, urlSafe: true, addLineSeparator: false);
//        print("_updateShader --- \n${frag}\n --- ${hash}");
//      }
    }
    if (debugPrintFragShader) {
      print("_updateShader : end ${window.performance.now() - t0} : ${_post2d.filters[0]}");
    }
    _needShaderUpdate = false;
  }

  run() {
    if (camera == null) throw new Exception("camera undefined");
    if (_runningFrag == null) throw new Exception("no frag defined");
    //if (_needShaderUpdate) updateShader();
    _post2d.run();
  }

  dispose() {
    _post2d.dispose();
    _os.clear();
  }
}
// Some code for GLSL
/*

float sd_torus82( vec3 p, vec2 t ) {
  vec2 q = vec2(length2(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}

float sd_tetrahedron0(vec3 p)
{
  vec3 a1 = vec3(1,0,0);
  vec3 a2 = vec3(-1,-1,0);
  vec3 a3 = vec3(-1,1, 0);
  vec3 a4 = vec3(0,0,1);
  float r = 3.0;
  float d = length(p-a1)-r;
  d = max(length(p-a2)-r,d);
  d = max(length(p-a3)-r,d);
  return max(length(p-a4)-r,d);
}

const float TIER = 1.0/3.0;

float tsphere(vec3 p, vec3 a1, vec3 a2, vec3 a3)
{

  vec3 c = vec3(a1);
  c = c + (a2 - c) * 0.5;
  c = c + (a3 - c) * 0.5;

  //vec3 c = (a1 + a2 + a3) * TIER;
  vec3 n = normalize(cross(a2 - a1, a3 - a1));
  float b = length(a1 - c);
  float r = max(b, 50.0);
  float h = sqrt(r*r - b*b);
  //float h = r ;//approx
  return length(p - (c + n * h))-r;
}
vec2 obj_tetrahedronArc(vec3 p)
{
  vec3 a1 = vec3(2,0,1);
  vec3 a2 = vec3(-1,-1,1);
  vec3 a3 = vec3(-1,1, 1);
  vec3 a4 = vec3(0,0,1.5);
    float r = 3.0;
    float d = 0.0;
  d = max(tsphere(p, a1, a3, a2),d);
    d = max(tsphere(p, a1, a2, a4),d);
    d = max(tsphere(p, a4, a2, a3),d);
    d = max(tsphere(p, a1, a4, a3),d);
  return vec2(d, 1);
}

float thalfspace(vec3 p, vec3 a1, vec3 a2, vec3 a3)
{

  vec3 c = vec3(a1);
  c = c + (a2 - c) * 0.5;
  c = c + (a3 - c) * 0.5;

  //vec3 c = (a1 + a2 + a3) * TIER;
  vec3 n = -normalize(cross(a2 - a1, a3 - a1));
  float b = length(a1 - c);
  return max(0.0, dot(p-a1, n));
}

vec2 obj_tetrahedron(vec3 p)
{
  vec3 a1 = vec3(2,0,1);
  vec3 a2 = vec3(-1,-1,1);
  vec3 a3 = vec3(-1,1, 1);
  vec3 a4 = vec3(0,0,1.5);
    float r = 3.0;
    float d = 0.0;
  d = max(thalfspace(p, a1, a3, a2),d);
    d = max(thalfspace(p, a1, a2, a4),d);
    d = max(thalfspace(p, a4, a2, a3),d);
    d = max(thalfspace(p, a1, a4, a3),d);
  return vec2(d, 1);
}



const float rimStart = 0.5;
const float rimEnd = 1.0;
const float rimMultiplier = 0.1;
vec3  rimColor = vec3(0.0, 0.0, 0.5);

vec3 rimLight(vec3 viewPos, vec3 normal, vec3 position) {
  float normalToCam = 1.0 - dot(normalize(normal), normalize(viewPos.xyz - position.xyz));
  float rim = smoothstep(rimStart, rimEnd, normalToCam) * rimMultiplier;
  return (rimColor * rim);
}

//vec4 shade1(vec2 d, vec3 p)
//{
//  vec4 c = getColor(d, p);
//  vec3 lightSegment = lightPosition - p;
//  vec3 lightDir = normalize(lightSegment);
//  float lightConeAngle = 85.0;
//  //vec3 normal = lightRot * normal;
//  vec3 normal = getNormal(d, p);
//  float lighting = (
//    lambert(normal, lightDir)
//    * influence(-lightDir, lightConeAngle)
//    * attenuation(lightSegment)
//    * softshadow( p+0.01*normal, lightDir, 0.0005, 32.0 )
//  );
//  c.rgb = (
//    skyLight(normal) +
//#ifdef RIMLIGHT
//    rimLight(camPosition, normal, p) +
//#endif
//    clamp(lighting, 0.0, 1.0) * c.rgb
//  );
//  return c;
//}


//uniform sampler2D _DissolveMap0;
//float dissolve(float threshold, vec2 uv, sampler2D dissolveMap) {
//  float v = texture2D(dissolveMap, uv).r;
//  //if (v < threshold) discard;
//  v = step(threshold, v);
//  return v;
//}

//vec4 getColor(vec2 d, vec3 p)
//{
//  vec4 c;
//      // y est utilisé pour gérer les matériaux
//    if (d.y==0.0)
//      c=floor_color(p);
//    else if (d.y == 1.0)
//      c=prim_c(p);
//  else if (d.y == 2.0) {
//    float r = 0.5;//mod(time,1000.0)/1000.0;
//    //vec2 xy = mod(p.xy + vec2(0.5, 0.5),1.0);
//    vec2 xy = vTexCoord0.xy;
//    float a = dissolve(r, xy, _DissolveMap0);
//    //r = ((v - r) < 0.05)? r : 0.0;
//      c = vec4(0.0, 0.8, 0.0, 0.5);
//      //c = c0;
//  }
//  return c;
//}


//// Couleur du sol (damier)
//vec4 floor_color(in vec3 p)
//{
//  float m = floor(p.x) + floor(p.y);
//  m = mod(m, 2.0) ;
//  if ( m == 0.0)
//  {
//    return vec4(0.9,0.0,0.5,1);
//  }
//  else
//  {
//      return vec4(0.2,0.2,0.8,1);
//   }
//}
//
//// Couleur du sol (damier)
//vec4 floor_color0(in vec3 p)
//{
//  if (fract(p.x*0.2)>0.2)
//  {
//    if (fract(p.y*0.2)>0.2)
//      return vec4(0,0.1,0.2,1.0);
//    else
//      return vec4(1,1,1,1.0);
//  }
//  else
//  {
//    if (fract(p.y*.2)>.2)
//      return vec4(1,1,0,1.0);
//    else
//      return vec4(0.3,0,0,1.0);
//   }
//}
//
//// Couleur de la primitive
//vec4 prim_c(in vec3 p)
//{
//  //return vec4(0.9,0.3,0.7,1.0); // aurore
//  //return vec4(1.0,0.9,0.8,1.0); //ryowen
//  return vec4(1.0,0.9,0.8,1.0) + vec4(0.9,0.3,0.7,1.0);
//}
float attenuation(vec3 dir){
  float dist = length(dir);
  float radiance = 1.0/(1.0+pow(dist/10.0, 2.0));
  return clamp(radiance*10.0, 0.0, 1.0);
}

float influence(vec3 normal, float coneAngle){
  float minConeAngle = ((360.0-coneAngle-10.0)/360.0)*PI;
  float maxConeAngle = ((360.0-coneAngle)/360.0)*PI;
  return smoothstep(minConeAngle, maxConeAngle, acos(normal.z));
}

float lambert(vec3 surfaceNormal, vec3 lightDirNormal){
  return max(0.0, dot(surfaceNormal, lightDirNormal));
}

vec3 skyLight(vec3 normal){
  return vec3(smoothstep(0.0, PI, PI-acos(normal.y)))*0.4;
}
float opScale( vec3 p, float s ) {
    return primitive(p/s)*s;
}
*/
