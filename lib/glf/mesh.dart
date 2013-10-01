// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
part of glf;

class Mesh {
  final vertices = new Float32Buffer()
    ..sname = SFNAME_VERTICES
    ;
  final normals = new Float32Buffer()
    ..sname = SFNAME_NORMALS;
  final texCoords = new Float32Buffer()
    ..sname = SFNAME_TEXCOORDS + '0'
    ..spacing = 2
    ;
  final colors = new Float32Buffer()
    ..sname = SFNAME_COLORS
    ;
  final triangles = new Uint16Buffer_Element();
  final lines = new Uint16Buffer_Element();

  setData(RenderingContext gl, MeshDef md, [tryCheck = true]) {
    if (md.vertices != null){
      if (tryCheck) check(md);
      vertices.setData(gl, md.vertices);
    }
    if (md.normals != null){
      normals.setData(gl, md.normals);
    }
    if (md.texCoords != null){
      texCoords.setData(gl, md.texCoords);
    }
    if (md.colors != null){
      colors.setData(gl, md.colors);
    }
    if (md.triangles != null) triangles.setData(gl, md.triangles);
    if (md.lines != null) lines.setData(gl, md.lines);
  }
  check(MeshDef md) {
    var length = md.vertices.length / vertices.spacing;
    if (md.normals != null && length != md.normals.length / normals.spacing) throw new Exception("expecting ${normals.spacing * length} length for MeshDef.normals (${md.normals.length})");
    if (md.texCoords != null && length != md.texCoords.length / texCoords.spacing) throw new Exception("expecting ${texCoords.spacing * length} length for MeshDef.texCoords (${md.texCoords.length})");
    if (md.colors != null && length != md.colors.length / colors.spacing) throw new Exception("expecting ${colors.spacing * length} length for MeshDef.texCoords (${md.colors.length})");
    if (md.triangles != null) {
      for(var i = 0; i < md.triangles.length; i++) {
        if (md.triangles[i] < 0 || md.triangles[i] >= length) throw new Exception("expecting value of MeshDef.triangles to be in [0, ${length}[ triangles[${i}] = ${md.triangles[i]}");
      }
    }
    if (md.lines != null) {
      for(var i = 0; i < md.lines.length; i++) {
        if (md.lines[i] < 0 || md.lines[i] >= length) throw new Exception("expecting value of MeshDef.lines to be in [0, ${length}[ lines[${i}] = ${md.lines[i]}");
      }
    }
  }

  free(RenderingContext gl) {
    vertices.free(gl);
    normals.free(gl);
    texCoords.free(gl);
    colors.free(gl);
    triangles.free(gl);
    lines.free(gl);
  }

  inject(ProgramContext ctx) {
    normals.injectVertexAttribArray(ctx);
    texCoords.injectVertexAttribArray(ctx);
    colors.injectVertexAttribArray(ctx);
    vertices.injectVertexAttribArray(ctx);
  }

  draw(ProgramContext ctx, [int mode = TRIANGLES]) {
    triangles.drawElements(ctx, mode);
    lines.drawElements(ctx, LINES);
  }

}

class Float32Buffer {
  String sname;
  int spacing = 3;
  Buffer buff = null;
  int length = 0;

  setData(RenderingContext gl, Float32List l) {
    if (buff == null) {
      buff = gl.createBuffer();
      length = l.length;
    } else if (length != l.length) {
      gl.deleteBuffer(buff);
      buff = gl.createBuffer();
      length = l.length;
    }
    gl.bindBuffer(ARRAY_BUFFER, buff);
    gl.bufferDataTyped(ARRAY_BUFFER, l, STATIC_DRAW);
  }

  free(RenderingContext gl) {
    if (buff != null) gl.deleteBuffer(buff);
    buff = null;
  }

  injectVertexAttribArray(ProgramContext ctx) {
    if (buff == null ) return;
    var gl = ctx.gl;
    var location = ctx.getAttribLocation(sname);
    if (location == -1 ) return;
    gl.bindBuffer(ARRAY_BUFFER, buff);
    gl.enableVertexAttribArray(location);
    gl.vertexAttribPointer(location, spacing, FLOAT, false, 0, 0);
  }
}

class Uint16Buffer_Element {
  Buffer buff = null;
  int length = -1;

  setData(RenderingContext gl, Uint16List l) {
    if (buff == null) {
      buff = gl.createBuffer();
      length = l.length;
    } else if (length != l.length) {
      gl.deleteBuffer(buff);
      buff = gl.createBuffer();
      length = l.length;
    }
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, buff);
    gl.bufferDataTyped(ELEMENT_ARRAY_BUFFER, l, STATIC_DRAW);
  }

  free(RenderingContext gl) {
    if (buff != null) gl.deleteBuffer(buff);
    buff = null;
  }

  drawElements(ProgramContext pc, int mode) {
    if (buff == null ) return;
    var gl = pc.gl;
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, buff);
    gl.drawElements(mode, length, UNSIGNED_SHORT, 0);
  }
}