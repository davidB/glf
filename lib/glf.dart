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
import 'dart:mirrors';

part 'glf/mesh.dart';
part 'glf/meshdef.dart';
part 'glf/textures.dart';
part 'glf/viewport.dart';
part 'glf/filters_2d.dart';

// follow OpenGL ES name but replace "gl_" prefix by "_" (see [GLSL QuickRef](http://mew.cx/glsl_quickref.pdf) )
const SFNAME_VERTICES = "_Vertex";
const SFNAME_TEXCOORDS = "_TexCoord";
const SFNAME_COLORS = "_Color";
const SFNAME_NORMALS = "_Normal";
const SFNAME_NORMALMATRIX = "_NormalMatrix";
const SFNAME_MODELMATRIX = "_ModelMatrix";
const SFNAME_VIEWMATRIX = "_ViewMatrix";
const SFNAME_ROTATIONMATRIX = "_RotMatrix";
const SFNAME_PROJECTIONMATRIX = "_ProjectionMatrix";
const SFNAME_PROJECTIONVIEWMATRIX = "_ProjectionViewMatrix";
const SFNAME_PIXELSIZE = "_PixelSize";

/// A class to wrappe a WebGL RenderingContext and print every call
/// To use for debug only, eg:
///    var gl0 = (query("#canvas0") as CanvasElement).getContext3d(alpha: false, depth: true);
///    var gl = gl0;
///    gl = new glf.RenderingContextTracer(gl0);
///    ...
///    var am = initAssetManager(gl);
///    var renderer = new RendererA(gl);
///    ...
///    gl.printing = true;
///
///  Run this class in DartVM only !
class RenderingContextTracer implements RenderingContext{
  final  _wrappee;
  bool printing = false;

  RenderingContextTracer(wrappee) :
    _wrappee = reflect(wrappee)
  ;

  noSuchMethod(Invocation msg) {
    if (printing) print("[TRACE] ${msg.memberName}(${msg.positionalArguments})");
    return _wrappee.delegate(msg);
  }
}

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
  var usage = 0;

  ProgramContext(this.gl, String vertSrc, String fragSrc) {
    try {
      _vertShader = _compileShader(gl, vertSrc, VERTEX_SHADER);
      _fragShader = _compileShader(gl, fragSrc, FRAGMENT_SHADER);
      program = _linkProgram(gl, _vertShader, _fragShader);
    } finally {
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
    }
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

  disableAllAttrib([ProgramContext exceptFrom]) {
    var except = (exceptFrom == null)? []:exceptFrom._attributes.keys;
    _attributes.forEach((k,v){
      if (v != -1 && !except.contains(k)) {
        gl.disableVertexAttribArray(v);
      }
    });
  }
  delete() {
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
      v.usage++;
      _cache[key] = v;
    }
    return v;
  }

  free(ProgramContext pc) {
    pc.usage--;
    if (pc.usage <= 0) {
      pc.delete();
    }
  }
}

class _ProgramContextEntry {
  // following field can't be stored in ProgramContext to avoid usage on an
  // associative array ProgramContext -> RunOnProgramContext;
  // because a ProgramContext can be use in separated ProgramsRunner
  // for different context (opaque, transparent, ...)
  ProgramContext ctx;
  final _befores = new List<RunOnProgramContext>();
  final _ats = new List<RunOnProgramContext>();
}
class ProgramsRunner {
  final RenderingContext gl;
  final _ctxs = new List<_ProgramContextEntry>();
  final _setups = new List<RunOnRenderingContext>();
  final _beforeAlls = new List<RunOnRenderingContext>();
  final _beforeEachs = new List<RunOnProgramContext>();
  final _afterAlls =  new List<RunOnRenderingContext>();
  final _teardowns = new List<RunOnRenderingContext>();
  final _onAddProgramCtxs = new List<RunOnProgramContextRegistration>();
  final _onRemoveProgramCtxs = new List<RunOnProgramContextRegistration>();
  final _autoData = new Map<String, RunOnProgramContext>();
  final _atEachs = new List<RunOnProgramContext>();
  ProgramsRunner parent;

