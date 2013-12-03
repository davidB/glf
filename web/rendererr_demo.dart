//TODO :
// * cleanup code of the demo (remove comment, move Texture name + num as constants, move code of frag/vert into external files)
// * refactor for a better SoC
// * expose some SSAO confugiration
// * expose list of filters2d (include SSAO) to allow enable/disable
// * add comments into the code (why ...)
// * fix bug via dart2js, any image texture are loaded
// * add aother mesh primitives (torus, cone, ...) see nutty primites
import 'dart:html';
import 'dart:async';

import 'package:vector_math/vector_math.dart';
import 'package:asset_pack/asset_pack.dart';
import 'package:glf/glf.dart' as glf;
import 'package:glf/glf_asset_pack.dart';
import 'package:glf/glf_rendererr.dart' as r;
import 'package:dartemis_toolbox/startstopstats.dart';

import 'utils.dart';

const TexNormalsRandomL = "_TexNormalsRandom";
const TexVerticesL = "_TexVertices";
const TexNormalsL = "_TexNormals";

var textures;

main(){
  var gl0 = (querySelector("#canvas0") as CanvasElement).getContext3d(antialias: false, premultipliedAlpha: false, alpha: false, depth: true);
  if (gl0 == null) {
    print("webgl not supported");
    return;
  }
  var gl = gl0;
  //gl = new glf.RenderingContextTracer(gl0); // un-comment this line to print gl's call.
  //gl.printing = false;

  //var gli = js.context.gli;
  //var result = gli.host.inspectContext(gl.canvas, gl);
  //var hostUI = new js.Proxy(gli.host.HostUI, result);
  //result.hostUI = hostUI; // just so we can access it later for debugging
  new Main(gl)
  ..am = initAssetManager(gl)
  ..start()
  ;
  textures = new glf.TextureUnitCache(gl);
}

AssetManager initAssetManager(gl) {
  var tracer = new AssetPackTrace();
  var stream = tracer.asStream().asBroadcastStream();
  new ProgressControler(querySelector("#assetload")).bind(stream);
  new EventsPrintControler().bind(stream);

  var b = new AssetManager(tracer);
  b.loaders['img'] = new ImageLoader();
  b.importers['img'] = new NoopImporter();
  registerGlfWithAssetManager(gl, b);
  return b;
}

class Tick {
  double _t = -1.0;
  double _tr = 0.0;
  double _dt  = 0.0;
  bool _started = false;
  get dt => _dt;
  get time => _t;
  get tr => _tr;

  update(ntr) {
    if (_started) {
      _dt = (ntr - _tr);
      _t = _t + _dt;
    } else {
      _started = true;
    }
    _tr = ntr;
  }

  reset() {
    _started = false;
    _t = 0.0;
    _tr = 0.0;
    _dt  = 0.0;
  }
}

class Main {
  final gl;

  final Tick tick = new Tick();
  AssetManager am;
  var _errorUI = querySelector('#errorTxt') as PreElement;
  var _statsUpdateUI = querySelector('#statsUpdate') as PreElement;
  var _statsLoopUI = querySelector('#statsLoop') as PreElement;

  var _programCtxCache = new glf.ProgramContextCache();
  final onUpdate = new List<Function>();

  /// Aabb of the scene used to adjust some parameter (like near, far shadowMapping)
  /// it is not updated when solid is add (or updated or removed).
  final _sceneAabb = new Aabb3()
  ..min.setValues(-4.0, -4.0, -1.0)
  ..max.setValues(4.0, 4.0, 4.0)
  ;

  Main(this.gl);

