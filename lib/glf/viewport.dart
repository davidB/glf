// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

part of glf;

class CameraInfo {
  /// used by Perpective projection
  double aspectRatio,fovRadians;
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
      setPerspectiveMatrix(projectionMatrix, fovRadians, aspectRatio, near, far); // from vector_math
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
    ctx.gl.uniform1f(ctx.getUniformLocation("_Near"), camera.near);
    ctx.gl.uniform1f(ctx.getUniformLocation("_Far"), camera.far);
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
    camera
    ..left = x.toDouble()
    ..right = x.toDouble() + viewWidth.toDouble()
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
    return Window.resizeEvent.forTarget(canvas).listen(onResize);
  }
}

class ViewportPlan {
  int x = 0;
  int y = 0;
  int viewWidth;
  int viewHeight;
  ///DO NOT MODIFIED directly, direct access is provided to avoid copy for read
  Vector2 pixelSize = new Vector2.zero();

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
  }

  injectUniforms(ProgramContext ctx) {
    ctx.gl.uniform2f(ctx.getUniformLocation(SFNAME_PIXELSIZE), pixelSize.x, pixelSize.y);
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
    return Window.resizeEvent.forTarget(canvas).listen(onResize);
  }
}