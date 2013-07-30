// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

part of glf;

class CameraInfo {
  double aspectRatio;
  double fovRadians;
  double near;
  double far;

  final position = new Vector3(0.0, 0.0, 1.0);
  final focusPosition = new Vector3(0.0, 0.0, 0.0);
  final upDirection = new Vector3(0.0, 1.0, 0.0);

  final _projectionMatrix = new Matrix4.zero();
  final _viewMatrix = new Matrix4.identity();
  final _rotMatrix = new Matrix3.identity();
  final _projectionViewMatrix = new Matrix4.zero();

  updateProjectionMatrix() {
    setPerspectiveMatrix(_projectionMatrix, fovRadians, aspectRatio, near, far); // from vector_math
    updateProjectionViewMatrix();
  }

  updateViewMatrix() {
    setViewMatrix(_viewMatrix, position, focusPosition, upDirection);
    //_viewMatrix.getRotation()
    _rotMatrix.storage[0] = _viewMatrix.storage[0];
    _rotMatrix.storage[1] = _viewMatrix.storage[1];
    _rotMatrix.storage[2] = _viewMatrix.storage[2];
    _rotMatrix.storage[3] = _viewMatrix.storage[4];
    _rotMatrix.storage[4] = _viewMatrix.storage[5];
    _rotMatrix.storage[5] = _viewMatrix.storage[6];
    _rotMatrix.storage[6] = _viewMatrix.storage[8];
    _rotMatrix.storage[7] = _viewMatrix.storage[9];
    _rotMatrix.storage[8] = _viewMatrix.storage[10];
    updateProjectionViewMatrix();
  }

  updateProjectionViewMatrix() {
    _projectionMatrix.copyInto(_projectionViewMatrix);
    _projectionViewMatrix.multiply(_viewMatrix);
  }

}

class Viewport {
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
  Viewport();

  factory Viewport.defaultSettings(CanvasElement canvas) {
    var b = new Viewport()
    ..camera.fovRadians = degrees2radians * 45.0
    ..camera.near = 1.0
    ..camera.far = 100.0
    ..fullCanvas(canvas)
    ..registerOnResizeCanvas(canvas)
    ;
    return b;
  }

  get autoData => new Map()
    ..[sfname_projectionmatrix] = _setUniformProjectionMatrix
    ..[sfname_viewmatrix] = _setUniformViewMatrix
    ..[sfname_rotmatrix] = _setUniformRotMatrix
    ..[sfname_projectionviewmatrix] = _setUniformProjectionViewMatrix
    ;

  _setup(RenderingContext gl) {
    // Basic viewport setup and clearing of the screen
    gl.viewport(x, y, viewWidth, viewHeight);
    camera.updateProjectionMatrix();
    camera.updateViewMatrix();
  }

  _setUniformProjectionMatrix(ProgramContext ctx) {
    injectMatrix4(ctx, camera._projectionMatrix, sfname_projectionmatrix);
  }

  _setUniformViewMatrix(ProgramContext ctx) {
    injectMatrix4(ctx, camera._viewMatrix, sfname_viewmatrix);
  }

  _setUniformRotMatrix(ProgramContext ctx) {
    injectMatrix3(ctx, camera._rotMatrix, sfname_rotmatrix);
  }

  _setUniformProjectionViewMatrix(ProgramContext ctx) {
    injectMatrix4(ctx, camera._projectionViewMatrix, sfname_projectionviewmatrix);
  }

  makeRequestRunOn() => new RequestRunOn()
    ..setup = _setup
//    ..beforeAll = ((gl) => autoScale(gl.canvas))
    ..autoData = autoData
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
    camera.aspectRatio = viewWidth.toDouble() / viewHeight.toDouble();
    camera.updateProjectionMatrix();
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


  // default constructor;
  ViewportPlan();

  factory ViewportPlan.defaultSettings(CanvasElement canvas) {
    var b = new Viewport()
    ..fullCanvas(canvas)
    ..registerOnResizeCanvas(canvas)
    ;
    return b;
  }

  _setup(RenderingContext gl) {
    // Basic viewport setup and clearing of the screen
    gl.viewport(x, y, viewWidth, viewHeight);
  }

  makeRequestRunOn() => new RequestRunOn()
    ..setup = _setup
//    ..beforeAll = ((gl) => autoScale(gl.canvas))
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