attribute vec3 _Vertex;
attribute vec3 _Normal;

uniform mat4 _ProjectionViewMatrix;
uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

varying vec3 vNormal;
varying vec4 vVertex;

void main(void) {
  vNormal = _NormalMatrix * _Normal;
  vVertex = _ModelMatrix * vec4(_Vertex, 1.0);
  gl_Position = _ProjectionViewMatrix * vVertex, 1.0;
}