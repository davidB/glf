library glf_asset_pack;

import 'dart:async';
import 'dart:html';
import 'dart:web_gl' as wgl;
import 'dart:typed_data';
import 'package:asset_pack/asset_pack.dart';
import 'glf.dart';


/// Register the glf loader with the asset_pack library.
/// asset manager. After calling this function, the asset manager
/// will be able to load :
/// * type 'shaderProgram' => ProgramContext
/// * type 'tex2d' => Texture
/// * type 'filter2d' => Filter2D
// TODO meshes, glTF
void registerGlfWithAssetManager(wgl.RenderingContext gl, AssetManager assetManager, {importImgToTexture(RenderingContext, Texture, ImageElement) : storeImageToTexture}) {
  //assetManager.loaders['mesh'] = new TextLoader();
  assetManager.loaders['tex2d'] = new ImageLoader();
  //assetManager.loaders['texCube'] = new _ImagePackLoader();
  //assetManager.loaders['vertexShader'] = new TextLoader();
  //assetManager.loaders['fragmentShader'] = new TextLoader();
  assetManager.loaders['filter2d'] = new TextLoader();
  assetManager.loaders['shaderProgram'] = new ProgramContextLoader();

  //assetManager.importers['mesh'] = new MeshImporter(graphicsDevice);
  assetManager.importers['tex2d'] = new Tex2DImporter(gl, importImgToTexture);
  //assetManager.importers['texCube'] = new TexCubeImporter(graphicsDevice);
  //assetManager.importers['vertexShader'] = new TextImporter();
  //assetManager.importers['fragmentShader'] = new TextImporter();
  assetManager.importers['filter2d'] = new Filter2DImporter(gl);
  assetManager.importers['shaderProgram'] = new ProgramContextImporter(gl);
}

final PatternVertAndFrag = new RegExp("""\{([A-Za-z_.0-9]*),([A-Za-z_.0-9]*)\}""");

List<String> extractVertAndFragUrl(String url) {
  String vertSuffix = '.vert';
  String fragSuffix = '.frag';
  var m = PatternVertAndFrag.firstMatch(url);
  if (m != null) {
   String from = m.group(0);
   String vertSuffix = m.group(1);
   String fragSuffix = m.group(2);
   return [url.replaceFirst(from, vertSuffix), url.replaceFirst(from, fragSuffix)];
  }
  return [url + vertSuffix, url + fragSuffix];
}
class ProgramContextLoader extends AssetLoader {
  Future<dynamic> load(Asset asset, AssetPackTrace tracer) {
    TextLoader loader = new TextLoader();
    var urls = extractVertAndFragUrl(asset.url);
    var vert = new Asset(asset.pack, asset.name, urls[0], 'vertexShader', loader, null, null, null);
    var frag = new Asset(asset.pack, asset.name, urls[1], 'fragmentShader', loader, null, null, null);
    return Future.wait([
      loader.load(vert, tracer),
      loader.load(frag, tracer)
    ]).then((l){
      if (l[0] == null || l[1] == null) return null;
      return l;
    });
  }

  void delete(dynamic arg) {
  }
}

class ProgramContextImporter extends AssetImporter {
  final wgl.RenderingContext gl;
  final _cache = new ProgramContextCache();

  ProgramContextImporter(this.gl);

  void initialize(Asset asset) {
    asset.imported = null;
  }

  Future<dynamic> import(dynamic payload, Asset asset, AssetPackTrace tracer) {
    if (payload is List && payload.length == 2) {
      String vertexShaderSource = payload[0];
      String fragmentShaderSource = payload[1];
      var b = _cache.find(gl, vertexShaderSource, fragmentShaderSource);
      asset.imported = b;
      return new Future.value(b);
    }
    return new Future.value(null);
  }

  void delete(ProgramContext imported) {
    if (imported == null) {
      return;
    }
    _cache.free(imported);
  }
}

class Tex2DImporter extends AssetImporter {
  final wgl.RenderingContext gl;
  final dynamic importImgToTexture;
  Tex2DImporter(this.gl, this.importImgToTexture(RenderingContext, Texture, ImageElement));

  void initialize(Asset asset) {
    var tex = gl.createTexture();
    //storeColorToTexture seems to break the flow under dart2js
    //tex = storeColorToTexture(gl, tex, new Uint8List.fromList([187, 187, 187, 255]));
    asset.imported = tex;
  }

  Future<dynamic> import(dynamic payload, Asset asset, AssetPackTrace tracer) {
    if (payload is ImageElement) {
      // workaround because initialize doesn't seems to be call via dart2js
      if (asset.imported == null) {
        asset.imported = gl.createTexture();
      }
      importImgToTexture(gl, asset.imported, payload);
      return new Future.value(asset.imported);
    }
    return new Future.value(asset.imported);
  }

  void delete(wgl.Texture imported) {
    if (imported == null) {
      return;
    }
    gl.deleteTexture(imported);
  }
}

class Filter2DImporter extends AssetImporter {
  final wgl.RenderingContext gl;
  Filter2DImporter(this.gl);

  void initialize(Asset asset) {
    asset.imported = null;
  }

  Future<dynamic> import(dynamic payload, Asset asset, AssetPackTrace tracer) {
    if (payload is String) {
      var b = new Filter2D(gl, payload);
      asset.imported = b;
      return new Future.value(b);
    }
    return new Future.value(null);
  }

  void delete(Filter2D imported) {
    if (imported == null) {
      return;
    }
    imported.ctx.delete();
  }
}

class BrightnessCtrl {
  double brightness = 0.0;
  double contrast = 0.0;
  double gamma = 2.2;
}

