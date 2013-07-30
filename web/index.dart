import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'dart:web_gl' as GL;
import 'dart:typed_data';
import 'package:js/js.dart' as js;

import 'package:vector_math/vector_math.dart';

import '../lib/glf.dart' as glf;


main(){
  var gl = (query("#canvas0") as CanvasElement).getContext3d(depth: true);
  if (gl == null) {
    print("webgl not supported");
    return;
  }
  new Main(new Renderer(gl)).start();
}

class Renderer {
  final gl;

  final glf.ProgramsRunner lightRunner;
  final glf.ProgramsRunner cameraRunner;
  final glf.ProgramsRunner postRunner;

  var lightCtx = null;

  Renderer(gl) : this.gl = gl,
    lightRunner = new glf.ProgramsRunner(gl),
    cameraRunner = new glf.ProgramsRunner(gl),
    postRunner = new glf.ProgramsRunner(gl)
  ;


  init() {
    _initCamera();
    _initLight();
    _initPost();
  }

  _initCamera() {
    // Camera default setting for perspective use canvas area full
    var viewport = new glf.Viewport.defaultSettings(gl.canvas);
    viewport.camera.position.setValues(0.0, 0.0, 6.0);

    cameraRunner.register(new glf.RequestRunOn()
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
        gl.viewport(viewport.x, viewport.y, viewport.viewWidth, viewport.viewHeight);
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


    cameraRunner.register(viewport.makeRequestRunOn());
  }

  _initLight() {
    var _light = new glf.Viewport()
      ..viewWidth = 256
      ..viewHeight = 256
      ..sfname_projectionmatrix = "lightProj"
      ..sfname_viewmatrix = "lightView"
      ..sfname_rotmatrix = "lightRot"
      ..sfname_projectionviewmatrix = "lightProjView"
      ..camera.fovRadians = degrees2radians * 55.0
      ..camera.near = 1.0
      ..camera.far = (2.0 * 2.0 + 2.0 * 2.0 + 4.0 * 4.0) * 2.0
      ..camera.aspectRatio = 1.0
      ..camera.position.setValues(2.0, 2.0, 4.0)
      ..camera.focusPosition.setValues(0.0, 0.0, 0.0)
      ;
    lightRunner.enableFrameBuffer(_light.viewWidth, _light.viewHeight);
    lightCtx = new glf.ProgramContext(gl, lightVert, lightFrag);
    lightRunner.register(_light.makeRequestRunOn()
      ..ctx = lightCtx
      ..beforeAll = (gl) {
        gl.viewport(0, 0, _light.viewWidth, _light.viewHeight);
        gl.clearColor(1.0, 1.0, 1.0, 1.0);
        gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
      }
      ..before =(ctx) {
        ctx.gl.uniform1f(ctx.getUniformLocation('lightFar'), _light.camera.far / 2.0);
      }
    );

    cameraRunner.register(new glf.RequestRunOn()
      ..autoData = (new Map()
        ..addAll(_light.autoData)
        ..["sLightDepth"] = ((ctx) => glf.injectTexture(ctx, lightRunner.frameTexture, 31, "sLightDepth"))
        ..["lightFar"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightFar'), _light.camera.far / 2.0))
        ..["lightConeAngle"] = ((ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('lightConeAngle'), _light.camera.fovRadians * radians2degrees))
      )
    );
  }

  _initPost() {
    var _post = new glf.ViewportPlan()
    ..viewWidth = 256
    ..viewHeight = 256
    ..x = 10
    ..y = 0
    ;
    postRunner.register(_post.makeRequestRunOn());
    var md = glf.makeMeshDef_plane()
        ..normals = null
        ;
    var mesh = new glf.Mesh()..setData(gl, md);
    postRunner.register(new glf.RequestRunOn()
    ..ctx = new glf.ProgramContext(gl, texVert, texFrag)
    ..beforeAll =(ctx) {
      gl.viewport(_post.x, _post.y, _post.viewWidth, _post.viewHeight);
      //gl.clearColor(1.0, 1.0, 1.0, 1.0);
      //gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
    }
    ..at =(ctx){
      if (lightRunner.frameTexture != null) {
        glf.injectTexture(ctx, lightRunner.frameTexture, 0);
        mesh.injectAndDraw(ctx);
      }
    }
    );
  }
  run() {
    lightRunner.run();
    cameraRunner.run();
    postRunner.run();
  }
}

class Main {

  final Renderer renderer;

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

  Main(this.renderer);

  start() {
    renderer.init();

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
    var md = null;
    switch(_selectMeshUI.value) {
      case 'box24' :
        md = glf.makeMeshDef_cube24Vertices(dx: 2.0, dy: 1.0, dz: 0.5, ty: 1.0);
        break;
      case 'box24-t' :
        md = glf.makeMeshDef_cube24Vertices(dx: 2.0, dy: 1.0, dz: 0.5, tx: 2.0, ty: 1.0, tz: 0.5);
        break;
      case 'cube8' :
        md = glf.makeMeshDef_cube8Vertices(dx: 0.5, dy: 0.5, dz: 0.5);
        break;
      case 'sphereL':
        md = glf.makeMeshDef_sphere(subdivisionsAxis : sub, subdivisionsHeight : sub);
        break;
      default:
        md = glf.makeMeshDef_cube24Vertices(dx: 0.5, dy: 0.5, dz: 0.5);
    }
    if (_showWireframeUI.checked) {
      md.lines = glf.extractWireframe(md.triangles);
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
    }catch(e) {
      _errorUI.text = e.toString();
    }
  }
}

class Obj3D {
  var cameraReq;
  var cameraReqN;
  var lightReq;
  var upd0;

  apply(renderer, ctx, onUpdate, glf.MeshDef md, showNormals) {
    _remove(renderer, ctx, onUpdate);
    _add(renderer, ctx, onUpdate, md, showNormals);
  }

  _remove(renderer, ctx, onUpdate) {
    if (lightReq != null) {
      renderer.lightRunner.unregister(lightReq);
      lightReq = null;
    }
    if (cameraReq != null) {
      renderer.cameraRunner.unregister(cameraReq);
      cameraReq = null;
    }
    if (cameraReqN != null) {
      renderer.cameraRunner.unregister(cameraReqN);
      cameraReqN = null;
    }
    if (upd0 != null) {
      onUpdate.remove(upd0);
      upd0 = null;
    }
  }

  _add(renderer, ctx, onUpdate, md, showNormals) {
    // Create a cube geometry +  a texture + a transform + a shader program to display all
    // same parameter with other transforms can be reused to display several cubes
    var transforms = new Matrix4.identity();
    var normalMatrix = new Matrix3.zero();

    var mesh = new glf.Mesh()..setData(ctx.gl, md);

    // keep ref to RequestRunOn to be able to register/unregister (show/hide)
    var tex = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/dirt.jpg"));
    var texNormal = glf.createTexture(ctx.gl, new Uint8List.fromList([0, 0, 120]), Uri.parse("_images/shaders_offest_normalmap.jpg"));

    cameraReq = new glf.RequestRunOn()
      ..ctx = ctx
      ..at = (ctx) {
        ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.5, 0.5, 0.5);
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
    renderer.cameraRunner.register(cameraReq);

    lightReq = new glf.RequestRunOn()
      ..ctx = renderer.lightCtx
      ..at = (ctx) {
        glf.makeNormalMatrix(transforms, normalMatrix);
        glf.injectMatrix4(ctx, transforms, glf.SFNAME_MODELMATRIX);
        mesh.injectAndDraw(ctx);
      }
    ;
    renderer.lightRunner.register(lightReq);

    upd0 = (dt) => transforms.rotateY(dt / 5000 * 2 * math.PI);
    onUpdate.add(upd0);

    if (showNormals) {
      var mdNormal = glf.extractNormals(md);
      var meshNormal = new glf.Mesh()..setData(ctx.gl, mdNormal);
      var programCtxN = glf.loadProgramContext(ctx.gl, Uri.parse("packages/glf/shaders/default.vert"), Uri.parse("packages/glf/shaders/default.vert"));

      programCtxN.then((ctxN) {
        cameraReqN = new glf.RequestRunOn()
          ..ctx = ctxN
          ..at = (ctx) {
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
        renderer.cameraRunner.register(cameraReqN);
      });
    }

  }
}

class Plane {
  var cameraReq;
  var cameraReqN;
  var lightReq;

  applyMaterial(renderer, ctx) {
    _remove(renderer, ctx);
    _add(renderer, ctx);
  }

  _remove(renderer, ctx) {
    if (lightReq != null) {
      renderer.lightRunner.unregister(lightReq);
      lightReq = null;
    }
    if (cameraReq != null) {
      renderer.cameraRunner.unregister(cameraReq);
      cameraReq = null;
    }
    if (cameraReqN != null) {
      renderer.cameraRunner.unregister(cameraReqN);
      cameraReqN = null;
    }
  }

  _add(renderer, ctx) {
    var md = glf.makeMeshDef_plane(dx: 3.0, dy: 3.0);
    var mesh = new glf.Mesh()..setData(ctx.gl, md);

    var transforms = new Matrix4.identity();
    transforms.translate(0.0, 0.0, 0.0);
    //transforms.rotateX(math.PI * -0.5);
    var normalMatrix = new Matrix3.zero();

    cameraReq = new glf.RequestRunOn()
      ..ctx = ctx
      ..at = (ctx) {
        ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.0, 0.5, 0.5);
        glf.makeNormalMatrix(transforms, normalMatrix);
        glf.injectMatrix4(ctx, transforms, glf.SFNAME_MODELMATRIX);
        glf.injectMatrix3(ctx, normalMatrix, glf.SFNAME_NORMALMATRIX);
        mesh.injectAndDraw(ctx);
      }
    ;
    renderer.cameraRunner.register(cameraReq);

    lightReq = new glf.RequestRunOn()
      ..ctx = renderer.lightCtx
      ..at = (ctx) {
        glf.makeNormalMatrix(transforms, normalMatrix);
        glf.injectMatrix4(ctx, transforms, glf.SFNAME_MODELMATRIX);
        mesh.injectAndDraw(ctx);
      }
    ;
    renderer.lightRunner.register(lightReq);
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
var texVert = """
attribute vec3 _Vertex;
attribute vec2 _TexCoord0;
varying vec2 vTexCoord0;
void main() {
vTexCoord0 = _TexCoord0.xy;
gl_Position = vec4(vTexCoord0 * 2.0 - 1.0, 0.0, 1.0);
}""";
var texFrag = """
#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D _Tex0;
varying vec2 vTexCoord0;
void main() {
//gl_FragColor = vec4(vTexCoord0.xy, 1.0, 1.0);
gl_FragColor = texture2D(_Tex0, vTexCoord0);
}
""";
var lightVert = """
attribute vec3 _Vertex;
attribute vec3 _Normal;

uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

varying vec3 normal;
varying vec4 position;

uniform mat4 lightProj, lightView;

void main(){
  normal = _NormalMatrix * _Normal;
  vec4 p = _ModelMatrix * vec4(_Vertex, 1.0);
  gl_Position = lightProj * lightView * p;
  position = p;
  //position = lightProj * lightView * p ;
}
""";
var lightFrag = """
#ifdef GL_ES
precision mediump float;
#endif
varying vec3 normal;
varying vec4 position;

uniform mat4 lightProj, lightView;
uniform float lightFar;

void main(){
  vec3 worldNormal = normalize(normal);
  vec3 lightPos = (lightView * position).xyz;
  float depth = clamp(length(lightPos)/lightFar, 0.0, 1.0);
  //float depth = clamp(position.z/lightFar, 0.0, 1.0);
  gl_FragColor = vec4(vec3(depth), 1.0);

}
""";

