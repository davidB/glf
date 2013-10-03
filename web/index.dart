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
import 'package:glf/glf_asset_pack.dart';
import 'package:glf/glf_renderera.dart';

const TexNormalsRandomL = "_TexNormalsRandom";
const TexNormalsRandomN = 28;
const TexVerticesL = "_TexVertices";
const TexVerticesN = 29;
const TexNormalsL = "_TexNormals";
const TexNormalsN = 30;

main(){
  var gl = (query("#canvas0") as CanvasElement).getContext3d(alpha: false, depth: true);
  if (gl == null) {
    print("webgl not supported");
    return;
  }
  //var gli = js.context.gli;
  //var result = gli.host.inspectContext(gl.canvas, gl);
  //var hostUI = new js.Proxy(gli.host.HostUI, result);
  //result.hostUI = hostUI; // just so we can access it later for debugging
  var am = initAssetManager(gl);
  new Main(new RendererA(gl), am).start();
}

AssetManager initAssetManager(gl) {
  var tracer = new AssetPackTrace();
  var stream = tracer.asStream().asBroadcastStream();
  new ProgressControler(query("#assetload")).bind(stream);
  new EventsPrintControler().bind(stream);

  var b = new AssetManager(tracer);
  b.loaders['img'] = new ImageLoader();
  b.importers['img'] = new NoopImporter();
  registerGlfWithAssetManager(gl, b);
  return b;
}

class EventsPrintControler {

  EventsPrintControler();

  StreamSubscription bind(Stream<AssetPackTraceEvent> tracer) {
    return tracer.listen(onEvent);
  }

  void onEvent(AssetPackTraceEvent event) {
    print("AssetPackTraceEvent : ${event}");
  }
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

var mdt = new glf.MeshDefTools();

class Main {

  final RendererA renderer;
  final AssetManager am;
  final Factory_Filter2D factory_filter2d;

  final Tick tick = new Tick();

  var _vertexUI; // = query('#vertex') as TextAreaElement;
  var _fragmentUI; //= query('#fragment') as TextAreaElement;
  var _selectShaderUI = query('#selectShader') as SelectElement;
  var _selectMeshUI = query('#selectMesh') as SelectElement;
  var _subdivisionMeshUI = query('#subdivisionMesh') as InputElement;
  var _loadShaderUI = query('#loadShader') as ButtonElement;
  var _applyShaderUI = query('#applyShader') as ButtonElement;
  var _errorUI = query('#errorTxt') as PreElement;
  var _showWireframeUI = query('#showWireframe') as CheckboxInputElement;
  var _showNormalsUI = query('#showNormals') as CheckboxInputElement;
  var _statsUpdateUI = query('#statsUpdate') as PreElement;
  var _statsLoopUI = query('#statsLoop') as PreElement;
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

  Main(this.renderer, am) :
    am = am,
    factory_filter2d = new Factory_Filter2D()..am = am
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
      //renderer.filters2d.add(factory_filter2d.makeBrightness(brightness : 0.0, contrast : 1.0, gamma : 2.2));
      //renderer.filters2d.add(factory_filter2d.makeConvolution3(Factory_Filter2D.c3_boxBlur));
      //renderer.filters2d.add(factory_filter2d.makeXWaves(() => tick.time / 1000.0));
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
    _vertexUI = js.retain((js.context as dynamic).CodeMirror.fromTextArea(query("#vertex"), js.map({"mode" : "glsl", "lineNumbers" : true})).doc);
    _fragmentUI = js.retain((js.context as dynamic).CodeMirror.fromTextArea(query("#fragment"), js.map({"mode" : "glsl", "lineNumbers" : true})).doc);
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
        ..["sLightDepth"] = ((ctx) => glf.injectTexture(ctx, lightFbo.texture, 31, "sLightDepth"))
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
    renderer.debugView = lightFbo.texture;
  }

