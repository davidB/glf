// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
part of glf;

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
}

class MeshDefTools {
  // cache temporary variable to avoid alloc/destroy
  var _v00 = new Vector3.zero();
  var _v01 = new Vector3.zero();
  var _v02 = new Vector3.zero();
  var _v03 = new Vector3.zero();
  var _v04 = new Vector3.zero();
  var _v10 = new Vector3.zero();
  var _v11 = new Vector3.zero();

  findNormal(Vector3 out, Float32List vertices, int p0, int p1, int p2) {
    _v00.setValues(vertices[p0 * 3 + 0], vertices[p0 * 3 + 1], vertices[p0 * 3 + 2]);
    _v01.setValues(vertices[p1 * 3 + 0], vertices[p1 * 3 + 1], vertices[p1 * 3 + 2]).sub(_v00);
    _v02.setValues(vertices[p2 * 3 + 0], vertices[p2 * 3 + 1], vertices[p2 * 3 + 2]).sub(_v00);
    _v01.crossInto(_v02, out);
    out.normalize();
    return out;
  }

  findCenter(Vector3 out, Float32List vertices) {
    out.setZero();
    for(var i = 0; i < vertices.length; i+=3 ){
      out.x += vertices[i + 0];
      out.y += vertices[i + 1];
      out.z += vertices[i + 2];
    }
    out.scale(3.0/vertices.length);
    return out;
  }

  isClockwise(Float32List vertices, Float32List normals, Uint16List triangles) {
    Vector3 n = _v10;
    Vector3 center = findCenter(_v11, vertices);
    Vector3 navg = _v00;
    var out = true;
    for(var i = 0; i < triangles.length; i += 3) {
      var i0 = triangles[i + 0];
      var i1 = triangles[i + 1];
      var i2 = triangles[i + 2];
      findNormal(n, vertices, i0, i1, i2);
      navg.setValues(
          normals[i0 * 3 + 0] + normals[i1 * 3 + 0] + normals[i2 * 3 + 0],
          normals[i0 * 3 + 1] + normals[i1 * 3 + 1] + normals[i2 * 3 + 1],
          normals[i0 * 3 + 2] + normals[i1 * 3 + 2] + normals[i2 * 3 + 2]
      ).normalize();
      var dir = navg.dot(n);
      if (dir <= 0) print("wrong triangle at ${i} : ${navg} ${n}");
      _v01.setValues(vertices[i0 * 3], vertices[i0 * 3 + 1], vertices[i0 * 3 + 2]).sub(center);
      if (navg.dot(_v01) < 0) print("wrong normal (look center) at ${i} : ${navg} ${n}");
      out = out && (dir > 0);
    }
    return out;
  }

  // Fill [out] with basic tessellation of a convex polygon of [nbpoints] sorted.
  // The tessellation algo is very basic : every triangles start from the point 0 + [pointsOffset]
  // return the next [trianglesOffset]
  tessellation0(Uint16List out, int nbpoints, int trianglesOffset, int pointsOffset) {
    for(var t = 0; t < (nbpoints - 2); t++) {
      var i = (trianglesOffset + t) * 3;
      out[i + 0] = pointsOffset;
      out[i + 1] = pointsOffset + t + 1;
      out[i + 2] = pointsOffset + t + 2;
    }
    return trianglesOffset + (nbpoints - 2);
  }

  /// 1 normal / face
  /// 3 doubles / vertex
  /// 3 doubles / normal
  /// nb normal == nb vertices
  /// 3 int / triangle
  /// 3 face / point => 3 vertices / point
  /// 2 triangles / side face
  /// (nbpoints - 2) triangle / bottom face
  /// (nbpoints - 2) triangle / top face
  MeshDef makeExtrude(Float32List vertices, Vector3 extrusion) {
    var nbpoints = vertices.length ~/ 3;
    if (nbpoints < 3) return null; //TODO throw an exception or return a valid MeshDef
    var out = new MeshDef()
    ..normals = new Float32List(nbpoints * 2 * 3 * 3) //points * 2 due to extrusion * 3 normals faces * 3d
    ..vertices = new Float32List(nbpoints * 2 * 3 * 3)
    ..triangles = new Uint16List((nbpoints * 2 + (nbpoints - 2) * 2) * 3)
    ;
    return extrudeInto(vertices, extrusion, out);
  }