  ProgramsRunner(this.gl);
  get lg => _ctxs.length;

  register(RequestRunOn req) {
    if ((req.ctx != null) && (req.ctx.gl != gl)) throw new Exception("ProgramsRunner only accept request about same RenderingContext : req.ctx.gl != this.gl");

    if (req.setup != null) _setups.add(req.setup);

    if (req.beforeAll != null) _beforeAlls.add(req.beforeAll);
    if (req.afterAll != null) _afterAlls.add(req.afterAll);
    if (req.onAddProgramCtx != null) _onAddProgramCtxs.add(req.onAddProgramCtx);
    if (req.onRemoveProgramCtx != null) _onRemoveProgramCtxs.add(req.onRemoveProgramCtx);
    if (req.beforeEach != null) _beforeEachs.add(req.beforeEach);
    if (req.atEach != null) _atEachs.add(req.atEach);
    if (req.autoData != null) req.autoData.forEach((k, v){
      _autoData[k] = v;
    });

    if (req.ctx != null) {
      var e = _ctxs.firstWhere((x) => x.ctx ==req.ctx, orElse : () => null);
      var isNew = e == null;
      if (isNew) {
        e = new _ProgramContextEntry()..ctx = req.ctx;
        _ctxs.add(e);
      }
      if (req.before != null) e._befores.add(req.before);
      if (req.at != null) e._ats.add(req.at);
      if (isNew) {
        _onAddProgramCtxs.forEach((f)=> f(this, e.ctx));
      }
    } else {
      if (req.before != null) throw new Exception("try to register 'before' but no 'ctx' defined");
      if (req.at != null) throw new Exception("try to register 'at' but no 'ctx' defined");
    }
  }

  //TODO test if Function can be removed from list (equality)
  //TODO remove from _ctxs is no longer need the program (when removing the last at no at method)
  unregister(RequestRunOn req) {
    if (req.teardown != null) _teardowns.add(req.teardown);

    if (req.beforeAll != null) _beforeAlls.remove(req.beforeAll);
    if (req.afterAll != null) _afterAlls.remove(req.afterAll);
    if (req.onAddProgramCtx != null) _onAddProgramCtxs.remove(req.onAddProgramCtx);
    if (req.onRemoveProgramCtx != null) _onAddProgramCtxs.remove(req.onRemoveProgramCtx);
    if (req.beforeEach != null) _beforeEachs.remove(req.beforeEach);
    if (req.atEach != null) _atEachs.remove(req.atEach);
    if (req.autoData != null) req.autoData.keys.forEach((k){
      var v = _autoData.remove(k);
    });

    if (req.ctx != null) {
      var e = _ctxs.firstWhere((x) => x.ctx == req.ctx, orElse : () => null);
      if (e != null) {
        if (req.before != null) e._befores.remove(req.before);
        if (req.at != null) e._ats.remove(req.at);
        if (e._ats.length == 0 && e._befores.length == 0) {
          _onRemoveProgramCtxs.forEach((f)=> f(this, e.ctx));
          _ctxs.remove(e);
        }
      }
    }
  }

  _autoDataForEach(ctx) {
    if (parent != null) parent._autoDataForEach(ctx);
    _autoData.values.forEach((f) => f(ctx));
  }