  start() {

    //renderer.init();

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

//    renderer.add(new glf.RequestRunOn()
//      ..autoData = (new Map()
//        ..["dt"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('dt'), tick.dt))
//        ..["time"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('time'), tick.time))
//      )
//    );
//    var cameraViewport = new glf.ViewportCamera.defaultSettings(gl.canvas)
//    ..camera.position.setValues(0.0, 0.0, 6.0)
//    ..camera.focusPosition.setValues(0.0, 0.0, 0.0)
////    ..camera.adjustNearFar(_sceneAabb, 0.1, 0.1)
    ;
//    renderer.cameraViewport = cameraViewport;
    var camera = new glf.CameraInfo()
    ..near = 1.0
    ..far = 100.0
    ..position.setValues(0.0, 0.0, 10.0)
    ..upDirection.setValues(0.0, 1.0, 0.0)
    ..focusPosition.setValues(0.0, 0.0, 0.0)
    ;
    var os = [
      floor,
      vdrone,
      cube,
    ];
    var frag = r.makeShader(os);
    var a1 = new Vector3(2.0, 0.0, 1.0);
    var a2 = new Vector3(-1.0,-1.0, 1.0);
    var a3 = new Vector3(-1.0, 1.0, 1.0);
    var a4 = new Vector3(0.0, 0.0, 1.5);

   // print(frag);
    var viewport =  new glf.ViewportPlan.defaultSettings(gl.canvas);
    var runner = new glf.Filter2DRunner(gl, viewport);
    runner.filters.add(new glf.Filter2D(gl, frag, (ctx){
      ctx.gl.uniform1f(ctx.getUniformLocation(glf.SFNAME_NEAR), camera.near);
      ctx.gl.uniform1f(ctx.getUniformLocation(glf.SFNAME_FAR), camera.far);
      ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_VIEWPOSITION), camera.position.storage);
      ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_VIEWUP), camera.upDirection.storage);
      ctx.gl.uniform3fv(ctx.getUniformLocation(glf.SFNAME_FOCUSPOSITION), camera.focusPosition.storage);

      ctx.gl.uniform3fv(ctx.getUniformLocation("a1"), a1.storage);
      ctx.gl.uniform3fv(ctx.getUniformLocation("a2"), a2.storage);
      ctx.gl.uniform3fv(ctx.getUniformLocation("a3"), a3.storage);
      ctx.gl.uniform3fv(ctx.getUniformLocation("a4"), a4.storage);
    }));
//    var ctx = new glf.ProgramContext(gl, r.rayMarchingVert0, );
//    var pr = new glf.ProgramsRunner(gl);
//    var rectangle;
//    pr.register(cameraViewport.makeRequestRunOn());
//    pr.register(new glf.RequestRunOn()
//    ..ctx = ctx
//    ..setup = (gl){
//      rectangle = new glf.FullScreenRectangle();
//      rectangle.init(gl);
//    }
//    ..at = (ctx){
//      rectangle.injectAndDraw(ctx);
//    }
//    );

    am.loadAndRegisterAsset('filter2d_fxaa', 'filter2d', 'packages/glf/shaders/filters_2d/fxaa.frag', null, null).then((_){
      runner.filters.add(am['filter2d_fxaa']);
    });
    update(t){
      statsU.start();
      window.animationFrame.then(update);
      tick.update(t);
      onUpdate.forEach((f) => f(tick));
      // render (run shader's program)
      runner.run();
      statsU.stop();
      statsL.stop();
      statsL.start();
    };
    window.animationFrame.then(update);

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
  }
}

var vdrone = new r.ObjectInfo()
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
;

var floor = new r.ObjectInfo()
..de = "sd_flatFloor(p)"
..sd = r.sd_flatFloor(1.0)
..mat = r.mat_chessboardXY0(1.0, new Vector4(0.9,0.0,0.5,1.0), new Vector4(0.2,0.2,0.8,1.0))
..sh = """return shade0(mat_chessboardXY0(p), getNormal(o, p), o, p);"""
;

var cube = new r.ObjectInfo()
..de = "sd_box(p, vec3(1.0,1.0,1.0))"
..sh = """return shadeNormal(o, p);"""
;