class Factory_Filter2D {
  static const c3_identity =         const[ 0.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 0.0000];
  static const c3_gaussianBlur =     const[ 0.0450, 0.1220, 0.0450, 0.1220, 0.3320, 0.1220, 0.0450, 0.1220, 0.0450];
  static const c3_gaussianBlur2 =    const[ 1.0000, 2.0000, 1.0000, 2.0000, 4.0000, 2.0000, 1.0000, 2.0000, 1.0000];
  static const c3_gaussianBlur3 =    const[ 0.0000, 1.0000, 0.0000, 1.0000, 1.0000, 1.0000, 0.0000, 1.0000, 0.0000];
  static const c3_unsharpen =        const[-1.0000,-1.0000,-1.0000,-1.0000, 9.0000,-1.0000,-1.0000,-1.0000,-1.0000];
  static const c3_sharpness =        const[ 0.0000,-1.0000, 0.0000,-1.0000, 5.0000,-1.0000, 0.0000,-1.0000, 0.0000];
  static const c3_sharpen =          const[-1.0000,-1.0000,-1.0000,-1.0000,16.0000,-1.0000,-1.0000,-1.0000,-1.0000];
  static const c3_edgeDetect =       const[-0.1250,-0.1250,-0.1250,-0.1250, 1.0000,-0.1250,-0.1250,-0.1250,-0.1250];
  static const c3_edgeDetect2 =      const[-1.0000,-1.0000,-1.0000,-1.0000, 8.0000,-1.0000,-1.0000,-1.0000,-1.0000];
  static const c3_edgeDetect3 =      const[-5.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 5.0000];
  static const c3_edgeDetect4 =      const[-1.0000,-1.0000,-1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 1.0000, 1.0000];
  static const c3_edgeDetect5 =      const[-1.0000,-1.0000,-1.0000, 2.0000, 2.0000, 2.0000,-1.0000,-1.0000,-1.0000];
  static const c3_edgeDetect6 =      const[-5.0000,-5.0000,-5.0000,-5.0000,39.0000,-5.0000,-5.0000,-5.0000,-5.0000];
  static const c3_sobelHorizontal =  const[ 1.0000, 2.0000, 1.0000, 0.0000, 0.0000, 0.0000,-1.0000,-2.0000,-1.0000];
  static const c3_sobelVertical =    const[ 1.0000, 0.0000,-1.0000, 2.0000, 0.0000,-2.0000, 1.0000, 0.0000,-1.0000];
  static const c3_previtHorizontal = const[ 1.0000, 1.0000, 1.0000, 0.0000, 0.0000, 0.0000,-1.0000,-1.0000,-1.0000];
  static const c3_previtVertical =   const[ 1.0000, 0.0000,-1.0000, 1.0000, 0.0000,-1.0000, 1.0000, 0.0000,-1.0000];
  static const c3_boxBlur =          const[ 0.1110, 0.1110, 0.1110, 0.1110, 0.1110, 0.1110, 0.1110, 0.1110, 0.1110];
  static const c3_triangleBlur =     const[ 0.0625, 0.1250, 0.0625, 0.1250, 0.2500, 0.1250, 0.0625, 0.1250, 0.0625];
  static const c3_emboss =           const[-2.0000,-1.0000, 0.0000,-1.0000, 1.0000, 1.0000, 0.0000, 1.0000, 2.0000];

  AssetManager am;

  init() {
    return Future.wait([
      am.loadAndRegisterAsset('filter2d_identity', 'filter2d', 'packages/glf/shaders/filters_2d/identity.frag', null, null),
      am.loadAndRegisterAsset('filter2d_brightness', 'filter2d', 'packages/glf/shaders/filters_2d/brightness.frag', null, null),
      am.loadAndRegisterAsset('filter2d_convolution3x3', 'filter2d', 'packages/glf/shaders/filters_2d/convolution3x3.frag', null, null),
      am.loadAndRegisterAsset('filter2d_x_waves', 'filter2d', 'packages/glf/shaders/filters_2d/x_waves.frag', null, null),
      am.loadAndRegisterAsset('filter2d_fxaa', 'filter2d', 'packages/glf/shaders/filters_2d/fxaa.frag', null, null),
    ]).then((l) => am);

    /* An alternative to AssetManager would be to use :
     * HttpRequest.request("packages/glf/shaders/filters_2d/convolution3x3.frag", method: 'GET').then((r) {
     *    var filter2d = new glf.Filter2D(gl, r.responseText);
     * });
     */
  }

  makeIdentity() {
    return am['filter2d_identity'];
  }

  makeFXAA() {
    return am['filter2d_fxaa'];
  }
  makeBrightness(BrightnessCtrl ctrl) {
    return new Filter2D.copy(am['filter2d_brightness'])
    ..cfg = (ctx) {
      ctx.gl.uniform1f(ctx.getUniformLocation('_Brightness'), ctrl.brightness);
      ctx.gl.uniform1f(ctx.getUniformLocation('_Contrast'), ctrl.contrast);
      ctx.gl.uniform1f(ctx.getUniformLocation('_InvGamma'), 1.0/ctrl.gamma);
    };
  }

  makeConvolution3(List<double> c3_matrix) {
    var kernel = new Float32List.fromList(c3_matrix);
    return new Filter2D.copy(am['filter2d_convolution3x3'])
    ..cfg = (ctx) => ctx.gl.uniform1fv(ctx.getUniformLocation('_Kernel[0]'), kernel)
    ;
  }

  makeXWaves(double offset()) {
    return new Filter2D.copy(am['filter2d_x_waves'])
    ..cfg = (ctx) => ctx.gl.uniform1f(ctx.getUniformLocation('_Offset'), offset())
    ;
  }

}
