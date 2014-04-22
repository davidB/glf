// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

part of glf;

class CameraInfo {
  /// used by Perpective projection
  double aspectRatio,_fovRadians;
  ///DO NOT MODIFIED directly, direct access is provided to avoid copy for read
  double tanHalfFov;

  set fovRadians(double v) {
    _fovRadians = v;
    tanHalfFov = math.tan(v * 0.5);
  }
  /// used by Perpective AND Orthographic projection
  double near,far;
  /// used by Orthographic projection
  double left, right, bottom, top;

  bool isOrthographic = false;

  final position = new Vector3(0.0, 0.0, 1.0);
  final focusPosition = new Vector3(0.0, 0.0, 0.0);
  final upDirection = new Vector3(0.0, 1.0, 0.0);

  ///DO NOT MODIFIED directly, direct access is provided to avoid copy for read
  final projectionMatrix = new Matrix4.zero();
  ///DO NOT MODIFIED directly, direct access is provided to avoid copy for read
  final viewMatrix = new Matrix4.identity();
  ///DO NOT MODIFIED directly, direct access is provided to avoid copy for read
  final rotMatrix = new Matrix3.identity();
  ///DO NOT MODIFIED directly, direct access is provided to avoid copy for read
  final projectionViewMatrix = new Matrix4.zero();

  updateProjectionMatrix() {
    if (isOrthographic) {
      setOrthographicMatrix(projectionMatrix, left, right, bottom, top, near, far);
    } else {
      setPerspectiveMatrix(projectionMatrix, _fovRadians, aspectRatio, near, far); // from vector_math
    }
    updateProjectionViewMatrix();
  }

  updateViewMatrix() {
    setViewMatrix(viewMatrix, position, focusPosition, upDirection);
    //_viewMatrix.getRotation()
    rotMatrix.storage[0] = viewMatrix.storage[0];
    rotMatrix.storage[1] = viewMatrix.storage[1];
    rotMatrix.storage[2] = viewMatrix.storage[2];
    rotMatrix.storage[3] = viewMatrix.storage[4];
    rotMatrix.storage[4] = viewMatrix.storage[5];
    rotMatrix.storage[5] = viewMatrix.storage[6];
    rotMatrix.storage[6] = viewMatrix.storage[8];
    rotMatrix.storage[7] = viewMatrix.storage[9];
    rotMatrix.storage[8] = viewMatrix.storage[10];
    updateProjectionViewMatrix();
  }

  updateProjectionViewMatrix() {
    projectionMatrix.copyInto(projectionViewMatrix);
    projectionViewMatrix.multiply(viewMatrix);
  }

  adjustNearFar(Aabb3 aabb, double nearMin, double farMin) {
    var v2 = new Vector2(nearMin, farMin);
    var axis = (focusPosition - position).normalized();
    var pts = aabbToPoints(aabb);
    //extractMinMaxProjection(pts, axis, position,v20);
    //extractMinMaxDistance(pts, position, v21);
    extractMinMaxDistanceAndProjection(pts, axis, position, v2);
    far = v2.y;
    near = math.max(nearMin, v2.x);
  }
}

aabbToPoints(Aabb3 aabb) {
  var b = new List<Vector3>(8);
  b[0] = new Vector3(aabb.min.x, aabb.min.y, aabb.min.z);
  b[1] = new Vector3(aabb.min.x, aabb.min.y, aabb.max.z);
  b[2] = new Vector3(aabb.min.x, aabb.max.y, aabb.min.z);
  b[3] = new Vector3(aabb.max.x, aabb.min.y, aabb.min.z);
  b[4] = new Vector3(aabb.max.x, aabb.max.y, aabb.max.z);
  b[5] = new Vector3(aabb.max.x, aabb.max.y, aabb.min.z);
  b[6] = new Vector3(aabb.max.x, aabb.min.y, aabb.max.z);
  b[7] = new Vector3(aabb.min.x, aabb.max.y, aabb.max.z);
  return b;
}
//extractMinMaxProjection(List<Vector3> vs, Vector3 axis, Vector3 origin, Vector2 out) {
//  var tmp = new Vector3.zero();
//  tmp.setFrom(vs[0]).sub(origin);
//  var p = tmp.dot(axis);
//  out.x = p;
//  out.y = p;
//  for (int i = 1; i < vs.length; i++) {
//    tmp.setFrom(vs[i]).sub(origin);
//    p = tmp.dot(axis);
//    if (p < out.x) out.x = p;
//    if (p > out.y) out.y = p;
//  }
//}
//extractMinMaxDistance(List<Vector3> vs, Vector3 origin, Vector2 out) {
//  var tmp = new Vector3.zero();
//  tmp.setFrom(vs[0]).sub(origin);
//  var p = tmp.length;
//  out.x = p;
//  out.y = p;
//  for (int i = 1; i < vs.length; i++) {
//    tmp.setFrom(vs[i]).sub(origin);
//    p = tmp.length;
//    if (p < out.x) out.x = p;
//    if (p > out.y) out.y = p;
//  }
//}

extractMinMaxDistanceAndProjection(List<Vector3> vs, Vector3 axis, Vector3 origin, Vector2 out) {
  var tmp = new Vector3.zero();
  for (int i = 0; i < vs.length; i++) {
    tmp.setFrom(vs[i]).sub(origin);
    var p = tmp.dot(axis);
    if (p < out.x) out.x = p;
    //if (p > out.y) out.y = p;
    var pl = tmp.length; //( pl is always >= p)
    //if (pl < out.x) out.x = pl;
    if (pl > out.y) out.y = pl;
  }
}
class ViewportCamera {
  int x = 0;
  int y = 0;
  int viewWidth;
  int viewHeight;

