precision mediump float;

uniform mat4 _ProjectionMatrix, _ViewMatrix;
uniform mat4 _ModelMatrix;

attribute vec3 _Vertex;

attribute vec2 _TexCoord0;
varying vec2 vTexCoord0;

void main(){
  vec4 vVertex = _ModelMatrix * vec4(_Vertex, 1.0);
  vTexCoord0 = _TexCoord0;
  gl_Position = _ProjectionMatrix * _ViewMatrix * vVertex;
}