  _initRendererPreDeferred() {
    var fboN = _initRendererPreDeferred0(renderer.cameraViewport, am['shader_deferred_normals'], TexNormalsL, TexNormalsN);
    var fboV = _initRendererPreDeferred0(renderer.cameraViewport, am['shader_deferred_vertices'], TexVerticesL, TexVerticesN);
    //renderer.debugView = fboV.texture;
    _initSSAO(fboN.texture, fboV.texture, am['texNormalsRandom']);
  }

  _initRendererPreDeferred0(vp, ctx, texName, texNum) {
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
        ..[texName] = ((ctx) => glf.injectTexture(ctx, fbo.texture, texNum, texName))
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
      glf.injectTexture(ctx, texNormals, TexNormalsN, TexNormalsL);
      glf.injectTexture(ctx, texVertices, TexVerticesN, TexVerticesL);
      glf.injectTexture(ctx, texNormalsRandom, TexNormalsRandomN, TexNormalsRandomL);
    };
    renderer.filters2d.insert(0, ssao);
  }
}

class Factory_Filter2D {
  static const c3_identity =         const[ 0.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 0.0000];
  static const c3_gaussianBlur =     const[ 0.0450, 0.1220, 0.0450, 0.1220, 0.3320, 0.1220, 0.0450, 0.1220, 0.0450];
  static const c3_gaussianBlur2 =    const[ 1.0000, 2.0000, 1.0000, 2.0000, 4.0000, 2.0000, 1.0000, 2.0000, 1.0000];
  static const c3_gaussianBlur3 =    const[ 0.0000, 1.0000, 0.0000, 1.0000, 1.0000, 1.0000, 0.0000, 1.0000, 0.0000];
  static const c3_unsharpen =        const[-1.0000,-1.0000,-1.0000,-1.0000, 9.0000,-1.0000,-1.0000,-1.0000,-1.0000];
  static const c3_sharpness =        const[ 0.0000,-1.0000, 0.0000,-1.0000, 5.0000,-1.0000, 0.0000,-1.0000, 0.0000];
  static const c3_sharpen =          const[-1.0000,-1.0000,-1.0000,-1.0000,16.0000,-1.0000,-1.0000,-1.0000,-1.0000];
  static const c3_edgeDetect =       const[-0.1250,-0.1250,-0.1250,-0.1250, 1.0000,-0.1250,-0.1250,-0.1250,-0.1250];
  static const c3_edgeDetect2 =      const[-1.0000,-1.0000,-1.0000,-1.0000, 8.0000,-1.0000,-1.0000,-1.0000,-1.0000];
  static const c3_edgeDetect3 =      const[-5.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 5.0000];
  static const c3_edgeDetect4 =      const[-1.0000,-1.0000,-1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 1.0000, 1.0000];
  static const c3_edgeDetect5 =      const[-1.0000,-1.0000,-1.0000, 2.0000, 2.0000, 2.0000,-1.0000,-1.0000,-1.0000];
  static const c3_edgeDetect6 =      const[-5.0000,-5.0000,-5.0000,-5.0000,39.0000,-5.0000,-5.0000,-5.0000,-5.0000];
  static const c3_sobelHorizontal =  const[ 1.0000, 2.0000, 1.0000, 0.0000, 0.0000, 0.0000,-1.0000,-2.0000,-1.0000];
  static const c3_sobelVertical =    const[ 1.0000, 0.0000,-1.0000, 2.0000, 0.0000,-2.0000, 1.0000, 0.0000,-1.0000];
  static const c3_previtHorizontal = const[ 1.0000, 1.0000, 1.0000, 0.0000, 0.0000, 0.0000,-1.0000,-1.0000,-1.0000];
  static const c3_previtVertical =   const[ 1.0000, 0.0000,-1.0000, 1.0000, 0.0000,-1.0000, 1.0000, 0.0000,-1.0000];
  static const c3_boxBlur =          const[ 0.1110, 0.1110, 0.1110, 0.1110, 0.1110, 0.1110, 0.1110, 0.1110, 0.1110];
  static const c3_triangleBlur =     const[ 0.0625, 0.1250, 0.0625, 0.1250, 0.2500, 0.1250, 0.0625, 0.1250, 0.0625];
  static const c3_emboss =           const[-2.0000,-1.0000, 0.0000,-1.0000, 1.0000, 1.0000, 0.0000, 1.0000, 2.0000];

