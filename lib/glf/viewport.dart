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
  final _projectionViewMatrix = new Matrix4.zero();

  updateProjectionMatrix() {
    setPerspectiveMatrix(_projectionMatrix, fovRadians, aspectRatio, near, far); // from vector_math
    updateProjectionViewMatrix();
  }

  updateViewMatrix() {
    setViewMatrix(_viewMatrix, position, focusPosition, upDirection);
    updateProjectionViewMatrix();
  }

  updateProjectionViewMatrix() {
    _projectionMatrix.copyInto(_projectionViewMatrix);
    _projectionViewMatrix.multiply(_viewMatrix);
  }

}

class Viewport {
  int x;
  int y;
  int viewWidth;
  int viewHeight;

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

  _setup(RenderingContext gl) {
    // Basic viewport setup and clearing of the screen
    gl.viewport(x, y, viewWidth, viewHeight);
    camera.updateProjectionMatrix();
    camera.updateViewMatrix();
  }

  _autoRegisterOnProgram(ProgramsRunner pr, ProgramContext p) {
    if (p.getUniformLocation(SFNAME_PROJECTIONMATRIX) != null) {
      pr.register(new RequestRunOn()
        ..ctx = p
        ..before = _setUniformProjectionMatrix
      );
    }
    if (p.getUniformLocation(SFNAME_VIEWMATRIX) != null) {
      pr.register(new RequestRunOn()
        ..ctx = p
        ..before = _setUniformViewMatrix
      );
    }
    if (p.getUniformLocation(SFNAME_PROJECTIONVIEWMATRIX) != null) {
      pr.register(new RequestRunOn()
        ..ctx = p
        ..before = _setUniformProjectionViewMatrix
      );
    }
  }

  _setUniformProjectionMatrix(ProgramContext ctx) {
    injectMatrix4(ctx, camera._projectionMatrix, SFNAME_PROJECTIONMATRIX);
  }

  _setUniformViewMatrix(ProgramContext ctx) {
    injectMatrix4(ctx, camera._viewMatrix, SFNAME_VIEWMATRIX);
  }

  _setUniformProjectionViewMatrix(ProgramContext ctx) {
    injectMatrix4(ctx, camera._projectionViewMatrix, SFNAME_PROJECTIONVIEWMATRIX);
  }

  makeRequestRunOn() => new RequestRunOn()
    ..setup = _setup
//    ..beforeAll = ((gl) => autoScale(gl.canvas))
    ..onAddProgramCtx = _autoRegisterOnProgram
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