import 'dart:html';
import 'dart:async';
import 'dart:web_gl' as webgl;

import 'package:vector_math/vector_math.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:glf/glf.dart' as glf;
import 'package:glf/glf_rendererr.dart' as r;
import 'package:dartemis_toolbox/startstopstats.dart';

import 'utils.dart';

var _x1;
var debugTexR0;
main(){
  var gl0 = (querySelector("#canvas0") as CanvasElement).getContext3d(antialias: false, premultipliedAlpha: false, alpha: false, depth: true);
  if (gl0 == null) {
    print("webgl not supported");
    return;
  }
  var gl = gl0;
  //_x0 = gl.getExtension("OES_standard_derivatives");
  _x1 = gl.getExtension("OES_texture_float");
  debugTexR0 = new glf.RendererTexture(gl);
  new Main(gl)
  ..am = initAssetManager(gl)
  ..start()
  ;
}

class Main {
  final gl;
  AssetManager am;

  var _errorUI = querySelector('#errorTxt') as PreElement;
  var _statsUpdateUI = querySelector('#statsUpdate') as PreElement;
  var _statsLoopUI = querySelector('#statsLoop') as PreElement;

  Main(this.gl);

  start() {
    var statsU = new StartStopStats()
      ..displayFct = (stats, now) {
        if (now - stats.displayLast > 1000) {
          stats.displayLast = now;
          var msg = "avg : ${stats.avg}\nmax : ${stats.max}\nmin : ${stats.min}\nfps : ${1000/stats.avg}\n";
          _statsUpdateUI.text = msg;
          if (now - stats.resetLast > 3000) stats.reset();
        }
      }
    ;
    var statsL = new StartStopStats()
      ..displayFct = (stats, now) {
        if (now - stats.displayLast > 1000) {
          stats.displayLast = now;
          var msg = "avg : ${stats.avg}\nmax : ${stats.max}\nmin : ${stats.min}\nfps : ${1000/stats.avg}\n";
          _statsLoopUI.text = msg;
          if (now - stats.resetLast > 3000) stats.reset();
        }
      }
    ;

    var textures = new glf.TextureUnitCache(gl);
    var viewport =  new glf.ViewportPlan.defaultSettings(gl.canvas);
    var runner = new r.RendererR(gl);
    am.loadAndRegisterAsset('filter2d_fxaa', 'filter2d', 'packages/glf/shaders/filters_2d/fxaa.frag', null, null).then((_){
      runner.filters2d.add(am['filter2d_fxaa']);
    });
    runner.camera = makeCameraRM();
    runner.nearLight = r.nearLight_SpotAt(new Vector3(2.0, 1.0, 5.0));
    runner.register(makeFloor());
    runner.register(makeVDrone(new Vector3(1.0, 2.0, 0.0)));
    runner.register(makeCube());
    runner.register(makeWallTexture(gl, textures, 1.0, 1.5, 1.0, 1.0, 3.0));
//    for(var i = 0; i < 10; i++){
//      runner.register(makeWall(i+1.0, i+2.0, 2.0, 0.5));
//    }

    update(t){
      statsU.start();
      window.animationFrame.then(update);
      runner.run();
      debugTexR0.run();
      statsU.stop();
      statsL.stop();
      statsL.start();
    };
    window.animationFrame.then(update);
    document.onKeyDown.listen((e){
      if (e.keyCode == KeyCode.N) window.animationFrame.then(update);
    });
  }
}

makeCameraRM(){
  var camera = new glf.CameraInfo()
  ..near = 0.0
  ..far = 100.0
  ..position.setValues(0.0, 0.0, 10.0)
  ..upDirection.setValues(0.0, 1.0, 0.0)
  ..focusPosition.setValues(0.0, 0.0, 0.0)
  ;
  document.onKeyDown.listen((e){
    if (e.keyCode == KeyCode.Z) camera.position.sub(camera.viewMatrix.forward);
    if (e.keyCode == KeyCode.S) camera.position.add(camera.viewMatrix.forward);
    if (e.keyCode == KeyCode.D) camera.position.sub(camera.viewMatrix.right);
    if (e.keyCode == KeyCode.Q) camera.position.add(camera.viewMatrix.right);
    if (e.keyCode == KeyCode.R) camera.position.sub(camera.viewMatrix.up);
    if (e.keyCode == KeyCode.F) camera.position.add(camera.viewMatrix.up);
    if (e.keyCode == KeyCode.NUM_ZERO) camera.position.setValues(0.0, 0.0, 10.0);
    //camera.updateViewMatrix();
  });
  return camera;
}

