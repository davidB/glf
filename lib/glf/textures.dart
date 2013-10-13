// License [CC0](http://creativecommons.org/publicdomain/zero/1.0/)

part of glf;

/// create a filled Texture.
/// The texture is 1 pixel of [color] (initialy).
/// If [imageUrl] is not null, then image is download (from [imageUrl])
/// and call [handle] to execute some GL code, by default store the image
/// into the texture (replace the 1 pixel color).
///
/// the [handle] function can be used:
/// * to notify when image is load (don't forgot to update the texture),
///   eg if you don't wish to display until the texture are filled with image
/// * to store the image with other code than [storeColorToTexture] (as default)
///
Texture createTexture(RenderingContext gl, Uint8List color, [Uri imageUrl, handle(RenderingContext, Texture, ImageElement) = storeImageToTexture]) {
  var tex = gl.createTexture();
  //storeColorToTexture seems to break the flow under dart2js but doest throw exception
  //tex = storeColorToTexture(gl, tex, color);
  if (imageUrl != null) {
    loadImage(imageUrl).then((img){
      handle(gl, tex, img);
    });
  }
  return tex;
}

Future<ImageElement> loadImage(Uri url) {
  var completer = new Completer<ImageElement>();
  var element = new ImageElement();
  element.onLoad.listen((e) {
    completer.complete(element);
  });
  element.src = url.toString();
  return completer.future;
}

storeColorToTexture(RenderingContext gl, Texture tex, Uint8List color) {
  gl.bindTexture(TEXTURE_2D, tex);
  switch(color.length) {
    case 3 :
      gl.texImage2DTyped(TEXTURE_2D, 0, RGB, 1, 1, 0, RGB, UNSIGNED_BYTE, color);
      break;
    case 4 :
      gl.texImage2DTyped(TEXTURE_2D, 0, RGBA, 1, 1, 0, RGBA, UNSIGNED_BYTE, color);
      break;
    default:
      throw new Exception("Uint8List color should be 3 int for RGB or 4 int for RGBA : color.length = ${color.length}");
  }
  gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
  gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
  //Unbind the texture and return it.
  gl.bindTexture(TEXTURE_2D, null);
  //TODO check for error
  //print("storeColorToTexture ${tex != null} 3");
  return tex;
}

storeImageToTexture(RenderingContext gl, Texture tex, ImageElement ele) {
  gl.bindTexture(TEXTURE_2D, tex);

  //Flip Positive Y (Optional)
  gl.pixelStorei(UNPACK_FLIP_Y_WEBGL, 1);

  //Load in The Image
  gl.texImage2DImage(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, ele);

  //Setup Scaling properties
  gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR);
  gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR_MIPMAP_NEAREST);
  gl.generateMipmap(TEXTURE_2D);

  //Unbind the texture and return it.
  gl.bindTexture(TEXTURE_2D, null);
  return tex;
}

injectTexture(ProgramContext ctx, Texture texture, [int textureUnit = 0, String sfname]) {
  if (sfname == null) sfname = "_Tex${textureUnit}";
  var uloc = ctx.getUniformLocation(sfname);
  if (uloc == null) return;
  //Set slot 0 as the active Texture
  ctx.gl.activeTexture(TEXTURE0 + textureUnit);
  //Load in the Texture To Memory
  ctx.gl.bindTexture(TEXTURE_2D, texture);
  //Update The Texture Sampler in the fragment shader to use slot textureIdx
  ctx.gl.uniform1i(uloc, textureUnit);
}

class TextureUnitCache {
  final RenderingContext gl;
  int _max;
  int _lastFind = 0; //use as a timestamp for a LRU
  Map<Texture, _TextureUnitCacheEntry> _cache;
  
  TextureUnitCache(this.gl) {
    _max = math.max(32, gl.getParameter(MAX_TEXTURE_IMAGE_UNITS));
    _cache = new Map<Texture, _TextureUnitCacheEntry>();
  }
  
  inject(ProgramContext ctx, Texture texture, String sfname) {
    var uloc = ctx.getUniformLocation(sfname);
    if (uloc == null){
      return -1;
    }
    var textureUnit = _find(texture);
    //Update The Texture Sampler in the fragment shader to use slot textureIdx
    ctx.gl.uniform1i(uloc, textureUnit);
    return textureUnit;
  }
  
  _find(Texture texture) {
    _lastFind++;
    var e = _cache[texture];
    if (e == null) {
      if (_cache.length >= _max) {
        var oldest = _findOldest();
        _cache.remove(oldest.texture);
        oldest.texture = texture;
        _cache[texture] = oldest;
      } else {
        e = new _TextureUnitCacheEntry()
        ..unit = _findUnusedUnit()
        ..texture = texture
        ;
        _cache[texture] = e;
      }
    }
    //Set slot 0 as the active Texture
    gl.activeTexture(TEXTURE0 + e.unit);
    //Load in the Texture To Memory
    gl.bindTexture(TEXTURE_2D, e.texture);
    e.lastFind = _lastFind;
    return e.unit;  
  }

  _findOldest() {
    return _cache.values.fold(null, (acc, e){
      return (acc == null) ? e : (acc.lastFind < e.lastFind) ? acc : e;
    });
  }

  _findUnusedUnit() {
    var freeset = _cache.values.fold(0, (acc, e){
      return acc | (1 << e.unit);
    });
    for (var i = 0; i < _max; ++i) {
      if ((freeset & (1 << i)) == 0) return i;  
    }
    return -1;
  }

  delete(Texture texture) {
    _cache.remove(texture);
    gl.deleteTexture(texture);
  }
}
class _TextureUnitCacheEntry {
  Texture texture;
  int unit;
  int lastFind;
}