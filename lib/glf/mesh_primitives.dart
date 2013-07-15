// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)
part of glf;

// MeshDef for primitives geometries

makeMeshDef_plane({double dx : 0.5, double dy : 0.5}) {
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
    0, 1, 2,
    2, 0, 3
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

makeMeshDef_cube8Vertices({double dx : 0.5, double dy : 0.5, double dz : 0.5}) {
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
    0, 1, 2,
    2, 0, 3,
    //Back
    4, 5, 6,
    6, 4, 7,
    //Right
    1, 2, 6,
    6, 1, 5,
    //Left
    0, 3, 7,
    7, 0, 4,
    //Top
    3, 2, 6,
    6, 3, 7,
    //Bottom
    0, 1, 5,
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

makeMeshDef_cube24Vertices({double dx : 0.5, double dy : 0.5, double dz : 0.5, double tx : 1.0, double ty : 1.0, double tz : 1.0}) {
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
makeMeshDef_sphere({
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