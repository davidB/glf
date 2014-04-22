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
import 'dart:math' as math;
import 'dart:web_gl' as WebGL;
import 'dart:typed_data';
import 'package:js/js.dart' as js;

import 'package:vector_math/vector_math.dart';

import 'package:asset_pack/asset_pack.dart';
import 'package:glf/glf.dart' as glf;
import 'package:glf/glf_renderera.dart';
import 'package:glf/glf_asset_pack.dart';

import 'utils.dart';

const TexNormalsRandomL = "_TexNormalsRandom";
const TexVerticesL = "_TexVertices";
const TexNormalsL = "_TexNormals";

var textures;
var debugTexR0;

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
  var am = initAssetManager(gl);
  debugTexR0 = new glf.RendererTexture(gl);
  textures = new glf.TextureUnitCache(gl);
  new Main(new RendererA(gl), am).start();
}

var mdt = new glf.MeshDefTools();

class Main {

  final RendererA renderer;
  final AssetManager am;
  final Factory_Filter2D factory_filter2d;

  final Tick tick = new Tick();

  var _vertexUI; // = querySelector('#vertex') as TextAreaElement;
  var _fragmentUI; //= querySelector('#fragment') as TextAreaElement;
  var _selectShaderUI = querySelector('#selectShader') as SelectElement;
  var _selectMeshUI = querySelector('#selectMesh') as SelectElement;
  var _subdivisionMeshUI = querySelector('#subdivisionMesh') as InputElement;
  var _loadShaderUI = querySelector('#loadShader') as ButtonElement;
  var _applyShaderUI = querySelector('#applyShader') as ButtonElement;
  var _errorUI = querySelector('#errorTxt') as PreElement;
  var _showWireframeUI = querySelector('#showWireframe') as CheckboxInputElement;
  var _showNormalsUI = querySelector('#showNormals') as CheckboxInputElement;
  var _statsUpdateUI = querySelector('#statsUpdate') as PreElement;
  var _statsLoopUI = querySelector('#statsLoop') as PreElement;
  var plane = new Plane();
  var obj3d = new Obj3D();
  var _programCtxCache = new glf.ProgramContextCache();
  final onUpdate = new List<Function>();

  /// Aabb of the scene used to adjust some parameter (like near, far shadowMapping)
  /// it is not updated when solid is add (or updated or removed).
  final _sceneAabb = new Aabb3()
  ..min.setValues(-4.0, -4.0, -1.0)
  ..max.setValues(4.0, 4.0, 4.0)
  ;

  Main(renderer0, am0) :
    renderer = renderer0,
    am = am0,
    factory_filter2d = new Factory_Filter2D()..am = am0
  ;

