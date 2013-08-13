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
  ProgramContextImporter(this.gl);

  void initialize(Asset asset) {
    asset.imported = null;
  }

  Future<dynamic> import(dynamic payload, Asset asset, AssetPackTrace tracer) {
    if (payload is List && payload.length == 2) {
      String vertexShaderSource = payload[0];
      String fragmentShaderSource = payload[1];
      var b = new ProgramContext(gl, vertexShaderSource, fragmentShaderSource);
      asset.imported = b;
      return new Future.value(b);
    }
    return new Future.value(null);
  }

  void delete(ProgramContext imported) {
    if (imported == null) {
      return;
    }
    imported.delete();
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
    print("imported import ${asset.imported}");
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