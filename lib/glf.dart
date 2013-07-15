// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
library glf;

/// source of inspiration (lot of to learn from them):
/// * [GLOW](http://i-am-glow.com/)
/// * [lightgl.js](https://github.com/evanw/lightgl.js)
/// * [tdl](https://github.com/greggman/tdl)
/// * [Learning WebGL : lessons](http://learningwebgl.com/blog/?page_id=1217) and the port to dart
///
/// TODO : docs + samples
import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'dart:web_gl';
import 'dart:typed_data';
import 'package:crypto/crypto.dart'; // for cache
import 'package:vector_math/vector_math.dart';

part 'glf/mesh.dart';
part 'glf/mesh_primitives.dart';
part 'glf/textures.dart';
part 'glf/viewport.dart';

// follow OpenGL ES name but replace "gl_" prefix by "_" (see [GLSL QuickRef](http://mew.cx/glsl_quickref.pdf) )
const SFNAME_VERTICES = "_Vertex";
const SFNAME_TEXCOORDS = "_TexCoord0";
const SFNAME_COLORS = "_Color";
const SFNAME_NORMALS = "_Normal";
const SFNAME_NORMALMATRIX = "_NormalMatrix";
const SFNAME_MODELMATRIX = "_ModelMatrix";
const SFNAME_VIEWMATRIX = "_ViewMatrix";
const SFNAME_PROJECTIONMATRIX = "_ProjectionMatrix";
const SFNAME_PROJECTIONVIEWMATRIX = "_ProjectionViewMatrix";


/// Create a WebGL [Program], compiling [Shader]s from passed in sources and
/// cache [UniformLocation]s and AttribLocations.
///
/// TODO may be preload location instead of ask on demand (like a cache), to find uniforms and attributes  /(uniform|attribute)\s+\S+\s+(\S+)\s*;/g;
class ProgramContext {
  final RenderingContext gl;
  Program program;

  final _attributes = new Map<String, int>();
  final _uniforms = new Map<String, UniformLocation>();
  Shader _vertShader;
  Shader _fragShader;

  // following field are stored in ProgramContext to avoid usage on an associative array ProgramContext -> RunOnProgramContext
  final _befores = new List<RunOnProgramContext>();
  final _ats = new List<RunOnProgramContext>();

  ProgramContext(this.gl, String vertSrc, String fragSrc) {
    _vertShader = _compileShader(gl, vertSrc, VERTEX_SHADER);
    _fragShader = _compileShader(gl, fragSrc, FRAGMENT_SHADER);
    program = _linkProgram(gl, _vertShader, _fragShader);
  }

  int getAttribLocation(String v) {
    var b = _attributes[v];
    if (b == null) {
      b = gl.getAttribLocation(program, v);
      _attributes[v] = b;
    }
    return b;
  }

  UniformLocation getUniformLocation(String v) {
    var b = _uniforms[v];
    if (b == null) {
      b = gl.getUniformLocation(program, v);
      _uniforms[v] = b;
    }
    return b;
  }

  delete() {
    if (_fragShader != null) {
      gl.detachShader(program, _fragShader);
      gl.deleteShader(_fragShader);
      _fragShader = null;
    }
    if (_vertShader != null) {
      gl.detachShader(program, _vertShader);
      gl.deleteShader(_vertShader);
      _vertShader = null;
    }
    if (program != null) {
     gl.deleteProgram(program);
     program = null;
    }
  }
}

class ProgramContextCache {
  final _cache = new Map<String, ProgramContext>();
  find(gl, String vertSrc, String fragSrc) {
    var s = new SHA1();
    s.add(vertSrc.codeUnits);
    s.add(fragSrc.codeUnits);
    var key = CryptoUtils.bytesToHex(s.close());
    var v = _cache[key];
    if (v == null) {
      v = new ProgramContext(gl, vertSrc, fragSrc);
      _cache[key] = v;
    }
    return v;
  }
}

class ProgramsRunner {
  final RenderingContext gl;
  final _ctxs = new List<ProgramContext>();
  final _setups = new List<RunOnRenderingContext>();
  final _beforeAlls = new List<RunOnRenderingContext>();
  final _afterAlls =  new List<RunOnRenderingContext>();
  final _teardowns = new List<RunOnRenderingContext>();
  final _onAddProgramCtxs = new List<RunOnProgramContextRegistration>();
  final _onRemoveProgramCtxs = new List<RunOnProgramContextRegistration>();

  ProgramsRunner(this.gl);

  register(RequestRunOn req) {
    if ((req.ctx != null) && (req.ctx.gl != gl)) throw new Exception("ProgramsRunner only accept request about same RenderingContext : req.ctx.gl != this.gl");

    if (req.setup != null) _setups.add(req.setup);

    if (req.beforeAll != null) _beforeAlls.add(req.beforeAll);
    if (req.onAddProgramCtx != null) _onAddProgramCtxs.add(req.onAddProgramCtx);
    if (req.onRemoveProgramCtx != null) _onRemoveProgramCtxs.add(req.onRemoveProgramCtx);

    if (req.ctx != null) {
      var isNew = !_ctxs.contains(req.ctx);
      if (isNew) {
        _ctxs.add(req.ctx);
      }
      if (req.before != null) req.ctx._befores.add(req.before);
      if (req.at != null) req.ctx._ats.add(req.at);
      if (isNew) {
        _onAddProgramCtxs.forEach((f)=> f(this, req.ctx));
      }
    }
  }

