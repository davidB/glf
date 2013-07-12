import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'dart:web_gl' as GL;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import '../lib/glf.dart' as glf;

main(){
  var gl = (query("#canvas0") as CanvasElement).getContext3d();
  if (gl == null) {
    print("webgl not supported");
    return;
  }
  var prunner = new glf.ProgramsRunner(gl);

  prunner.register(new glf.RequestRunOn()
    ..setup= (gl) {
      if (true) {
        // opaque
        gl.disable(GL.BLEND);
        gl.depthFunc(GL.LEQUAL);
        //gl.depthFunc(GL.LESS); // default value
        gl.enable(GL.DEPTH_TEST);
      } else {
        // blend
        gl.disable(GL.DEPTH_TEST);
        gl.blendFunc(GL.SRC_ALPHA, GL.ONE);
        gl.enable(GL.BLEND);
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
  );

  // Camera default setting for perspective use canvas area full
  var viewport = new glf.Viewport.defaultSettings(gl.canvas);
  prunner.register(viewport.makeRequestRunOn());

  // Create a cube geometry +  a texture + a transform + a shader program to display all
  // same parameter with other transforms can be reused to display several cubes
  var transforms = new Matrix4.identity();
  transforms.translate(0.0, 0.0, -6.0);
  //var md = glf.makeMeshDef_cube8Vertices(dx: 1.0, dy: 1.0, dz: 0.5);
  var md = glf.makeMeshDef_cube24Vertices(dx: 2.0, dy: 1.0, dz: 0.5, ty: 1.0);
  //var md = glf.makeMeshDef_sphere(subdivisionsAxis : 16, subdivisionsHeight : 16);
  //md.lines = glf.extractWireframe(md.triangles);
  //md.triangles = null;
  var md2 = glf.extractNormals(md);
  var vsUri = Uri.parse("./test_webgl.vert");
  var fsUri = Uri.parse("./test_webgl.frag");
//  var vsUri = Uri.parse("packages/glf/shaders/default.vert");
//  var fsUri = Uri.parse("packages/glf/shaders/default.frag");
  glf.loadProgramContext(gl, vsUri, fsUri).then((ctx){
    // keep ref to RequestRunOn to be able to register/unregister (show/hide)
    var req0Hidden = true;
    var req0 = null;
    var tex = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]), Uri.parse("_images/dirt.jpg"));
    //var tex = glf.createTexture(ctx.gl, new Uint8List.fromList([120, 120, 120, 255]));
    var texNormal = glf.createTexture(ctx.gl, new Uint8List.fromList([0, 0, 120]), Uri.parse("_images/shaders_offest_normalmap.jpg"));
    var mesh = new glf.Mesh()..setData(ctx.gl, md);
    req0 = new glf.RequestRunOn()
      ..ctx = ctx
      ..before = (glf.ProgramContext  ctx) {
        ctx.gl.uniform1i(ctx.getUniformLocation('useLights'), 1);
        ctx.gl.uniform3f(ctx.getUniformLocation(glf.SFNAME_COLORS), 0.5, 0.5, 0.5);
      }
      ..at = (ctx) {
        var normalMatrix = glf.makeNormalMatrix(transforms);
        glf.injectMatrix4(ctx, transforms, glf.SFNAME_MODELMATRIX);
        glf.injectMatrix3(ctx, normalMatrix, glf.SFNAME_NORMALMATRIX);
        glf.injectTexture(ctx, tex, 0);
        glf.injectTexture(ctx, texNormal, 1);
        // vertices of the mesh can be modified in update loop, so update the data to GPU
        //mesh.vertices.setData(ctx.gl, md.vertices);
        mesh.injectAndDraw(ctx);
      }
      ;
    var mesh2 = new glf.Mesh()..setData(ctx.gl, md2);
    var req2 = new glf.RequestRunOn()
      ..ctx = ctx
      ..before = (ctx) {
        ctx.gl.uniform1i(ctx.getUniformLocation('useLights'), 1);
      }
      ..at = (ctx) {
        var normalMatrix = glf.makeNormalMatrix(transforms);
        glf.injectMatrix4(ctx, transforms, glf.SFNAME_MODELMATRIX);
        glf.injectMatrix3(ctx, normalMatrix, glf.SFNAME_NORMALMATRIX);
        glf.injectTexture(ctx, tex, 0);
        glf.injectTexture(ctx, texNormal, 1);
        // vertices of the mesh can be modified in update loop, so update the data to GPU
        //mesh2.vertices.setData(ctx.gl, md2.vertices);
        mesh2.injectAndDraw(ctx);
      }
      ;
    //prunner.register(req2);

    var tprevious = 0;
    update(t){
      // rule to define if req0 is shown or hidden
      //var hidden = (t~/3000) % 2 == 1;
      var hidden = false;
      if (hidden && !req0Hidden && req0 != null) {
        prunner.unregister(req0);
        req0Hidden = true;
      } else if (!hidden && req0Hidden && req0 != null) {
        prunner.register(req0);
        req0Hidden = false;
      }

      // rule to modify transforms of the global mesh
      var dt = t - tprevious;
      tprevious = t;
      transforms.rotateY(20 * degrees2radians * dt/1000);
      // rule to modify one vertice of the mesh
      //md.vertices[0] = 4.0 * (t % 3000)/3000 - 2.0;

      // render (run shader's program)
      prunner.run();
      window.animationFrame.then(update);
    };
    window.animationFrame.then(update);
  });
}