  start() {

    renderer.init();

    var statsU = new StartStopWatch()
      ..displayFct = (stats, now) {
        if (now - stats.displayLast > 1000) {
          stats.displayLast = now;
          var msg = "avg : ${stats.avg}\nmax : ${stats.max}\nmin : ${stats.min}\nfps : ${1000/stats.avg}\n";
          _statsUpdateUI.text = msg;
          if (now - stats.resetLast > 3000) stats.reset();
        }
      }
    ;
    var statsL = new StartStopWatch()
      ..displayFct = (stats, now) {
        if (now - stats.displayLast > 1000) {
          stats.displayLast = now;
          var msg = "avg : ${stats.avg}\nmax : ${stats.max}\nmin : ${stats.min}\nfps : ${1000/stats.avg}\n";
          _statsLoopUI.text = msg;
          if (now - stats.resetLast > 3000) stats.reset();
        }
      }
    ;

    renderer.add(new glf.RequestRunOn()
      ..autoData = (new Map()
        ..["dt"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('dt'), tick.dt))
        ..["time"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('time'), tick.time))
      )
    );
    var cameraViewport = new glf.ViewportCamera.defaultSettings(renderer.gl.canvas)
    ..camera.position.setValues(0.0, 0.0, 6.0)
    ..camera.focusPosition.setValues(0.0, 0.0, 0.0)
    ..camera.adjustNearFar(_sceneAabb, 0.1, 0.1)
    ;
    renderer.cameraViewport = cameraViewport;

    _loadAssets().then((x){
      renderer.filters2d.add(factory_filter2d.makeIdentity());
      //renderer.filters2d.add(factory_filter2d.makeBrightness(new BrightnessCtrl()));
      //renderer.filters2d.add(factory_filter2d.makeConvolution3(Factory_Filter2D.c3_boxBlur));
      //renderer.filters2d.add(factory_filter2d.makeXWaves(() => tick.time / 1000.0));
      renderer.filters2d.add(factory_filter2d.makeFXAA());
      _initRendererPre();
    });

    update(t){
      statsU.start();
      window.animationFrame.then(update);
      tick.update(t);
      // rule to modify one vertice of the mesh
      //md.vertices[0] = 4.0 * (t % 3000)/3000 - 2.0;

      onUpdate.forEach((f) => f(tick));
      // render (run shader's program)
      renderer.run();
      debugTexR0.run();
      statsU.stop();
      statsL.stop();
      statsL.start();
    };
    window.animationFrame.then(update);

    initEditors();
    bindUI();
    _selectShaderUI.selectedIndex = 0;
    loadShaderCode(_selectShaderUI.value).then((_){
      apply();
    });
    //_loadShaderUI.click();
    //_applyShaderUI.click();
  }


  initEditors() {
    _vertexUI = ((js.context as dynamic).CodeMirror.fromTextArea(querySelector("#vertex"), js.map({"mode" : "glsl", "lineNumbers" : true})).doc);
    _fragmentUI = ((js.context as dynamic).CodeMirror.fromTextArea(querySelector("#fragment"), js.map({"mode" : "glsl", "lineNumbers" : true})).doc);
  }

  bindUI() {
    _loadShaderUI.onClick.listen((_) => loadShaderCode(_selectShaderUI.value));
    _applyShaderUI.onClick.listen((_) => apply());
  }

  loadShaderCode(String baseUri){
    var vsUri = Uri.parse("${baseUri}.vert");
    var fsUri = Uri.parse("${baseUri}.frag");
    return Future.wait([
      HttpRequest.request(vsUri.toString(), method: 'GET'),
      HttpRequest.request(fsUri.toString(), method: 'GET')
    ])
    .then((l) {
      _vertexUI.setValue(l[0].responseText);
      _fragmentUI.setValue(l[1].responseText);
    });
  }

  makeShaderProgram(gl) => _programCtxCache.find(gl, _vertexUI.getValue(), _fragmentUI.getValue());

  makeMeshDef(){
    var sub = int.parse(_subdivisionMeshUI.value);
    var md = null;
    switch(_selectMeshUI.value) {
      case 'none' :
        md = null; //new glf.MeshDef();
        break;
      case 'box24' :
        md = mdt.makeBox24Vertices(dx: 2.0, dy: 1.0, dz: 0.5, ty: 1.0);
        break;
      case 'box24-t' :
        md = mdt.makeBox24Vertices(dx: 2.0, dy: 1.0, dz: 0.5, tx: 2.0, ty: 1.0, tz: 0.5);
        break;
      case 'cube8' :
        md = mdt.makeBox8Vertices(dx: 0.5, dy: 0.5, dz: 0.5);
        break;
      case 'sphereL':
        md = mdt.makeSphere(subdivisionsAxis : sub, subdivisionsHeight : sub);
        break;
      default:
        md = mdt.makeBox24Vertices(dx: 0.5, dy: 0.5, dz: 0.5);
    }
    if (_showWireframeUI.checked) {
      md.lines = mdt.extractWireframe(md.triangles);
      md.triangles = null;
    }
    return md;
  }

  apply() {
    try {
      _errorUI.text = '';
      var ctx = makeShaderProgram(renderer.gl);
      plane.applyMaterial(renderer, ctx);
      obj3d.apply(renderer, ctx, onUpdate, makeMeshDef(), _showNormalsUI.checked);
    }catch (e, stackTrace) {
      _errorUI.text = e.toString();
      print(e);
      print(stackTrace);
    }
  }

  Future<AssetManager> _loadAssets() {
    return Future.wait([
      factory_filter2d.init(),
      am.loadAndRegisterAsset('shader_depth_light', 'shaderProgram', 'packages/glf/shaders/depth_light{.vert,.frag}', null, null),
      am.loadAndRegisterAsset('shader_deferred_normals', 'shaderProgram', 'packages/glf/shaders/deferred{.vert,_normals.frag}', null, null),
      am.loadAndRegisterAsset('shader_deferred_vertices', 'shaderProgram', 'packages/glf/shaders/deferred{.vert,_vertices.frag}', null, null),
      am.loadAndRegisterAsset('filter2d_blend_ssao', 'filter2d', 'packages/glf/shaders/filters_2d/blend_ssao.frag', null, null),
      am.loadAndRegisterAsset('texNormalsRandom', 'tex2d', 'normalmap.png', null, null)
    ]).then((l) => am);
  }
  _initRendererPre() {
    _initRendererPreLight();
    _initRendererPreDeferred();
  }
  _initRendererPreLight() {
    var light = new glf.ViewportCamera()
      ..viewWidth = 256
      ..viewHeight = 256
      ..camera.fovRadians = degrees2radians * 55.0
      ..camera.aspectRatio = 1.0
      ..camera.position.setValues(2.0, 2.0, 4.0)
      ..camera.focusPosition.setValues(0.0, 0.0, 0.0)
      ..camera.adjustNearFar(_sceneAabb, 0.1, 0.1);
      ;
    var lightFbo = new glf.FBO(renderer.gl)..make(width : light.viewWidth, height : light.viewHeight);
    var lightCtx = am['shader_depth_light'];
    var lightR = light.makeRequestRunOn()
      ..ctx = lightCtx
      ..setup = light.setup
      ..before =(ctx) {
        ctx.gl.bindFramebuffer(WebGL.FRAMEBUFFER, lightFbo.buffer);
        ctx.gl.viewport(light.x, light.y, light.viewWidth, light.viewHeight);
        ctx.gl.clearColor(1.0, 1.0, 1.0, 1.0);
        ctx.gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
        light.injectUniforms(ctx);
      }
    ;

    var r = new glf.RequestRunOn()
      ..autoData = (new Map()
        ..["sLightDepth"] = ((ctx) => textures.inject(ctx, lightFbo.texture, "sLightDepth"))
        ..["lightFar"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightFar'), light.camera.far))
        ..["lightNear"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightNear'), light.camera.near))
        ..["lightConeAngle"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightConeAngle'), light.camera.fovRadians * radians2degrees))
        ..["lightProj"] = ((ctx) => glf.injectMatrix4(ctx, light.camera.projectionMatrix, "lightProj"))
        ..["lightView"] = ((ctx) => glf.injectMatrix4(ctx, light.camera.viewMatrix, "lightView"))
        ..["lightRot"] = ((ctx) => glf.injectMatrix3(ctx, light.camera.rotMatrix, "lightRot"))
        ..["lightProjView"] = ((ctx) => glf.injectMatrix4(ctx, light.camera.projectionViewMatrix, "lightProjView"))
        //..["lightVertex"] = ((ctx) => ctx.gl.uniform1fv(ctx.getUniformLocation('lightVertex'), light.camera.position.storage))
      )
      ;
    renderer.add(r);
    renderer.addPrepare(r);
    renderer.addPrepare(lightR);
    debugTexR0.tex = lightFbo.texture;
  }

  _initRendererPreDeferred() {
    var fboN = _initRendererPreDeferred0(renderer.cameraViewport, am['shader_deferred_normals'], TexNormalsL);
    var fboV = _initRendererPreDeferred0(renderer.cameraViewport, am['shader_deferred_vertices'], TexVerticesL);
    //renderer.debugView = fboN.texture;
    //_initSSAO(fboN.texture, fboV.texture, am['texNormalsRandom']);
  }

  _initRendererPreDeferred0(vp, ctx, texName) {
    var fbo = new glf.FBO(renderer.gl)..make(width : vp.viewWidth, height : vp.viewHeight, type: WebGL.FLOAT);
    var pre = new glf.RequestRunOn()
      ..ctx = ctx
      ..before =(ctx) {
        var gl = ctx.gl;
        gl.bindFramebuffer(WebGL.FRAMEBUFFER, fbo.buffer);
        gl.viewport(vp.x, vp.y, vp.viewWidth, vp.viewHeight);
        gl.clearColor(1.0, 1.0, 1.0, 1.0);
        gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
        vp.injectUniforms(ctx);
      }
    ;

    var r = new glf.RequestRunOn()
      ..autoData = (new Map()
        ..[texName] = ((ctx) => textures.inject(ctx, fbo.texture, texName))
      )
      ;
    renderer.add(r);
    renderer.addPrepare(r);
    renderer.addPrepare(pre);
    return fbo;
  }

  _initSSAO(WebGL.Texture texNormals, WebGL.Texture texVertices, WebGL.Texture texNormalsRandom) {
    var ssao = new glf.Filter2D.copy(am['filter2d_blend_ssao'])
    ..cfg = (ctx) {
      ctx.gl.uniform2f(ctx.getUniformLocation('_Attenuation'), 1.0, 5.0); // (0,0) -> (2, 10) def (1.0, 5.0)
      ctx.gl.uniform1f(ctx.getUniformLocation('_SamplingRadius'), 15.0); // 0 -> 40
      ctx.gl.uniform1f(ctx.getUniformLocation('_OccluderBias'), 0.05); // 0.0 -> 0.2, def 0.05
      textures.inject(ctx, texNormals, TexNormalsL);
      textures.inject(ctx, texVertices, TexVerticesL);
      textures.inject(ctx, texNormalsRandom, TexNormalsRandomL);
    };
    renderer.filters2d.insert(0, ssao);
  }
}

class Obj3D {
  var cameraReqN;
  var upd0;
  var geometry = new Geometry();
  var material;

  apply(renderer, ctx, onUpdate, glf.MeshDef md, showNormals) {
    _remove(renderer, onUpdate);
    if (md != null) {
      _add(renderer, ctx, onUpdate, md, showNormals);
    }
  }

  _remove(renderer, onUpdate) {
    renderer.removeSolid(geometry);
    if (cameraReqN != null) {
      renderer.remove(cameraReqN);
      cameraReqN = null;
    }
    if (upd0 != null) {
      onUpdate.remove(upd0);
      upd0 = null;
    }
  }

  _add(renderer, ctx, onUpdate, md, showNormals) {

    geometry.meshDef = md;

    // keep ref to RequestRunOn to be able to register/unregister (show/hide)
    var tex = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/dirt.jpg"));
    var texNormal = glf.createTexture(ctx.gl, new Uint8List.fromList([0, 0, 120]), Uri.parse("_images/shaders_offest_normalmap.jpg"));
    var texDissolve0 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/burnMap.png"));
    var texDissolve1 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/growMap.png"));
    var texDissolve2 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/linear.png"));
    var texMatCap0 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/matcap/matcap0.png"));
    var texMatCap1 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/matcap/matcap1.png"));
    var texMatCap2 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/matcap/matcap2.jpg"));

    var material = new Material()
      ..ctx = ctx
      ..cfg = (ctx) {
        // material (fake variation)
        ctx.gl.uniform4f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.5, 0.5, 0.5, 1.0);
        textures.inject(ctx, tex, '_Tex0');
        textures.inject(ctx, texNormal, '_NormalMap0');
        textures.inject(ctx, texDissolve0, '_DissolveMap0');
        textures.inject(ctx, texDissolve1, '_DissolveMap1');
        textures.inject(ctx, texDissolve2, '_DissolveMap2');
        textures.inject(ctx, texMatCap0, '_MatCap0');
        textures.inject(ctx, texMatCap1, '_MatCap1');
        textures.inject(ctx, texMatCap2, '_MatCap2');
      }
    ;
    renderer.addSolid(geometry, material);

//    cameraRunner.register(cameraReq);

//    lightReq = new glf.RequestRunOn()
//      ..ctx = renderer.lightCtx
//      ..at = geometry.injectAndDraw
//    ;
//    renderer.lightRunner.register(lightReq);

    upd0 = (tick){
      geometry.transforms.setIdentity();
      geometry.transforms.rotateY((tick.time % 5000.0) / 5000.0 * 2 * math.PI);
      glf.makeNormalMatrix(geometry.transforms, geometry.normalMatrix);
    };
    onUpdate.add(upd0);

    if (showNormals) {
      var mdNormal = mdt.extractNormals(geometry.meshDef);
      var meshNormal = new glf.Mesh()..setData(ctx.gl, mdNormal);
      var programCtxN = glf.loadProgramContext(ctx.gl, Uri.parse("packages/glf/shaders/default.vert"), Uri.parse("packages/glf/shaders/default.frag"));

      programCtxN.then((ctxN) {
        cameraReqN = new glf.RequestRunOn()
          ..ctx = ctxN
          ..at = (ctx) {
            ctx.gl.uniform4f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.8, 0.8, 0.8, 1.0);
            glf.makeNormalMatrix(geometry.transforms, geometry.normalMatrix);
            glf.injectMatrix4(ctx, geometry.transforms, glf.SFNAME_MODELMATRIX);
            glf.injectMatrix3(ctx, geometry.normalMatrix, glf.SFNAME_NORMALMATRIX);
            textures.inject(ctx, tex, '_Tex0');
            textures.inject(ctx, texNormal, '_NormalMap0');
            // vertices of the mesh can be modified in update loop, so update the data to GPU
            //mesh2.vertices.setData(ctx.gl, md2.vertices);
            meshNormal.inject(ctx);
            meshNormal.draw(ctx);
          }
        ;
        renderer.add(cameraReqN);
      });
    }

  }
}