  MeshDef extrudeInto(Float32List vertices, Vector3 extrusion, MeshDef out) {
    var nbpoints = vertices.length ~/ 3;
    var trianglesOffset = 0;
    // normal of the source face (defined by vertices)
    var n = _v10;
    findNormal(n, vertices, 0, 1, 2);
    var isCCW = n.dot(extrusion) >= 0;
    if (isCCW) {
      n.scale(-1.0); // normal is opposite of extrusion
    }
    // make bottom face (from input vertices)
    for(var p = 0; p < nbpoints; p++ ){
      var i = p * 3;
      var i0 = p * 3;
      out.vertices[i + 0] = vertices[i0 + 0];
      out.vertices[i + 1] = vertices[i0 + 1];
      out.vertices[i + 2] = vertices[i0 + 2];
      out.normals[i + 0] = n.x;
      out.normals[i + 1] = n.y;
      out.normals[i + 2] = n.z;
    }
    trianglesOffset = tessellation0(out.triangles, nbpoints, trianglesOffset, 0);
    // make top face (input + extrusion)
    for(var p = 0; p < nbpoints; p++ ){
      var i = (p + nbpoints) * 3;
      var i0 = p * 3;
      out.vertices[i + 0] = vertices[i0 + 0] + extrusion.x;
      out.vertices[i + 1] = vertices[i0 + 1] + extrusion.y;
      out.vertices[i + 2] = vertices[i0 + 2] + extrusion.z;
      out.normals[i + 0] = -n.x;
      out.normals[i + 1] = -n.y;
      out.normals[i + 2] = -n.z;
    }
    trianglesOffset = tessellation0(out.triangles, nbpoints, trianglesOffset, nbpoints);
    // make side faces
    var center = findCenter(_v11, vertices);

    for(var f = 0; f < nbpoints; f++ ){
      var p0 = (nbpoints * 2) + (f * 4);
      var pv0 = p0 * 3;
      var pv1 = pv0 + 3;
      var pv2 = pv1 + 3;
      var pv3 = pv2 + 3;
      var v0 = (f + 0) * 3;
      var v1 = ((f + 1) % nbpoints) * 3;
      out.vertices[pv0 + 0] = vertices[v0 + 0];
      out.vertices[pv0 + 1] = vertices[v0 + 1];
      out.vertices[pv0 + 2] = vertices[v0 + 2];
      out.vertices[pv1 + 0] = vertices[v0 + 0] + extrusion.x;
      out.vertices[pv1 + 1] = vertices[v0 + 1] + extrusion.y;
      out.vertices[pv1 + 2] = vertices[v0 + 2] + extrusion.z;
      out.vertices[pv2 + 0] = vertices[v1 + 0] + extrusion.x;
      out.vertices[pv2 + 1] = vertices[v1 + 1] + extrusion.y;
      out.vertices[pv2 + 2] = vertices[v1 + 2] + extrusion.z;
      out.vertices[pv3 + 0] = vertices[v1 + 0];
      out.vertices[pv3 + 1] = vertices[v1 + 1];
      out.vertices[pv3 + 2] = vertices[v1 + 2];
      findNormal(n, out.vertices, p0 + 0, p0 + 1, p0 +2);
      // normal should be in opposite to p0 -> center
      _v00.setValues(out.vertices[p0 + 0], out.vertices[p0 + 1], out.vertices[p0 + 2]).sub(center);
      if (_v00.dot(n) >= 0) n.scale(-1.0);

      for(var pi = p0; pi < p0 + 4; pi++) {
        out.normals[pi * 3 + 0] = n.x;
        out.normals[pi * 3 + 1] = n.y;
        out.normals[pi * 3 + 2] = n.z;
      }
      trianglesOffset = tessellation0(out.triangles, 4, trianglesOffset, p0);
    }
    return out;
  }