makeVDrone(Vector3 t){
  var a1 = new Vector3(2.0, 0.0, 1.0).add(t);
  var a2 = new Vector3(-1.0,-1.0, 1.0).add(t);
  var a3 = new Vector3(-1.0, 1.0, 1.0).add(t);
  var a4 = new Vector3(0.0, 0.0, 1.5).add(t);
  return new r.ObjectInfo()
  ..uniforms = """
  uniform vec3 a1, a2, a3, a4;
  """
  ..de = "sd_tetrahedron(p, a1, a2, a3, a4)"
  ..sd = """
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
  
  float sd_tetrahedron(vec3 p, vec3 a1, vec3 a2, vec3 a3, vec3 a4){
  float d = 0.0;
  d = max(thalfspace(p, a1, a3, a2),d);
  d = max(thalfspace(p, a1, a2, a4),d);
  d = max(thalfspace(p, a4, a2, a3),d);
  d = max(thalfspace(p, a1, a4, a3),d);
  return d;
  }
  """
  ..sh = """return shadeUniformBasic(vec4(0.5, 0.0, 0.0, 1.0), o, p);"""
  ..at = (ctx){
    ctx.gl.uniform3fv(ctx.getUniformLocation("a1"), a1.storage);
    ctx.gl.uniform3fv(ctx.getUniformLocation("a2"), a2.storage);
    ctx.gl.uniform3fv(ctx.getUniformLocation("a3"), a3.storage);
    ctx.gl.uniform3fv(ctx.getUniformLocation("a4"), a4.storage);
  }
  ;
}

makeFloor(){
  return new r.ObjectInfo()
  ..de = "sd_flatFloor(p)"
  ..sd = r.sd_flatFloor(1.0)
  ..mat = r.mat_chessboardXY0(1.0, new Vector4(0.9,0.0,0.5,1.0), new Vector4(0.2,0.2,0.8,1.0))
  ..sh = """return shade0(mat_chessboardXY0(p), getNormal(o, p), o, p);"""
  ;
}

makeCube(){
  return new r.ObjectInfo()
  ..de = "sd_box(p, vec3(1.0,1.0,1.0))"
  ..sh = """return shadeNormal(o, p);"""
  ;
}

makeWall(x, y, w, h, [z = 2.0]){
  return new r.ObjectInfo()
  ..de = "sd_box(p - vec3($x, $y, 0.0), vec3($w,$h,$z))"
  ..sh = """return shadeUniformBasic(vec4(1.0,1.0,1.0,1.0), o, p);"""
  ;
}

makeWallTexture(gl, textures, z, zSize, offx, offy, unit){
  offx = 5.0;
  offy = 0.0;
  unit = 20.0;
  var fbo;
  fbo = new glf.FBO(gl);
  fbo.makeP2(powerOf2:11, hasDepthBuff: false, magFilter: webgl.NEAREST, minFilter: webgl.NEAREST); // 2048 * 2048
  var runner = new r.RendererR(gl, fboTarget: fbo);
  runner.camera = new glf.CameraInfo()
  ..near = 0.0
  ..far = unit * 0.5// the half of the width and height
  ..position.setValues(offx, offy, z)
  ;
  runner.tmpl = r.distanceFieldFrag0;
  var nb = 4;
  var w = 1.0; //unit/ (nb * 2.0);
  var h = 0.5; //unit/ (nb * 0.5);
  for(var i = 0; i < nb; i++){
    var p = 0 + i * ((i % 2) - 0.5) * 2.0;
    runner.register(makeWall(p + 3, p + 1, w, h, z));
  }
  runner.run();
  runner.dispose();
  var tex = fbo.texture;
  debugTexR0.tex = tex;

  return new r.ObjectInfo()
    ..uniforms='''
    uniform sampler2D wallTex;
    '''
    ..sd = '''
    float sd_tex(vec3 p, sampler2D tex, float dz, float halfz, float offx, float offy, float iu, float u) {
      vec2 st = (vec2((p.x + offy), (p.y + offy)) * iu) * 0.5 + 0.5;
      vec4 data = texture2D(tex, st);
      float d = data.r;
      float z = max(0.0, abs(p.z - dz) - halfz);
      return sqrt(d * d + z * z);
    }
    '''
    ..de = "sd_tex(p, wallTex, $z, ${zSize * 0.5}, $offx, $offy, ${1/unit}, ${unit})"
    ..sh = """return shadeUniformBasic(vec4(1.0,1.0,1.0,1.0), o, p);"""
    //..sh = """return vec4(1.0,0.0,0.0,1.0);"""
    ..at = (ctx) {
      //glf.injectTexture(ctx, tex, 1, 'wallTex');
      textures.inject(ctx, tex, 'wallTex');
    }
  ;
}