  //TODO test if Function can be removed from list (equality)
  //TODO remove from _ctxs is no longer need the program (when removing the last at no at method)
  unregister(RequestRunOn req) {
    if (req.teardown != null) _teardowns.add(req.teardown);

    if (req.beforeAll != null) _beforeAlls.remove(req.beforeAll);
    if (req.onAddProgramCtx != null) _onAddProgramCtxs.remove(req.onAddProgramCtx);
    if (req.onRemoveProgramCtx != null) _onAddProgramCtxs.remove(req.onRemoveProgramCtx);

    if (req.ctx != null) {
      if (req.before != null) req.ctx._befores.remove(req.before);
      if (req.at != null){
        req.ctx._ats.remove(req.at);
        if (req.ctx._ats.length == 0) {
          _onRemoveProgramCtxs.forEach((f)=> f(this, req.ctx));
          _ctxs.remove(req.ctx);
        }
      }
    }
  }

  //TODO should be to most optimized call
  run() {
    _teardowns.forEach((f) => f(gl));
    _teardowns.clear();

    _setups.forEach((f) => f(gl));
    _setups.clear();

    _beforeAlls.forEach((f) => f(gl));

    _ctxs.forEach((ctx) {
      // useProgram is done outof draw to allow factorisation later
//      ctx.gl.useProgram(ctx.program);
//      ctx._befores.forEach((f) => f(ctx));
//      ctx._ats.forEach((f) => f(ctx));
      ctx._ats.forEach((f){
        ctx.gl.useProgram(ctx.program);
        ctx._befores.forEach((f) => f(ctx));
        f(ctx);
      });
    });

    _afterAlls.forEach((f) => f(gl));
  }
}

typedef void RunOnRenderingContext(RenderingContext gl);
typedef void RunOnProgramContext(ProgramContext ctx);
typedef void RunOnProgramContextRegistration(ProgramsRunner pr, ProgramContext ctx);

class RequestRunOn {
  ProgramContext ctx = null;
  RunOnRenderingContext setup = null;
  RunOnRenderingContext beforeAll = null;
  RunOnProgramContext before = null;
  RunOnProgramContext at = null;
  RunOnRenderingContext teardown = null;
  RunOnRenderingContext afterAll = null;
  RunOnProgramContextRegistration onAddProgramCtx = null;
  RunOnProgramContextRegistration onRemoveProgramCtx = null;
}

_compileShader(RenderingContext gl, String src, int type) {
  var shader = gl.createShader(type);
  gl.shaderSource(shader, src);
  gl.compileShader(shader);
  var status = (gl.getShaderParameter(shader, COMPILE_STATUS).toString() == "true");
  if (!status) {
    var msg = gl.getShaderInfoLog(shader);
    gl.deleteShader(shader);
    shader = null;
    throw new Exception("An error occurred compiling the shaders: ${status}: ${msg}\n ${src} ");
  }
  return shader;
}

_linkProgram(RenderingContext gl, Shader vertex, Shader fragment, [deleteShaderOnFailure = true]) {
  var program = gl.createProgram();
  gl.attachShader(program, vertex);
  gl.attachShader(program, fragment);
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, LINK_STATUS)) {
    var msg = gl.getProgramInfoLog(program);
    gl.detachShader(program, fragment);
    gl.detachShader(program, vertex);
    if (deleteShaderOnFailure) {
      gl.deleteShader(vertex);
      gl.deleteShader(fragment);
    }
    gl.deleteProgram(program);
    program = null;
    throw new Exception("An error occurred compiling the shaders: ${msg}");
  }
  return program;
}


void injectMatrix4(ProgramContext ctx, Matrix4 mat, String sname) {
  var u = ctx.getUniformLocation(sname);
  if (u != null) {
    ctx.gl.uniformMatrix4fv(u, false, mat.storage);
  }
}

void injectMatrix3(ProgramContext ctx, Matrix3 mat, String sname) {
  var u = ctx.getUniformLocation(sname);
  if (u != null) {
    ctx.gl.uniformMatrix3fv(u, false, mat.storage);
  }
}
//makeNormalMatrix(Matrix4 transforms, Matrix4 out){
//  return out
//  ..setIdentity()
//  ..setRotation(transforms.getRotation()) //TODO optimize avoid Matrix3 creation
//  //..copyInverse(transforms)
//  ..transposeRotation()
//  ;
//}

makeNormalMatrix(Matrix4 transforms, Matrix3 out){
  // extract rotation
  out.storage[0] = transforms.storage[0];
  out.storage[1] = transforms.storage[1];
  out.storage[2] = transforms.storage[2];
  out.storage[3] = transforms.storage[4];
  out.storage[4] = transforms.storage[5];
  out.storage[5] = transforms.storage[6];
  out.storage[6] = transforms.storage[8];
  out.storage[7] = transforms.storage[9];
  out.storage[8] = transforms.storage[10];
  return out
    ..invert()
    ..transpose()
  ;
}

/// a very basic http loader for ProgramContext. It can be used for demo,
/// bootstrap, ... until you don't a have other asset loader.
Future<ProgramContext> loadProgramContext(gl, Uri vsUri, Uri fsUri) {
  return Future.wait([
    HttpRequest.request(vsUri.toString(), method: 'GET'),
    HttpRequest.request(fsUri.toString(), method: 'GET')
  ])
  .then((l) => new ProgramContext(gl, l[0].responseText, l[1].responseText))
  ;
}
