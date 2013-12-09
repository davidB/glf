library glf_rendererr;

import 'package:glf/glf.dart' as glf;
import 'package:vector_math/vector_math.dart';
import 'package:html_toolbox/html_toolbox.dart';

const rayMarchingVert0 = glf.Filter2D.VERT_SRC_2D;

sd_flatFloor(h) {
  return """
float sd_flatFloor(in vec3 p) {
  return p.z+ $h;
}
  """;
}

mat_chessboardXY0(size, Vector4 color0, Vector4 color1) {
  var c = 0.5 / size;
  return '''
color mat_chessboardXY0(in vec3 p){
  //float m = p.x + p.y; // pattern for line
  //float m = fract(p.x) + fract(p.y); // pattern for triangle + m > 1.0
  float m = step(0.5, fract(p.x * $c)) + step(0.5, fract(p.y * $c)) ;
  if ( m == 1.0) {
    return vec4(${color0.r}, ${color0.g}, ${color0.b}, ${color0.a});
  } else {
    return vec4(${color1.r}, ${color1.g}, ${color1.b}, ${color1.a});
  }
}
''';
}
mat_chessboardXY1(ratiox, ratioy, Vector4 color0, Vector4 color1, Vector4 color2, Vector4 color3) {
  return '''
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
''';
}

const sdHeaderFrag0 = '''
// based on
// http://geeks3d.developpez.com/GLSL/raymarching/
// http://9bitscience.blogspot.fr/2013/07/raymarching-distance-fields_14.html
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// https://www.shadertoy.com/view/MsXGWr
precision mediump float;

const float PI = 3.14159265358979323846264;

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

float sd_box( vec3 p, vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float ud_roundBox( vec3 p, vec3 b, float r ) {
  return length(max(abs(p)-b,0.0))-r;
}

float sd_sphere(in vec3 p, float r) {
  return length(p)-r;
}

float sd_torus( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
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
void obj_union(inout obj o, float d, float matId) {
  if (abs(o.x) > abs(d)) {
    o.x = d;
    o.y = matId;
  }
}

obj de(in vec3 p) {
  obj o = vec2(${glf.SFNAME_FAR}, 0.0);
  \${obj_des}
  return o;
}
''';

const distanceFieldFrag0 = '''
${sdHeaderFrag0}

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
  gl_FragColor.r = d;
  gl_FragColor.a = 1.0;
}
''';

const rayMarchingFrag0 = '''
${sdHeaderFrag0}

//------------------------------------------------------------------------------
// Material

\${obj_mats}

//------------------------------------------------------------------------------
// Shading
float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
  float h = 1.0;
    for( int i=0; i<35; i++ )
    {
        h = de(ro + rd*t).x;
        res = min( res, k*h/t );
    t += clamp( h, 0.02, 2.0 );
    }
    return clamp(res,0.5,1.0);
}

const vec3 e=vec3(0.02,0,0);

vec3 getNormal(vec2 d, vec3 p)
{
   vec3 n = vec3(d.x-de(p-e.xyy).x,
                  d.x-de(p-e.yxy).x,
                  d.x-de(p-e.yyx).x);
   return normalize(n);

}

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

\${nearLight}

color shade0(color c, vec3 normal, obj o, vec3 p) {
    
    //spotlight
    vec3 lightPosition = nearLight(p);
    vec3 lightSegment = lightPosition - p;
    vec3 lightDir = normalize(lightSegment);
    float lightIntensity = dot(normal, lightDir);
    c.rgb = lightIntensity * c.rgb;
    c.rgb = (c.rgb + pow(lightIntensity,10.0))*(1.0-length(lightSegment)*.01);

    // directionnal light
    /*
    vec3 lightDir = normalize(vec3(1,1,1));
    float lightIntensity = dot(normal, lightDir);
    c.rgb =lightIntensity*c.rgb;
    */
    //return getReflectance(p) * lightIntensity;
    //float sha = 1.0;
    float sha = softshadow( p+0.01*normal, lightDir, 0.0005, 32.0 );
    c.rgb = c.rgb *sha;
    //c.a = c.a*sha;
    return c;
}

color shadeUniformBasic(vec4 c, obj o, vec3 p) {
  return shade0(c, getNormal(o, p), o, p);
}

color shadeNormal(obj o, vec3 p) {
  vec3 n = getNormal(o, p);
  color c = vec4(n.xy* 0.5 + 0.5,  n.z* 0.4 + 0.6, 1.0);
  return shade0(c, n, o, p);
}

color shade(obj o, vec3 p) {
  \${obj_shs}
  return color(0.0, 0.0, 0.0, 0.0);
}

// front to back
// GL_ONE_MINUS_DST_ALPHA, GL_ONE
color blend(color front, color back) {
  vec4 c;
  //if (back.a < 0.2) return front;
  c.rgb = (1.0 - front.a) * back.a * (back.rgb) + front.rgb * front.a;
  c.a = front.a + (1.0 - front.a) * back.a;//(1.0 - src.a) * dst.a;
  //c.a = max(front.a, back.a);
  //c.a = 1.0;
  return c;
}

void main(void) {
  float far = ${glf.SFNAME_FAR};
  float near= ${glf.SFNAME_NEAR};
  vec3 ro= ${glf.SFNAME_VIEWPOSITION};

  // Configuration de la camera.
  vec3 vuv = ${glf.SFNAME_VIEWUP};
  vec3 vpn = normalize(${glf.SFNAME_FOCUSPOSITION} - ro);
  vec3 u = normalize(cross(vuv,vpn));
  vec3 v = cross(vpn,u);
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
  vec4 c = vec4(0.0,0.5,0.0,0.0);
  for(int i=0;i< MAXSTEP;i++) {
    p = ro + rd * t;
    o = de(p);
    if (o.x < EPSILON_DE && o.x >= 0.0) {
      //c.rgb = vec3((t - near)/(far - near));  //display distance (z)
      c = blend(c, shade(o, p));
      //c.rgb = vec3(0.0,0.0,0.5);
      //c.rgb = vec3(o.y*0.1, 0.0, 0.0); //display matId
      c.a = 1.0;
      if (c.a >= 1.0) break;
      o.x = max(EPSILON_DE, abs(o.x)) * 1.1;
    }
    t += abs(o.x);
    if (t > far) break;
  }
  //gl_FragColor= vec4((t - near)/(far - near), 0.0, 0.0, 1.0);  //check last distance
  //gl_FragColor= vec4(rd, 1.0); // check ray direction 
  gl_FragColor= c;
}
''';