  AssetManager am;

  init() {
    return Future.wait([
      am.loadAndRegisterAsset('filter2d_identity', 'filter2d', 'packages/glf/shaders/filters_2d/identity.frag', null, null),
      am.loadAndRegisterAsset('filter2d_brightness', 'filter2d', 'packages/glf/shaders/filters_2d/brightness.frag', null, null),
      am.loadAndRegisterAsset('filter2d_convolution3x3', 'filter2d', 'packages/glf/shaders/filters_2d/convolution3x3.frag', null, null),
      am.loadAndRegisterAsset('filter2d_x_waves', 'filter2d', 'packages/glf/shaders/filters_2d/x_waves.frag', null, null),
    ]).then((l) => am);

    /* An alternative to AssetManager would be to use :
     * HttpRequest.request("packages/glf/shaders/filters_2d/convolution3x3.frag", method: 'GET').then((r) {
     *    var filter2d = new glf.Filter2D(gl, r.responseText);
     * });
     */
  }

  makeIdentity() {
    return am['filter2d_identity'];
  }

  makeBrightness({double brightness : 0.0, contrast : 1.0, gamma : 2.2}) {
    return new glf.Filter2D.copy(am['filter2d_brightness'])
    ..cfg = (ctx) {
      ctx.gl.uniform1f(ctx.getUniformLocation('_Brightness'), brightness);
      ctx.gl.uniform1f(ctx.getUniformLocation('_Contrast'), contrast);
      ctx.gl.uniform1f(ctx.getUniformLocation('_InvGamma'), 1.0/gamma);
    };
  }

  makeConvolution3(List<double> c3_matrix) {
    var kernel = new Float32List.fromList(c3_matrix);
    return new glf.Filter2D.copy(am['filter2d_convolution3x3'])
    ..cfg = (ctx) => ctx.gl.uniform1fv(ctx.getUniformLocation('_Kernel[0]'), kernel)
    ;
  }

  makeXWaves(double offset()) {
    return new glf.Filter2D.copy(am['filter2d_x_waves'])
    ..cfg = (ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('_Offset'), offset())
    ;
  }

}



class Obj3D {
  var cameraReqN;
  var upd0;
  var geometry = new Geometry();
  var material;

  apply(renderer, ctx, onUpdate, glf.MeshDef md, showNormals) {
    _remove(renderer, onUpdate);
    _add(renderer, ctx, onUpdate, md, showNormals);
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
        ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.5, 0.5, 0.5);
        glf.injectTexture(ctx, tex, 0);
        glf.injectTexture(ctx, texNormal, 1, '_NormalMap0');
        glf.injectTexture(ctx, texDissolve0, 3, '_DissolveMap0');
        glf.injectTexture(ctx, texDissolve1, 4, '_DissolveMap1');
        glf.injectTexture(ctx, texDissolve2, 5, '_DissolveMap2');
        glf.injectTexture(ctx, texMatCap0, 10, '_MatCap0');
        glf.injectTexture(ctx, texMatCap1, 11, '_MatCap1');
        glf.injectTexture(ctx, texMatCap2, 12, '_MatCap2');
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
            ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.8, 0.8, 0.8);
            glf.makeNormalMatrix(geometry.transforms, geometry.normalMatrix);
            glf.injectMatrix4(ctx, geometry.transforms, glf.SFNAME_MODELMATRIX);
            glf.injectMatrix3(ctx, geometry.normalMatrix, glf.SFNAME_NORMALMATRIX);
            glf.injectTexture(ctx, tex, 0);
            glf.injectTexture(ctx, texNormal, 1);
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
    var material = new Material()
    //..transparent = true
    ..ctx = ctx
    ..cfg = (ctx) {
      ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.0, 0.5, 0.5);
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

