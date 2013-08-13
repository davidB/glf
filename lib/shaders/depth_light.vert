uniform mat4 _ProjectionViewMatrix;
uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

attribute vec3 _Vertex;
varying vec4 vVertex;

attribute vec3 _Normal;
varying vec3 vNormal;

void main(){
  vVertex = _ModelMatrix * vec4(_Vertex, 1.0);
  vNormal = _NormalMatrix * _Normal;
  gl_Position = _ProjectionViewMatrix * vVertex;
}