const nearLight0 = '''
vec3 nearLight(vec3 p) {
  return vec3(0.0, 0.0, 0.0);
}
''';

nearLight_SpotAt(Vector3 v) {
  return'''
vec3 nearLight(vec3 p) {
  return vec3(${v.x}, ${v.y}, ${v.z});
}
''';
}

nearLight_SpotGrid(size) {
  var invsize = 1.0 / size;
  return'''
vec3 nearLight(vec3 p) {
  return (floor(p * $invsize) * $size);
}
''';
}

class ObjectInfo {
  /// code used to inject uniform declaration into the shader
  String uniforms;
  /// distance estimator fragment to insert into the distance estimator
  /// function as second arg of obj_union to define the distance of the object
  /// it is the place that should call function define in sd
  /// + some op (opScale, opTx) with the right args
  String de;
  /// code of the signed distance of the object (shape)
  String sd;
  List<String> sds;
  /// shade fragment to insert into the shade
  String sh;
  /// code of the material of the object
  String mat;
  /// update to run at each frame rendering, eg to update uniforms
  glf.RunOnProgramContext at;
}

makeShader(List<ObjectInfo> os, {String tmpl: rayMarchingFrag0, stepmax:256, epsilon_de: 0.005, nearLight : nearLight0}) {
  var kv = {
   'stepmax' : stepmax,
   'epsilon_de': epsilon_de,
   'nearLight' : nearLight
  };

  var mats = [];
  var sh0s = [];
  var shs = [];
  var sds = [];
  var des = [];
  // merge objInfo definitions
  os.forEach((o) {
    if (o.mat != null && mats.indexOf(o.mat) < 0) {
      mats.add(o.mat);
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
    if (o.sd != null && sds.indexOf(o.sd) < 0) {
      sds.add(o.sd);
    }
    if (o.sds != null && o.sds.isNotEmpty) {
      sds.addAll(o.sds);
    }
    if (o.de != null) {
      des.add("obj_union(o, " + o.de +"," + matId.toString() +".0);");
    }
  });
  kv['obj_uniforms'] = os.fold('', (acc, x) => (x.uniforms == null)? acc : (acc + x.uniforms + '\n'));
  kv['obj_sds'] = sds.fold('', (acc, x) => acc + x + '\n');
  kv['obj_des'] = des.fold('', (acc, x) => acc + x + '\n');
  kv['obj_shs'] = shs.fold('', (acc, x) => acc + x + '\n');
  kv['obj_mats'] = mats.fold('', (acc, x) => acc + x + '\n');
  return interpolate(tmpl, kv);
}

class RendererR {
  final gl;
  glf.Filter2DRunner _post2d;
  List<glf.Filter2D>  get filters2d => _post2d.filters;
  glf.CameraInfo camera;
  var nearLight = nearLight0;
  var tmpl = rayMarchingFrag0;
  var stepmax = 256;
  var epsilon_de = 0.005;
  var debugPrintFragShader = false;

  final _os = new List<ObjectInfo>();
  var _needShaderUpdate = true;

  get os => _os;
  get needShaderUpdate => _needShaderUpdate;

  RendererR(gl, {glf.FBO fboTarget}) : this.gl = gl{
    if (fboTarget != null) {
      _post2d = new glf.Filter2DRunner.intoFBO(gl, fboTarget);
    } else {
      var view2d = new glf.ViewportPlan()..fullCanvas(gl.canvas);
      _post2d = new glf.Filter2DRunner(gl, view2d);
    }
    // reserve placeholder for raymarching shader
    _post2d.filters.add(null);
  }

  register(ObjectInfo o) {
    _os.add(o);
    _needShaderUpdate = true;
  }

  unregister(ObjectInfo o) {
    _os.remove(o);
    _needShaderUpdate = true;
  }

  _updateShader() {
    var frag = makeShader(_os, tmpl:tmpl, stepmax: stepmax, epsilon_de:epsilon_de, nearLight: nearLight);
    if (debugPrintFragShader) {
      print("_updateShader");
      print(frag);
    }
    _post2d.filters[0] = new glf.Filter2D(gl, frag, (ctx){
      ctx.gl.uniform1f(ctx.getUniformLocation(glf.SFNAME_NEAR), camera.near);
      ctx.gl.uniform1f(ctx.getUniformLocation(glf.SFNAME_FAR), camera.far);
      ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_VIEWPOSITION), camera.position.storage);
      ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_VIEWUP), camera.upDirection.storage);
      ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_FOCUSPOSITION), camera.focusPosition.storage);
      _os.forEach((x){if (x.at != null) { x.at(ctx); }});
    });
    _needShaderUpdate = false;
  }

  run() {
    if (camera == null) throw new Exception("camera undefined");
    if (_needShaderUpdate) _updateShader();
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

float opScale( vec3 p, float s ) {
    return primitive(p/s)*s;
}
*/
