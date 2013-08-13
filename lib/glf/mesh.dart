// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
part of glf;

extractWireframe(Uint16List triangles) {
  Uint16List lines = new Uint16List(triangles.length * 2);
  for (var i = 0; i < triangles.length; i = i + 3) {
    for (var j = 0; j < 3; j++) {
      var a = triangles[i + j];
      var b = triangles[i + (j + 1) % 3];
      lines[(i + j) * 2] = a; //math.min(a, b));
      lines[(i + j) * 2 + 1] = b; //math.max(a, b));
    }
  }
  return lines;
}

extractNormals(MeshDef m) {
  MeshDef out = new MeshDef();
  if (m.normals == null || m.normals.length < 3) return out;

  var l = m.normals.length ~/3;
  out.vertices = new Float32List(l * 3 * 2);
  out.lines = new Uint16List(l * 2);
  for (var i = 0; i < l; i++) {
    var i2 = i * 2;
    var l3 = i * 3;
    var l6 = i * 6;
    out.vertices[l6 + 0] = m.vertices[l3 + 0];
    out.vertices[l6 + 1] = m.vertices[l3 + 1];
    out.vertices[l6 + 2] = m.vertices[l3 + 2];
    out.vertices[l6 + 3] = m.vertices[l3 + 0] + m.normals[l3 + 0];
    out.vertices[l6 + 4] = m.vertices[l3 + 1] + m.normals[l3 + 1];
    out.vertices[l6 + 5] = m.vertices[l3 + 2] + m.normals[l3 + 2];
    out.lines[i2 + 0] = i2;
    out.lines[i2 + 1] = i2 + 1;
  }
  return out;
}

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

class MeshDef {
  Float32List vertices;
  Float32List normals;
  Float32List texCoords;
  Float32List colors;
  Uint16List triangles;
  Uint16List lines;

  free() {
    vertices = null;
    normals = null;
    texCoords = null;
    colors = null;
    triangles = null;
    lines = null;
  }

  merge(MeshDef other) {
    var vertices2 = _mergeBuffer(this.vertices, other.vertices);
    var normals2 = _mergeBuffer(this.normals, other.normals);
    var texCoords2 = _mergeBuffer(this.texCoords, other.texCoords);
    var colors2 = _mergeBuffer(this.colors, other.colors);
    var triangles2 = _mergeIndices(this.triangles, other.triangles, this.vertices.length ~/ 3);
    var lines2 = _mergeIndices(this.lines, other.lines, this.vertices.length ~/ 3);
    // no exception so apply
    this.vertices = vertices2;
    this.normals = normals2;
    this.texCoords = texCoords2;
    this.colors = colors2;
    this.triangles = triangles2;
    this.lines = lines2;
    return this;
  }

  /// tranforms vertices and normals
  transform(Matrix4 m) {
    var v3 = new Vector3.zero();
    for (var i = 0; i < vertices.length; i += 3) {
      v3.x = vertices[i + 0];
      v3.y = vertices[i + 1];
      v3.z = vertices[i + 2];
      m.transform3(v3);
      vertices[i + 0] = v3.x;
      vertices[i + 1] = v3.y;
      vertices[i + 2] = v3.z;
    }
    var nm = new Matrix3.zero();
    makeNormalMatrix(m, nm);
    for (var i = 0; i < normals.length; i += 3) {
      v3.x = normals[i + 0];
      v3.y = normals[i + 1];
      v3.z = normals[i + 2];
      nm.transform(v3);
      normals[i + 0] = v3.x;
      normals[i + 1] = v3.y;
      normals[i + 2] = v3.z;
    }
    return this;
  }
}

_mergeBuffer(Float32List l1, Float32List l2) {
  if (l1 == null && l2 == null) return null;
  if (l1 == null) throw new Exception("to merge 2 Float32List, they must must both null or not null : list 1 is null");
  if (l2 == null) throw new Exception("to merge 2 Float32List, they must must both null or not null : list 2 is null");
  var b = new Float32List(l1.length + l2.length);
  b.setAll(0, l1);
  b.setAll(l1.length, l2);
  return b;
}

_mergeIndices(Uint16List l1, Uint16List l2, int l2offset) {
  if (l1 == null && l2 == null) return null;
  if (l1 == null) throw new Exception("to merge 2 Float32List, they must must both null or not null : list 1 is null");
  if (l2 == null) throw new Exception("to merge 2 Float32List, they must must both null or not null : list 2 is null");
  var b = new Uint16List(l1.length + l2.length);
  b.setAll(0, l1);
  for(var i = 0; i < l2.length; i++) {
    b[l1.length + i] = l2[i] + l2offset;
  }
  return b;
}

class Float32Buffer {
  String sname;
  int spacing = 3;
  Buffer buff = null;

  setData(RenderingContext gl, Float32List l) {
    if (buff != null) {
      gl.deleteBuffer(buff);
    }
    buff = gl.createBuffer();
    gl.bindBuffer(ARRAY_BUFFER, buff);
    gl.bufferDataTyped(ARRAY_BUFFER, l, STATIC_DRAW);
  }

  free(RenderingContext gl) {
    if (buff == null) buff = gl.createBuffer();
    gl.deleteBuffer(buff);
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
  int length = 0;

  setData(RenderingContext gl, Uint16List l) {
    if (buff != null) {
      gl.deleteBuffer(buff);
    }
    buff = gl.createBuffer();
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, buff);
    gl.bufferDataTyped(ELEMENT_ARRAY_BUFFER, l, STATIC_DRAW);
    length = l.length;
  }

  free(RenderingContext gl) {
    if (buff == null) buff = gl.createBuffer();
    gl.deleteBuffer(buff);
    buff = null;
  }

  drawElements(ProgramContext pc, int mode) {
    if (buff == null ) return;
    var gl = pc.gl;
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, buff);
    gl.drawElements(mode, length, UNSIGNED_SHORT, 0);
  }
}