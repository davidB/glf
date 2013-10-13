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

injectTexture(ProgramContext ctx, Texture texture, [int textureSlot = 0, String sfname]) {
  if (sfname == null) sfname = "_Tex${textureSlot}";
  var uloc = ctx.getUniformLocation(sfname);
  if (uloc == null) return;
  //Set slot 0 as the active Texture
  ctx.gl.activeTexture(TEXTURE0 + textureSlot);
  //Load in the Texture To Memory
  ctx.gl.bindTexture(TEXTURE_2D, texture);
  //Update The Texture Sampler in the fragment shader to use slot textureIdx
  ctx.gl.uniform1i(uloc, textureSlot);
}