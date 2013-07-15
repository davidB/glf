import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'dart:web_gl' as GL;
import 'dart:typed_data';
import 'package:js/js.dart' as js;

import 'package:vector_math/vector_math.dart';

import '../lib/glf.dart' as glf;


main(){
  var gl = (query("#canvas0") as CanvasElement).getContext3d();
  if (gl == null) {
    print("webgl not supported");
    return;
  }
  new Main(gl).start();
}

class Main {
  final gl;

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
  var req0 = null;
  var upd0 = null;
  var reqN = null;
  var _programCtxN = null;
  var _programCtxCache = new glf.ProgramContextCache();

  glf.ProgramsRunner _prunner = null;
  final onUpdate = new List<Function>();

  Main(this.gl);

  start() {
    _programCtxN = glf.loadProgramContext(gl, Uri.parse("packages/glf/shaders/default.vert"), Uri.parse("packages/glf/shaders/default.vert"));
    _prunner = new glf.ProgramsRunner(gl);

    _prunner.register(new glf.RequestRunOn()
      ..setup= (gl) {
        if (true) {
          // opaque
          gl.disable(GL.BLEND);
          gl.depthFunc(GL.LEQUAL);
          //gl.depthFunc(GL.LESS); // default value
          gl.enable(GL.DEPTH_TEST);
//        } else {
//          // blend
//          gl.disable(GL.DEPTH_TEST);
//          gl.blendFunc(GL.SRC_ALPHA, GL.ONE);
//          gl.enable(GL.BLEND);
        }
        gl.colorMask(true, true, true, true);
      }
      ..beforeAll = (gl) {
        //gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clearColor(1.0, 0.0, 0.0, 1.0);
        //gl.clearColor(1.0, 1.0, 1.0, 1.0);
        gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        //gl.clear(GL.COLOR_BUFFER_BIT);
      }
//      ..onRemoveProgramCtx = (prunner, ctx) {
//        ctx.delete();
//      }
    );

    // Camera default setting for perspective use canvas area full
    var viewport = new glf.Viewport.defaultSettings(gl.canvas);
    viewport.camera.position.setValues(0.0, 0.0, 6.0);

    _prunner.register(viewport.makeRequestRunOn());

    var tprevious = 0;
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
    var lastDisplay = 0;
    update(t){
      statsU.start();
      window.animationFrame.then(update);
      // rule to modify transforms of the global mesh
      var dt = t - tprevious;
      tprevious = t;
      // rule to modify one vertice of the mesh
      //md.vertices[0] = 4.0 * (t % 3000)/3000 - 2.0;

      onUpdate.forEach((f) => f(dt));
      // render (run shader's program)
      _prunner.run();
      statsU.stop();
      statsL.stop();
      statsL.start();
    };
    window.animationFrame.then(update);
    initEditors();
    bindUI();
    _selectShaderUI.selectedIndex = 0;
    loadShaderCode(_selectShaderUI.value).then((_) => apply());
    //_loadShaderUI.click();
    //_applyShaderUI.click();
  }


  initEditors() {
    _vertexUI = js.retain(js.context.CodeMirror.fromTextArea(query("#vertex"), js.map({"mode" : "glsl", "lineNumbers" : true})).doc);
    _fragmentUI = js.retain(js.context.CodeMirror.fromTextArea(query("#fragment"), js.map({"mode" : "glsl", "lineNumbers" : true})).doc);
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
    switch(_selectMeshUI.value) {
      case 'box24' :
        return glf.makeMeshDef_cube24Vertices(dx: 2.0, dy: 1.0, dz: 0.5, ty: 1.0);
      case 'cube8' :
        return glf.makeMeshDef_cube8Vertices(dx: 0.5, dy: 0.5, dz: 0.5);
      case 'sphereL':
        return glf.makeMeshDef_sphere(subdivisionsAxis : sub, subdivisionsHeight : sub);
      default:
        return glf.makeMeshDef_cube24Vertices(dx: 0.5, dy: 0.5, dz: 0.5);
    }
  }

  apply() {
    try {
      _errorUI.text = '';
      _apply0();
    }catch(e) {
      _errorUI.text = e.toString();
    }
  }

  _apply0() {
    var ctx = makeShaderProgram(gl);

    // Create a cube geometry +  a texture + a transform + a shader program to display all
    // same parameter with other transforms can be reused to display several cubes
    var transforms = new Matrix4.identity();
    var normalMatrix = new Matrix3.zero();

    var md = makeMeshDef();
    if (_showWireframeUI.checked) {
      md.lines = glf.extractWireframe(md.triangles);
      md.triangles = null;
    }
    var mesh = new glf.Mesh()..setData(ctx.gl, md);

    // keep ref to RequestRunOn to be able to register/unregister (show/hide)
    var tex = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/dirt.jpg"));
    var texNormal = glf.createTexture(ctx.gl, new Uint8List.fromList([0, 0, 120]), Uri.parse("_images/shaders_offest_normalmap.jpg"));

    if (req0 != null) {
      _prunner.unregister(req0);
      req0 = null;
    }
    req0 = new glf.RequestRunOn()
      ..ctx = ctx
      ..at = (ctx) {
        ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.5, 0.5, 0.5);
        ctx.gl.uniform1i(ctx.getUniformLocation('useLights'), 1);
        glf.makeNormalMatrix(transforms, normalMatrix);
        glf.injectMatrix4(ctx, transforms, glf.SFNAME_MODELMATRIX);
        glf.injectMatrix3(ctx, normalMatrix, glf.SFNAME_NORMALMATRIX);
        glf.injectTexture(ctx, tex, 0);
        glf.injectTexture(ctx, texNormal, 1);
        // vertices of the mesh can be modified in update loop, so update the data to GPU
        //mesh.vertices.setData(ctx.gl, md.vertices);
        mesh.injectAndDraw(ctx);
      }
    ;
    _prunner.register(req0);

    if (upd0 != null) {
      onUpdate.remove(upd0);
      upd0 = null;
    }
    upd0 = (dt) => transforms.rotateY(dt / 5000 * 2 * math.PI);
    onUpdate.add(upd0);


    if (reqN != null) {
      _prunner.unregister(reqN);
      reqN = null;
    }
    if (_showNormalsUI.checked) {
      var mdNormal = glf.extractNormals(md);
      var meshNormal = new glf.Mesh()..setData(ctx.gl, mdNormal);
      _programCtxN.then((ctxN) {
        reqN = new glf.RequestRunOn()
          ..ctx = ctxN
          ..at = (ctx) {
            ctx.gl.uniform1i(ctx.getUniformLocation('useLights'), 0);
            ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.8, 0.8, 0.8);
            glf.makeNormalMatrix(transforms, normalMatrix);
            glf.injectMatrix4(ctx, transforms, glf.SFNAME_MODELMATRIX);
            glf.injectMatrix3(ctx, normalMatrix, glf.SFNAME_NORMALMATRIX);
            glf.injectTexture(ctx, tex, 0);
            glf.injectTexture(ctx, texNormal, 1);
            // vertices of the mesh can be modified in update loop, so update the data to GPU
            //mesh2.vertices.setData(ctx.gl, md2.vertices);
            meshNormal.injectAndDraw(ctx);
          }
        ;
        _prunner.register(reqN);
      });
    }
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