  //TODO should be to most optimized call
  run() {
    _teardowns.forEach((f) => f(gl));
    _teardowns.clear();

    _setups.forEach((f) => f(gl));
    _setups.clear();

    //gl.bindFramebuffer(FRAMEBUFFER, null);
    _beforeAlls.forEach((f) => f(gl));

    _ctxs.forEach((e) {
      var ctx = e.ctx;
      //if (e._ats.length == 0) return;
      // useProgram is done out of draw to allow factorisation later
      ctx.gl.useProgram(ctx.program);
      _autoDataForEach(ctx);
      _beforeEachs.forEach((f) => f(ctx));
      e._befores.forEach((f) => f(ctx));
      _atEachs.forEach((f) => f(ctx));
      e._ats.forEach((f) => f(ctx));
//      _atEachs.forEach((f){
//        _beforeEachs.forEach((f) => f(ctx));
////        ctx.gl.useProgram(ctx.program);
//        ctx._befores.forEach((f) => f(ctx));
//        f(ctx);
//      });
//      ctx._ats.forEach((f){
////        ctx.gl.useProgram(ctx.program);
//        _beforeEachs.forEach((f) => f(ctx));
//        ctx._befores.forEach((f) => f(ctx));
//        f(ctx);
//      });
      ctx.disableAllAttrib();
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
  RunOnProgramContext beforeEach = null;
  RunOnProgramContext before = null;
  Map<String, RunOnProgramContext> autoData = null;
  RunOnProgramContext atEach = null;
  RunOnProgramContext at = null;
  RunOnRenderingContext teardown = null;
  RunOnRenderingContext afterAll = null;
  RunOnProgramContextRegistration onAddProgramCtx = null;
  RunOnProgramContextRegistration onRemoveProgramCtx = null;

  RequestRunOn();
  RequestRunOn.copy(RequestRunOn src) {
    ctx = src.ctx;
    setup = src.setup;
    beforeAll = src.beforeAll;
    before = src.before;
    autoData = src.autoData;
    at = src.at;
    teardown = src.teardown;
    afterAll = src.afterAll;
    onAddProgramCtx = src.onAddProgramCtx;
    onRemoveProgramCtx = src.onRemoveProgramCtx;
  }
}

class FBO {
  final RenderingContext gl;

  get buffer => _buf;
  get texture => _tex;
  get width => _width;
  get height => _height;

  Framebuffer _buf;
  Renderbuffer _renderBuf;
  Texture _tex;
  int _width = -1;
  int _height = -1;

  FBO(this.gl);

  make({int width : -1, int height : -1, int type : UNSIGNED_BYTE, hasDepthBuff: true}) {
    dispose();
    if (width < 0) width = gl.canvas.width;
    if (height < 0) height = gl.canvas.height;

    _buf = gl.createFramebuffer();
    gl.bindFramebuffer(FRAMEBUFFER, _buf);

    _tex = gl.createTexture();
    gl.bindTexture(TEXTURE_2D, _tex);
    gl.texImage2DTyped(TEXTURE_2D, 0, RGBA, width, height, 0, RGBA, type, null);
    gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_S, CLAMP_TO_EDGE);
    gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_T, CLAMP_TO_EDGE);
    gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
    gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
    //gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR);
    //gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR_MIPMAP_NEAREST);
    //gl.generateMipmap(TEXTURE_2D);
    gl.framebufferTexture2D(FRAMEBUFFER, COLOR_ATTACHMENT0, TEXTURE_2D, _tex, 0);

    if (hasDepthBuff) {
      _renderBuf = gl.createRenderbuffer();
      gl.bindRenderbuffer(RENDERBUFFER, _renderBuf);
      gl.renderbufferStorage(RENDERBUFFER, DEPTH_COMPONENT16, width, height);
      gl.framebufferRenderbuffer(FRAMEBUFFER, DEPTH_ATTACHMENT, RENDERBUFFER, _renderBuf);
    }

    gl.bindTexture(TEXTURE_2D, null);
    gl.bindRenderbuffer(RENDERBUFFER, null);
    gl.bindFramebuffer(FRAMEBUFFER, null);
    _width = width;
    _height = height;
  }

  dispose() {
    if (_renderBuf != null) {
      gl.deleteRenderbuffer(_renderBuf);
      _renderBuf = null;
    }
    if (_tex != null) {
      gl.deleteTexture(_tex);
      _tex = null;
    }
    if (_buf == null) {
      gl.deleteFramebuffer(_buf);
      _buf = null;
    }
    _width = -1;
    _height = -1;
  }
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