  var sfname_projectionmatrix = SFNAME_PROJECTIONMATRIX;
  var sfname_viewmatrix = SFNAME_VIEWMATRIX;
  var sfname_rotmatrix = SFNAME_ROTATIONMATRIX;
  var sfname_projectionviewmatrix = SFNAME_PROJECTIONVIEWMATRIX;
  var sfname_near = SFNAME_NEAR;
  var sfname_far = SFNAME_FAR;
  var sfname_viewposition = SFNAME_VIEWPOSITION;
  var sfname_viewup = SFNAME_VIEWUP;
  var sfname_focusposition = SFNAME_FOCUSPOSITION;

  final camera = new CameraInfo();


  //final _projectionInvMatrix = new Matrix4.zero();

  // default constructor;
  ViewportCamera();

  factory ViewportCamera.defaultSettings(CanvasElement canvas) {
    var b = new ViewportCamera()
    ..camera.fovRadians = degrees2radians * 45.0
    ..camera.near = 1.0
    ..camera.far = 100.0
    ..fullCanvas(canvas)
    ..registerOnResizeCanvas(canvas)
    ;
    return b;
  }

  setup(RenderingContext gl) {
    // Basic viewport setup and clearing of the screen
    gl.viewport(x, y, viewWidth, viewHeight);
    camera.updateProjectionMatrix();
    camera.updateViewMatrix();
  }

  injectUniforms(ProgramContext ctx) {
    injectMatrix4(ctx, camera.projectionMatrix, sfname_projectionmatrix);
    injectMatrix4(ctx, camera.viewMatrix, sfname_viewmatrix);
    injectMatrix3(ctx, camera.rotMatrix, sfname_rotmatrix);
    injectMatrix4(ctx, camera.projectionViewMatrix, sfname_projectionviewmatrix);
    ctx.gl.uniform1f(ctx.getUniformLocation(sfname_near), camera.near);
    ctx.gl.uniform1f(ctx.getUniformLocation(sfname_far), camera.far);
    ctx.gl.uniform3fv(ctx.getUniformLocation(sfname_viewposition), camera.position.storage);
    ctx.gl.uniform3fv(ctx.getUniformLocation(sfname_viewup), camera.upDirection.storage);
    ctx.gl.uniform3fv(ctx.getUniformLocation(sfname_focusposition), camera.focusPosition.storage);
  }

  makeRequestRunOn() => new RequestRunOn()
    ..setup = setup
    ..beforeEach = injectUniforms
  ;


  fullCanvas(CanvasElement canvas) {
    var dpr = window.devicePixelRatio;     // retina
    //var dpr = 1;
    var w = (dpr * canvas.clientWidth).round();//parseInt(canvas.style.width);
    var h = (dpr * canvas.clientHeight).round(); //parseInt(canvas.style.height);
    //HACK to avoid set to 0
    if (w == 0 || h == 0) {
      viewWidth = canvas.width;
      viewHeight = canvas.height;
    } else {
      viewWidth = w;
      viewHeight = h;
      canvas.width = viewWidth;
      canvas.height = viewHeight;
    }
    x = 0;
    y = 0;
    camera
    ..left = x.toDouble()
    ..right = x.toDouble() + canvas.width.toDouble()
    ..top = y.toDouble()
    ..bottom = y.toDouble() + viewHeight.toDouble()
    ..isOrthographic = false
    ..aspectRatio = viewWidth.toDouble() / viewHeight.toDouble()
    ..updateProjectionMatrix()
    ;
  }

  registerOnResizeCanvas(CanvasElement canvas) {
    var onResize = (evt){
      fullCanvas(canvas);
    };
    //return Window.resizeEvent.forTarget(canvas).listen(onResize);
    return canvas.onResize.listen(onResize);
  }
}

class ViewportPlan {
  int x = 0;
  int y = 0;
  int viewWidth;
  int viewHeight;
  ///DO NOT MODIFIED directly, direct access is provided to avoid copy for read
  Vector3 pixelSize = new Vector3.zero();

  // default constructor;
  ViewportPlan();

  factory ViewportPlan.defaultSettings(CanvasElement canvas) {
    var b = new ViewportPlan()
    ..fullCanvas(canvas)
    ..registerOnResizeCanvas(canvas)
    ;
    return b;
  }

  setup(RenderingContext gl) {
    // Basic viewport setup and clearing of the screen
    gl.viewport(x, y, viewWidth, viewHeight);
    pixelSize.x = 1.0 / viewWidth.toDouble();
    pixelSize.y = 1.0 / viewHeight.toDouble();
    pixelSize.z = viewWidth.toDouble() / viewHeight.toDouble();
  }

  injectUniforms(ProgramContext ctx) {
    ctx.gl.uniform3fv(ctx.getUniformLocation(SFNAME_PIXELSIZE), pixelSize.storage);
    //print("$pixelSize");
    //ctx.gl.uniform1fv(ctx.getUniformLocation(SFNAME_PIXELSIZE), pixelSize.storage);
  }

  makeRequestRunOn() => new RequestRunOn()
  ..setup = setup
  ..beforeEach = injectUniforms
  ;

  fullCanvas(CanvasElement canvas) {
    var dpr = window.devicePixelRatio;     // retina
    //var dpr = 1;
    viewWidth = (dpr * canvas.clientWidth).round();//parseInt(canvas.style.width);
    viewHeight = (dpr * canvas.clientHeight).round(); //parseInt(canvas.style.height);
    x = 0;
    y = 0;
    canvas.width = viewWidth;
    canvas.height = viewHeight;
  }

  registerOnResizeCanvas(CanvasElement canvas) {
    var onResize = (evt){
      fullCanvas(canvas);
    };
    return canvas.onResize.listen(onResize);
  }
}