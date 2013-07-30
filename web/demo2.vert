varying vec3 normal;
varying vec4 position;

uniform mat4 _ProjectionMatrix, _ViewMatrix;
uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

attribute vec3 _Vertex, _Normal;

void main(){
  normal = _NormalMatrix * _Normal;
  position = _ModelMatrix * vec4(_Vertex, 1.0);
  gl_Position = _ProjectionMatrix * _ViewMatrix * position;
}