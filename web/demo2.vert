precision mediump float;

uniform mat4 _ProjectionMatrix, _ViewMatrix;
uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

attribute vec3 _Vertex;
varying vec4 vVertex;

attribute vec3 _Normal;
varying vec3 vNormal;

attribute vec2 _TexCoord0;
varying vec2 vTexCoord0;

void main(){
  vVertex = _ModelMatrix * vec4(_Vertex, 1.0);
  vNormal = _NormalMatrix * _Normal;
  vTexCoord0 = _TexCoord0;
  gl_Position = _ProjectionMatrix * _ViewMatrix * vVertex;
}
