part of glf;

class Filter2D {
  static const VERT_SRC_2D =
"""
const vec2 ma = vec2(0.5,0.5);
attribute vec2 ${SFNAME_TEXCOORDS}0;
varying vec2 vTexCoord0;
 
void main(void) {
  gl_Position = vec4(${SFNAME_TEXCOORDS}0, 0.0, 1.0);
  vTexCoord0 = ${SFNAME_TEXCOORDS}0 * ma + ma;
}
""";

  final ProgramContext ctx;
  RunOnProgramContext cfg;

  Filter2D(gl, String fragSrcFilter, [RunOnProgramContext this.cfg]) : ctx = new ProgramContext(gl, VERT_SRC_2D, fragSrcFilter);

  Filter2D.copy(Filter2D o): ctx = o.ctx, cfg = o.cfg;
}

class FullScreenRectangle {
  final _coordSFName = SFNAME_TEXCOORDS + "0";
  var _coordBuffer;
  var gl;

  init(gl){
    this.gl = gl;
    _coordBuffer = gl.createBuffer();
    gl.bindBuffer(ARRAY_BUFFER, _coordBuffer);
    gl.bufferDataTyped(ARRAY_BUFFER,
      new Float32List.fromList([
        -1.0, -1.0,
         1.0, -1.0,
        -1.0,  1.0,
        -1.0,  1.0,
         1.0, -1.0,
         1.0,  1.0
      ]),
      STATIC_DRAW
    );
  }

  injectAndDraw(ctx) {
    var location = ctx.getAttribLocation(_coordSFName);
    //var gl = ctx.gl;
    gl.bindBuffer(ARRAY_BUFFER, _coordBuffer);
    gl.enableVertexAttribArray(location);
    gl.vertexAttribPointer(location, 2, FLOAT, false, 0, 0);
    gl.drawArrays(TRIANGLES, 0, 6);
  }

  delete() {
    gl.deleteBuffer(_coordBuffer);
  }
}

class Filter2DRunner {


  final RenderingContext gl;
  final List<Filter2D> filters = new List<Filter2D>();
  Texture texInit;
  final _fbo0;
  final _fbo1;
  FBO _fboTarget = null;
  ViewportPlan plan;
  FullScreenRectangle rectangle;

  Filter2DRunner(gl, ViewportPlan this.plan): this.gl = gl, _fbo0 = new FBO(gl), _fbo1 = new FBO(gl) {
    rectangle = new FullScreenRectangle();
    rectangle.init(gl);
  }

  Filter2DRunner.intoFBO(gl, this._fboTarget): this.gl = gl, _fbo0 = new FBO(gl), _fbo1 = new FBO(gl) {
    plan = new ViewportPlan()
    ..viewWidth = _fboTarget.width
    ..viewHeight = _fboTarget.height
    ;
    rectangle = new FullScreenRectangle();
    rectangle.init(gl);
  }

  run() {
    if (filters.length == 0) return;
    plan.setup(gl);
    if (plan.viewWidth != _fbo0.width || plan.viewHeight != _fbo0.height) {
      _fbo0.make(width: plan.viewWidth, height: plan.viewHeight, hasDepthBuff: false);
      _fbo1.make(width: plan.viewWidth, height: plan.viewHeight, hasDepthBuff: false);
    }
    var dest = _fbo0;
    var tex0 = texInit;
    //gl.disable(BLEND);
    //gl.disable(DEPTH_TEST);
    for(var i = 0; i < filters.length; ++i){
      if (i > 0) {
        tex0 = (dest == _fbo0) ? _fbo1.texture : _fbo0.texture;
      }
      if (i == filters.length - 1) {
        var b = (_fboTarget != null) ? _fboTarget.buffer : null;
        gl.bindFramebuffer(FRAMEBUFFER, b);
      } else {
        gl.bindFramebuffer(FRAMEBUFFER, dest.buffer);
        dest = (dest == _fbo0) ? _fbo1 : _fbo0;
      }
      var f = filters[i];
      if (f == null) {
        print("f is null for i : ${i} / ${filters.length}");
      }
      var ctx = f.ctx;
      var cfg = f.cfg;
      ctx.use();
      plan.injectUniforms(ctx);
      //if (ctx._ats.length == 1 && ctx._ats[0] != null) ctx._ats[0](ctx);
      if (cfg != null) cfg(ctx);

      injectTexture(ctx, tex0, 0);
      rectangle.injectAndDraw(ctx);
    }
    gl.bindFramebuffer(FRAMEBUFFER, null);
  }

  dispose() {
    _fbo0.dispose();
    _fbo1.dispose();
//    filters.forEach((x){
//      x.ctx.delete();
//    });
    filters.clear();
  }
}