class Plane {
  var geometry = new Geometry();

  applyMaterial(renderer, ctx) {
    renderer.removeSolid(geometry);
    _add(renderer, ctx);
  }


  _add(renderer, ctx) {
    geometry.meshDef = mdt.makePlane(dx: 3.0, dy: 3.0);
    glf.makeNormalMatrix(geometry.transforms, geometry.normalMatrix);
    // keep ref to RequestRunOn to be able to register/unregister (show/hide)
    var tex = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/dirt.jpg"));
    var texNormal = glf.createTexture(ctx.gl, new Uint8List.fromList([0, 0, 120]), Uri.parse("_images/shaders_offest_normalmap.jpg"));
    var texDissolve0 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/burnMap.png"));
    var texDissolve1 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/growMap.png"));
    var texDissolve2 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/linear.png"));
    var texMatCap0 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/matcap/matcap0.png"));
    var texMatCap1 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/matcap/matcap1.png"));
    var texMatCap2 = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/matcap/matcap2.jpg"));

    var material = new Material()
    ..ctx = ctx
    ..cfg = (ctx) {
      // material (fake variation)
      ctx.gl.uniform4f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.0, 0.5, 0.5, 1.0);
      textures.inject(ctx, tex, '_Tex0');
      textures.inject(ctx, texNormal, '_NormalMap0');
      textures.inject(ctx, texDissolve0, '_DissolveMap0');
      textures.inject(ctx, texDissolve1, '_DissolveMap1');
      textures.inject(ctx, texDissolve2, '_DissolveMap2');
      textures.inject(ctx, texMatCap0, '_MatCap0');
      textures.inject(ctx, texMatCap1, '_MatCap1');
      textures.inject(ctx, texMatCap2, '_MatCap2');
    }
    ;
    renderer.addSolid(geometry, material);
  }

}

// in milliseconds ( like window.performance.now() )
class StartStopWatch {
  Function displayFct;
  double displayLast = 0.0;
  double resetLast = 0.0;
  double min;
  double max;
  double total;
  int count;
  double _pstart;

  final _perf = window.performance;

  get avg => (count == 0) ? 0.0 : total/count;

  StartStopWatch() {
    reset();
    start();
  }

  start() {
    _pstart = _perf.now();
  }

  stop() {
    var now = _perf.now();
    store(now - _pstart);
    if (displayFct != null) {
      displayFct(this, now);
    }
  }

  store(double t) {
    if (min > t) min = t;
    if (max < t) max = t;
    count++;
    total += t;
  }

  reset() {
    resetLast = _perf.now();
    min = double.MAX_FINITE;
    max = double.MIN_POSITIVE;
    total = 0.0;
    count = 0;
  }

}

