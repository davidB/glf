import 'dart:html';
import 'dart:async';

import 'package:vector_math/vector_math.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:glf/glf.dart' as glf;
import 'package:glf/glf_rendererr.dart' as r;
import 'package:glf/glf_asset_pack.dart';
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
  //_x1 = gl.getExtension("OES_texture_float");
  debugTexR0 = new glf.RendererTexture(gl);
  try {
    new Main(gl)
    ..am = initAssetManager(gl)
    ..start()
    ;
  } catch(err) {
    print(err);
  }
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

    var bctrl = new BrightnessCtrl()
    ..brightness = 0.1
    ..contrast = 0.3
    ;
    var textures = new glf.TextureUnitCache(gl);
    var viewport =  new glf.ViewportPlan.defaultSettings(gl.canvas);
    var runner = new r.RendererR(gl);
    var factory_filter2d = new Factory_Filter2D()
    ..am = am
    ;
    factory_filter2d.init().then((_){
      runner.filters2d.add(factory_filter2d.makeFXAA());
      runner.filters2d.add(factory_filter2d.makeBrightness(bctrl));
    });
    runner.stepmax = 32;
    runner.camera = makeCameraRM();
    runner.lightSegment = r.lightSegment_spotAt(new Vector3(2.0, 1.0, 5.0));
    runner.register(makeFloor());
    runner.register(makeVDrone(new Vector3(1.0, 2.0, 0.0)));
    runner.register(makeCube());
    runner.register(makeWallTexture(gl, textures, 1.0, 1.5, 1.0, 1.0, 3.0));
    runner.updateShader();
//    for(var i = 0; i < 10; i++){
//      runner.register(makeWall(i+1.0, i+2.0, 2.0, 0.5));
//    }

    update(t){
      try {
        statsU.start();
        window.animationFrame.then(update);
        runner.run();
        debugTexR0.run();
        statsU.stop();
        statsL.stop();
        statsL.start();
      } catch(err, exc) {
        print(exc);
      }
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
    if (e.keyCode == KeyCode.D) camera.position.add(camera.viewMatrix.right);
    if (e.keyCode == KeyCode.Q) camera.position.sub(camera.viewMatrix.right);
    if (e.keyCode == KeyCode.R) camera.position.sub(camera.viewMatrix.up);
    if (e.keyCode == KeyCode.F) camera.position.add(camera.viewMatrix.up);
    camera.upDirection.setFrom(camera.viewMatrix.up);

    if (e.keyCode == KeyCode.NUM_ZERO){
      camera.position.setValues(0.0, 0.0, 10.0);
      camera.upDirection.setValues(0.0, 1.0, 0.0);
    }
    camera.updateViewMatrix();
  });
  return camera;
}

defaultShadeMats(l) {
  r.n_de(l);
  r.normalToColor(l);
  r.aoToColor(l);
  r.shade1(l);
  r.shade0(l);
  r.shadeOutdoor(l);
}

defaultShade({String c : "normalToColor(n)", String n : "n_de(o, p)"}) {
  return """
  vec3 n = $n;
  vec3 nf = faceforward(n, rd, n);
  //return shade1($c, p, nf, t, rd);
  return shade0($c, p, nf);
  //return shadeOutdoor($c, p, nf);
  //return aoToColor(p, nf);
  //return normalToColor(n);
  """;
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
  ..sds = [
(l) => l.add("""
float thalfspace(vec3 p, vec3 a1, vec3 a2, vec3 a3){
  vec3 c = vec3(a1);
  c = c + (a2 - c) * 0.5;
  c = c + (a3 - c) * 0.5;
  
  //vec3 c = (a1 + a2 + a3) * TIER;
  vec3 n = -normalize(cross(a2 - a1, a3 - a1));
  float b = length(a1 - c);
  return max(0.0, dot(p-a1, n));
}
"""),
(l) => l.add("""  
float sd_tetrahedron(vec3 p, vec3 a1, vec3 a2, vec3 a3, vec3 a4){
  float d = 0.0;
  d = max(thalfspace(p, a1, a3, a2),d);
  d = max(thalfspace(p, a1, a2, a4),d);
  d = max(thalfspace(p, a4, a2, a3),d);
  d = max(thalfspace(p, a1, a4, a3),d);
  return d;
}
""")
]
  ..mats = [defaultShadeMats]
  ..sh = defaultShade(c : "vec4(0.5, 0.0, 0.0, 1.0)")
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
  ..sds = [r.sd_flatFloor(1.0)]
  ..mats = [r.mat_chessboardXY0(1.0, new Vector4(0.9,0.0,0.5,1.0), new Vector4(0.2,0.2,0.8,1.0)), defaultShadeMats]
  ..sh = defaultShade(c : "mat_chessboardXY0(p)")
  ;
}

makeCube(){
  return new r.ObjectInfo()
  ..sds = [r.sd_box]
  ..de = "sd_box(p, vec3(1.0,1.0,1.0))"
  ..mats = [defaultShadeMats]
  ..sh = defaultShade()
  ;
}

makeWall(x, y, w, h, [z = 2.0]){
  return new r.ObjectInfo()
  ..sds = [r.sd_box]
  ..de = "sd_box(p - vec3($x, $y, 0.0), vec3($w,$h,$z))"
  ..mats = [defaultShadeMats]
  ..sh = defaultShade(c : "vec4(0.1,1.0,0.1,1.0)")
  ;
}

makeWallTexture(gl, textures, z, zSize, offx, offy, unit){
  unit = 20.0;
  var nb = 4;
  var w = 1.0; //unit/ (nb * 2.0);
  var h = 0.5; //unit/ (nb * 0.5);
  var objs = [];
  for(var i = 0; i < nb; i++){
    var p = 0 + i * ((i % 2) - 0.5) * 2.0;
    objs.add(makeWall(p + 3, p + 1, w, h, z));
  }
//  var tex = fbo.texture;
//  debugTexR0.tex = tex;
  var utex = "wallTex";
  var center = new Vector3(offx, offy, z);
  return r.makeExtrudeZinTex(gl, textures, utex, center, zSize, unit, objs)
  ..mats = [r.n_tex2d, defaultShadeMats]
  //..sh = defaultShade(n : "n_tex2d(p, ${utex}, vec3(${center.x}, ${center.y}, ${center.z}), $zSize, ${1/unit}, ${unit})")
  ..sh = defaultShade(c : "vec4(0.1,1.0,0.1,0.7)")
  ;
}