The directory used to store some shaders (original or adaptation from lot of place).

Source of shaders are used as is (no header, no uniform, ... append by the library):
* some info about [precision](http://my.opera.com/emoller/blog/2011/10/18/all-hail-ios-5)
* common precision append by other lib, frameworks :
  ```
  #ifdef GL_ES
  precision highp float;
  #endif
  ```

# Some source of shaders :

## for postprocessing or 2D filter:

* [GLSL Image Processing](http://r3dux.org/2011/06/glsl-image-processing/) with code
* see [glfx](https://github.com/evanw/glfx.js)

## for 3D :

* [jme-glsl-shaders](http://code.google.com/p/jme-glsl-shaders/), source, video, ...
* [Shaders](http://wiki.unity3d.com/index.php/Shaders) from Unity community
* shader's of [webglu](https://github.com/OneGeek/WebGLU/tree/master/shaders)
* [example of lightgl.js](https://github.com/evanw/lightgl.js/tree/master/tests)
* [example of glow](https://github.com/empaempa/GLOW/tree/master/examples/shaders)
* shield :
  * [shield force](http://irrlicht.sourceforge.net/forum/viewtopic.php?t=38544) for irrlicht
  * [rim light](http://mtheorygame.com/tag/rim-light/)
* blog :
  * [CIS565: Project 5: Advanced GLSL](https://github.com/ashima07/Project5-AdvancedGLSL)
  * [CIS 565 Final Project - WebGL Path Tracer](http://pixelated.webgl.ashimag.com/p/blogs.html)
* [devmaster](http://devmaster.net/)
* [nutty software](http://www.nutty.ca/?cat=11) ssao, glow,
* [Experiments with Perlin noise](http://www.clicktorelease.com/blog/experiments-with-perlin-noise) explosion, chrome, light

## for NPR :

Some [Non-Photorealistic Rendering](http://en.wikipedia.org/wiki/Non-photorealistic_rendering) (aka npr), include  Cartoon/toon Shading, Pencil Shading, Ink Shading, Cell Shading :

* [Toon pixel shader](http://coding-experiments.blogspot.fr/2011/01/toon-pixel-shader.html) by Agnius Vasiliauskas
* [NPR GLSL Tutorials](http://stackoverflow.com/questions/2727821/npr-glsl-tutorials) on StackOverflow
* gl demos of [Non-Photorealistic Rendering](http://www.bonzaisoftware.com/gldemos/non-photorealistic-rendering/) by BonzaiSoftware
* blog of "The Little Grasshopper" [old](http://prideout.net/blog/) [new](http://github.prideout.net/)
* ala Team Fortress 2
  * [description](http://www.valvesoftware.com/publications/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf) from Valve Software
  * [article by Eric Kurzmack ](http://www.sfdm.scad.edu/faculty/mkesson/vsfx419/wip/spring11/eric_kurzmack/toon.html)
  * [TeamFortress2Shader](http://wiki.unity3d.com/index.php/TeamFortress2Shader) from unity community

## for Texture

* [MatCap library](http://pixologic.com/zbrush/downloadcenter/library/) from zbrush for the texture

# Info

## online tools :

* [GLSL Sandbox](http://glsl.heroku.com/)
* Shadertoy

## Misc:

* transparency : [depth-peeling](http://www.khronos.org/message_boards/showthread.php/8228-Details-about-handling-transparency-with-depth-peeling)
* books :
  * [ShaderX](http://tog.acm.org/resources/shaderx/)
  * [GPU Pro](http://gpupro.blogspot.fr/)
* [Real-Time Rendering Portal](http://www.realtimerendering.com/portal.html)
* experiment of Daniel Wustenhoff [Shaders and Special effects](http://www.danielwustenhoff.com/?page_id=179)