  // merge [o2] into [o1]
  // return [o1]
  merge(MeshDef o1, MeshDef o2) {
    var vertices2 = _mergeBuffer(o1.vertices, o2.vertices);
    var normals2 = _mergeBuffer(o1.normals, o2.normals);
    var texCoords2 = _mergeBuffer(o1.texCoords, o2.texCoords);
    var colors2 = _mergeBuffer(o1.colors, o2.colors);
    var triangles2 = _mergeIndices(o1.triangles, o2.triangles, o1.vertices.length ~/ 3);
    var lines2 = _mergeIndices(o1.lines, o2.lines, o1.vertices.length ~/ 3);
    // no exception so apply
    o1.vertices = vertices2;
    o1.normals = normals2;
    o1.texCoords = texCoords2;
    o1.colors = colors2;
    o1.triangles = triangles2;
    o1.lines = lines2;
    return o1;
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

  /// Apply transform [m] to [o1.vertices] and [o1.normals]
  transform(MeshDef o1, Matrix4 m) {
    var v3 = new Vector3.zero();
    for (var i = 0; i < o1.vertices.length; i += 3) {
      v3.x = o1.vertices[i + 0];
      v3.y = o1.vertices[i + 1];
      v3.z = o1.vertices[i + 2];
      m.transform3(v3);
      o1.vertices[i + 0] = v3.x;
      o1.vertices[i + 1] = v3.y;
      o1.vertices[i + 2] = v3.z;
    }
    var nm = new Matrix3.zero();
    makeNormalMatrix(m, nm);
    for (var i = 0; i < o1.normals.length; i += 3) {
      v3.x = o1.normals[i + 0];
      v3.y = o1.normals[i + 1];
      v3.z = o1.normals[i + 2];
      nm.transform(v3);
      o1.normals[i + 0] = v3.x;
      o1.normals[i + 1] = v3.y;
      o1.normals[i + 2] = v3.z;
    }
    return o1;
  }

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

  makePlane({double dx : 0.5, double dy : 0.5}) {
    return new MeshDef()
    ..vertices = new Float32List.fromList([
      -dx, -dy, 0.0,
       dx, -dy, 0.0,
       dx,  dy, 0.0,
      -dx,  dy, 0.0,
    ])
    ..normals = new Float32List.fromList([
      0.0,  0.0, 1.0,
      0.0,  0.0, 1.0,
      0.0,  0.0, 1.0,
      0.0,  0.0, 1.0,
    ])
    ..triangles = new Uint16List.fromList([
     // Also in groups of threes to define the three points of each triangle
     //The numbers here are the index numbers in the vertex array
      2, 0, 1,
      0, 2, 3
    ])
    ..texCoords = new Float32List.fromList([
      //This array is in groups of two, the x and y coordinates (a.k.a U,V) in the texture
      //The numbers go from 0.0 to 1.0, One pair for each vertex
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0
    ])
    ;

  }

  makeBox8Vertices({double dx : 0.5, double dy : 0.5, double dz : 0.5}) {
  return new MeshDef()
    ..vertices = new Float32List.fromList([
      //Front
      -dx, -dy,   dz,
       dx, -dy,   dz,
       dx,  dy,   dz,
      -dx,  dy,   dz,
      //Back
      -dx, -dy,  -dz,
       dx, -dy,  -dz,
       dx,  dy,  -dz,
      -dx,  dy,  -dz,
    ])
    ..normals = new Float32List.fromList([
      //Front
      -0.33, -0.33,  0.33,
       0.33, -0.33,  0.33,
       0.33,  0.33,  0.33,
      -0.33,  0.33,  0.33,
      //Back
      -0.33, -0.33,  -0.33,
       0.33, -0.33,  -0.33,
       0.33,  0.33,  -0.33,
      -0.33,  0.33,  -0.33,
    ])
    ..triangles = new Uint16List.fromList([
      // Also in groups of threes to define the three points of each triangle
      //The numbers here are the index numbers in the vertex array

      //Front
      0, 2, 3,
      2, 0, 1,
      //Back
      6, 4, 7,
      4, 6, 5,
      //Right
      6, 1, 5,
      1, 6, 2,
      //Left
      0, 7, 4,
      7, 0, 3,
      //Top
      3, 2, 6,
      3, 6, 7,
      //Bottom
      5, 1, 0,
      5, 0, 4
    ])
    ..texCoords = new Float32List.fromList([
      //This array is in groups of two, the x and y coordinates (a.k.a U,V) in the texture
      //The numbers go from 0.0 to 1.0, One pair for each vertex

      //Front
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
      //Back
      1.0, 0.0,
      0.0, 0.0,
      0.0, 1.0,
      1.0, 1.0,
    ])
    ;
  }

  makeBox24Vertices({double dx : 0.5, double dy : 0.5, double dz : 0.5, double tx : 1.0, double ty : 1.0, double tz : 1.0}) {
    return new MeshDef()
      ..vertices = new Float32List.fromList([
        // Front face
        -dx, -dy,  dz,
         dx, -dy,  dz,
         dx,  dy,  dz,
        -dx,  dy,  dz,
        // Back
        -dx, -dy, -dz,
        -dx,  dy, -dz,
         dx,  dy, -dz,
         dx, -dy, -dz,
        // Top
        -dx,  dy, -dz,
        -dx,  dy,  dz,
         dx,  dy,  dz,
         dx,  dy, -dz,
        // Bottom
        -dx, -dy, -dz,
         dx, -dy, -dz,
         dx, -dy,  dz,
        -dx, -dy,  dz,
        // Right
         dx, -dy, -dz,
         dx,  dy, -dz,
         dx,  dy,  dz,
         dx, -dy,  dz,
        // Left
        -dx, -dy, -dz,
        -dx, -dy,  dz,
        -dx,  dy,  dz,
        -dx,  dy, -dz
      ])
      ..normals = new Float32List.fromList([
         // Front face
         0.0,  0.0,  1.0,
         0.0,  0.0,  1.0,
         0.0,  0.0,  1.0,
         0.0,  0.0,  1.0,

         // Back face
         0.0,  0.0, -1.0,
         0.0,  0.0, -1.0,
         0.0,  0.0, -1.0,
         0.0,  0.0, -1.0,

         // Top face
         0.0,  1.0,  0.0,
         0.0,  1.0,  0.0,
         0.0,  1.0,  0.0,
         0.0,  1.0,  0.0,

         // Bottom face
         0.0, -1.0,  0.0,
         0.0, -1.0,  0.0,
         0.0, -1.0,  0.0,
         0.0, -1.0,  0.0,

         // Right face
         1.0,  0.0,  0.0,
         1.0,  0.0,  0.0,
         1.0,  0.0,  0.0,
         1.0,  0.0,  0.0,

         // Left face
         -1.0,  0.0,  0.0,
         -1.0,  0.0,  0.0,
         -1.0,  0.0,  0.0,
         -1.0,  0.0,  0.0,
      ])
      ..triangles = new Uint16List.fromList([
        0, 1, 2,      0, 2, 3,    // Front face
        4, 5, 6,      4, 6, 7,    // Back face
        8, 9, 10,     8, 10, 11,  // Top face
        12, 13, 14,   12, 14, 15, // Bottom face
        16, 17, 18,   16, 18, 19, // Right face
        20, 21, 22,   20, 22, 23  // Left face
      ])
      ..texCoords = new Float32List.fromList([
         // Front face
         0.0, 0.0,
          tx, 0.0,
          tx,  ty,
         0.0,  ty,

         // Back face
          tx, 0.0,
          tx,  ty,
         0.0,  ty,
         0.0, 0.0,

         // Top face
         0.0,  tz,
         0.0, 0.0,
          tx, 0.0,
          tx,  tz,

         // Bottom face
          tx,  tz,
         0.0,  tz,
         0.0, 0.0,
          tx, 0.0,

         // Right face
          tz, 0.0,
          tz,  ty,
         0.0,  ty,
         0.0, 0.0,

         // Left face
         0.0, 0.0,
          tz, 0.0,
          tz,  ty,
         0.0,  ty,
      ])
    ;
  }

  /// Creates sphere vertices.
  /// The created sphere has position, normal and uv streams.
  ///
  /// * [radius] of the sphere.
  /// * [subdivisionsAxis] number of steps around the sphere.
  /// * [subdivisionsHeight] number of vertically on the sphere.
  /// * [startLatitudeInRadians] where to start the top of the sphere.
  /// * [endLatitudeInRadians] where to end the bottom of the sphere.
  /// * [startLongitudeInRadians] where to start wrapping the sphere.
  /// * [endLongitudeInRadians] where to end wrapping the sphere.
  ///
  /// adapt from [tdl](https://github.com/greggman/tdl/blob/master/tdl/primitives.js)
  makeSphere({
      double radius : 1.0,
      int subdivisionsAxis : 6,
      int subdivisionsHeight : 6,
      double startLatitudeInRadians : 0.0,
      double endLatitudeInRadians : math.PI,
      double startLongitudeInRadians : 0.0,
      double endLongitudeInRadians : 2 * math.PI
      }) {
    if (subdivisionsAxis <= 0 || subdivisionsHeight <= 0) {
      throw new Exception('subdivisionAxis and subdivisionHeight must be > 0');
    }

    var latRange = endLatitudeInRadians - startLatitudeInRadians;
    var longRange = endLongitudeInRadians - startLongitudeInRadians;

    // We are going to generate our sphere by iterating through its
    // spherical coordinates and generating 2 triangles for each quad on a
    // ring of the sphere.
    var numVertices = (subdivisionsAxis + 1) * (subdivisionsHeight + 1);
    var positions = new Float32List(3 * numVertices);
    var normals = new Float32List(3 * numVertices);
    var texCoords = new Float32List(2 * numVertices);

    // Generate the individual vertices in our vertex buffer
    for (var i = 0, y = 0; y <= subdivisionsHeight; y++) {
      for (var x = 0; x <= subdivisionsAxis; x++) {
        // Generate a vertex based on its spherical coordinates
        var u = x / subdivisionsAxis;
        var v = y / subdivisionsHeight;
        var theta = longRange * u;
        var phi = latRange * v;
        var sinTheta = math.sin(theta);
        var cosTheta = math.cos(theta);
        var sinPhi = math.sin(phi);
        var cosPhi = math.cos(phi);
        var ux = cosTheta * sinPhi;
        var uy = cosPhi;
        var uz = sinTheta * sinPhi;
        positions[i * 3 + 0] = radius * ux;
        positions[i * 3 + 1] = radius * uy;
        positions[i * 3 + 2] = radius * uz;
        normals[i * 3 + 0] = ux;
        normals[i * 3 + 1] = uy;
        normals[i * 3 + 2] = uz;
        texCoords[i * 2 + 0] = 1 - u;
        texCoords[i * 2 + 1] = v;
        i++;
      }
    }

    var numVertsAround = subdivisionsAxis + 1;
    var indices = new Uint16List(3 * subdivisionsAxis * subdivisionsHeight * 2);
    for (var i = 0, x = 0; x < subdivisionsAxis; x++) {
      for (var y = 0; y < subdivisionsHeight; y++) {
        // Make triangle 1 of quad.
        indices[i++] = (y + 0) * numVertsAround + x;
        indices[i++] = (y + 0) * numVertsAround + x + 1;
        indices[i++] = (y + 1) * numVertsAround + x;

        // Make triangle 2 of quad.
        indices[i++] = (y + 1) * numVertsAround + x;
        indices[i++] = (y + 0) * numVertsAround + x + 1;
        indices[i++] = (y + 1) * numVertsAround + x + 1;
      }
    }

    return new MeshDef()
      ..vertices = positions
      ..normals = normals
      ..texCoords = texCoords
      ..triangles = indices
      ;
  }
}