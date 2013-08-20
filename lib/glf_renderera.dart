library glf_renderera;

import 'package:glf/glf.dart' as glf;
import 'package:vector_math/vector_math.dart';
import 'dart:web_gl' as WebGL;
import 'dart:html';

class Renderer2SolidCache {
  Geometry geometry;
  Material material;
  glf.RequestRunOn cameraReq;
  glf.RequestRunOn geomReq;

  Renderer2SolidCache(this.geometry, this.material) {
    cameraReq = new glf.RequestRunOn()
    ..ctx = material.ctx
    ..at = (ctx) {
      material.cfg(ctx);
      geometry.injectAndDraw(ctx);
    }
    ;
    geomReq = new glf.RequestRunOn()
    ..atEach = geometry.injectAndDraw
    ;
  }
}

class RendererA {
  final gl;

  final glf.ProgramsRunner _preRunner;
  final glf.ProgramsRunner _cameraRunner;
  glf.Filter2DRunner _post2d;
  glf.Filter2DRunner _post2dw1;

  get filters2d => _post2d.filters;

  get debugView => _post2dw1.texInit;
  set debugView(WebGL.Texture tex) => _post2dw1.texInit = tex;

  final cameraViewport;

  var _reqs = new Map<Geometry, Renderer2SolidCache>();

  /// Aabb of the scene used to adjust some parameter (like near, far shadowMapping)
  /// it is not updated when solid is add (or updated or removed).
  final sceneAabb = new Aabb3()
  ..min.setValues(-4.0, -4.0, -1.0)
  ..max.setValues(4.0, 4.0, 4.0)
  ;

  RendererA(gl) : this.gl = gl,
    _preRunner = new glf.ProgramsRunner(gl),
    _cameraRunner = new glf.ProgramsRunner(gl),
    cameraViewport = new glf.ViewportCamera.defaultSettings(gl.canvas)
  ;

  addPrepare(glf.RequestRunOn req) {
    _preRunner.register(req);
  }

  removePrepare(glf.RequestRunOn req) {
    _preRunner.unregister(req);
  }

  add(glf.RequestRunOn req) {
    _cameraRunner.register(req);
  }

  remove(glf.RequestRunOn req) {
    _cameraRunner.unregister(req);
  }

  addSolid(Geometry geometry, Material material) {
    var e = new Renderer2SolidCache(geometry, material);
    _reqs[geometry] = e;
    addPrepare(e.geomReq);
    add(e.cameraReq);
  }

  removeSolid(Geometry geometry) {
    var e = _reqs[geometry];
    if (e != null) {
      removePrepare(e.geomReq);
      remove(e.cameraReq);
      _reqs[geometry] = null;
    }
  }

  var _x0, _x1, _x2;
  init() {
    //_x0 = gl.getExtension("OES_standard_derivatives");
    _x1 = gl.getExtension("OES_texture_float");
    //_x2 = gl.getExtension("GL_EXT_draw_buffers");
    _initPostW0();
    _initPostW1();
    _initCamera();
    _initPre();
  }

  _initCamera() {
    // Camera default setting for perspective use canvas area full
    var viewport = cameraViewport;
    var camera = viewport.camera;
    camera.position.setValues(0.0, 0.0, 6.0);
    camera.focusPosition.setValues(0.0, 0.0, 0.0);
    camera.adjustNearFar(sceneAabb, 0.1, 0.1);
    //TODO support resize
    var cameraFbo = new glf.FBO(gl)..make(width : viewport.viewWidth, height : viewport.viewHeight);
    var r = new glf.RequestRunOn()
      ..setup= (gl) {
        if (true) {
          // opaque
          gl.disable(WebGL.BLEND);
          gl.depthFunc(WebGL.LEQUAL);
          //gl.depthFunc(WebGL.LESS); // default value
          gl.enable(WebGL.DEPTH_TEST);
//        } else {
//          // blend
//          gl.disable(WebGL.DEPTH_TEST);
//          gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE);
//          gl.enable(WebGL.BLEND);
        }
        gl.colorMask(true, true, true, true);
        viewport.setup(gl);
      }
      ..beforeAll = (gl) {
        gl.bindFramebuffer(WebGL.FRAMEBUFFER, cameraFbo.buffer);
        gl.viewport(viewport.x, viewport.y, viewport.viewWidth, viewport.viewHeight);
        //gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clearColor(1.0, 0.0, 0.0, 1.0);
        //gl.clearColor(1.0, 1.0, 1.0, 1.0);
        gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
        //gl.clear(WebGL.COLOR_BUFFER_BIT);
      }
      ..beforeEach =  viewport.injectUniforms
//      ..onRemoveProgramCtx = (prunner, ctx) {
//        ctx.delete();
//      }
    ;
    add(r);
    _post2d.texInit = cameraFbo.texture;
  }

  _initPre() {
  }

  _initPostW1() {
    var view2d = new glf.ViewportPlan()
    ..viewWidth = 256
    ..viewHeight = 256
    ..x = 10
    ..y = 0
    ;
    _post2dw1 = new glf.Filter2DRunner(gl, view2d);
    HttpRequest.request('packages/glf/shaders/filters_2d/identity.frag', method: 'GET').then((r) {
      _post2dw1.filters.add(new glf.Filter2D(gl, r.responseText));
    });
  }

  _initPostW0() {
    var view2d = new glf.ViewportPlan()..fullCanvas(gl.canvas);
    _post2d = new glf.Filter2DRunner(gl, view2d);
  }

  run() {
    _preRunner.run();
    _cameraRunner.run();
    _post2d.run();
    if (_post2dw1.texInit != null) _post2dw1.run();
  }

}

class Geometry {
  final transforms = new Matrix4.identity();
  final normalMatrix = new Matrix3.zero();
  final _mesh = new glf.Mesh();
  var _md = null;
  var meshNeedUpdate = true;
  var verticesNeedUpdate = false;
  get meshDef => _md;
  set meshDef(glf.MeshDef v) {
    _md = v;
    meshNeedUpdate = true;
  }

  injectAndDraw(glf.ProgramContext ctx) {
    if (meshNeedUpdate && _md != null) {
      _mesh.setData(ctx.gl, _md);
      meshNeedUpdate = false;
      verticesNeedUpdate = false;
    }
    if (verticesNeedUpdate && _md != null) {
      _mesh.vertices.setData(ctx.gl, _md.vertices);
      verticesNeedUpdate = false;
    }
    glf.injectMatrix4(ctx, transforms, glf.SFNAME_MODELMATRIX);
    glf.injectMatrix3(ctx, normalMatrix, glf.SFNAME_NORMALMATRIX);
    _mesh.inject(ctx);
    _mesh.draw(ctx);
  }
}

class Material {
  glf.ProgramContext ctx = null;
  glf.RunOnProgramContext cfg = null;
}