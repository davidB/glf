library meshdef_test;

import 'dart:typed_data';
import 'package:unittest/unittest.dart';
import 'package:vector_math/vector_math.dart';
import 'package:glf/glf.dart' as glf;

//import '../lib/vdrones.dart';

main() {
  var sut = new glf.MeshDefTools();
  test("meshDefTools extract 3d box from 2d box CW", () {
    var vertices = new Float32List.fromList([
     -1.0, 1.0, 0.0,
      1.0, 1.0, 0.0,
      1.0,-1.0, 0.0,
     -1.0,-1.0, 0.0
    ]);
    var extrusion = new Vector3(0.0, 0.0, 1.0);
    var md = sut.makeExtrude(vertices, extrusion);
    expect(md.vertices.length, equals(4 * 6 * 3));
    expect(md.normals.length, equals(md.vertices.length));
    expect(md.triangles.length, equals(6 * 2 * 3));
    expect(md.normals[0 * 3 + 2], equals(-1.0));
    expect(md.normals[4 * 3 + 2], equals(1.0));
    expect(md.normals[8 * 3 + 0], equals(0.0));
    expect(md.normals[8 * 3 + 1], equals(1.0));
    expect(md.normals[8 * 3 + 2], equals(0.0));
    for(var i = 0; i < md.triangles.length; i++) {
      expect(md.triangles[i], greaterThanOrEqualTo(0));
      expect(md.triangles[i], lessThan(md.vertices.length ~/ 3));
    }
  });
  test("meshDefTools extract 3d box from 2d box CCW", () {
    var vertices = new Float32List.fromList([
     -1.0, 1.0, 0.0,
     -1.0,-1.0, 0.0,
      1.0,-1.0, 0.0,
      1.0, 1.0, 0.0
    ]);
    var extrusion = new Vector3(0.0, 0.0, 1.0);
    var md = sut.makeExtrude(vertices, extrusion);
    expect(md.vertices.length, equals(4 * 6 * 3));
    expect(md.normals.length, equals(4 * 6 * 3));
    expect(md.triangles.length, equals(6 * 2 * 3));
    expect(md.normals[0 * 3 + 2], equals(-1.0));
    expect(md.normals[4 * 3 + 2], equals(1.0));
    expect(md.normals[8 * 3 + 0], equals(-1.0));
    expect(md.normals[8 * 3 + 1], equals(0.0));
    expect(md.normals[8 * 3 + 2], equals(0.0));
  });
  test("findNormal on axis", (){
    var out = new Vector3.zero();
    sut.findNormal(out, new Float32List.fromList(
      [
        0.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0
      ]),
      0, 1, 2
    );

    expect(out.storage, equals(new Vector3(0.0, 0.0, 1.0).storage));
  });
}


