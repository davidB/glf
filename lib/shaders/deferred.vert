/// This vertex shader prepares the geometry for rendering to a floating point texture map.
precision highp float;

uniform mat4 _ProjectionMatrix;
uniform mat4 _ViewMatrix;
uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

attribute vec3 _Vertex;
attribute vec3 _Normal;

varying vec4 vVertex;
varying vec3 vNormal;

void main(void) {
  vNormal = _NormalMatrix * _Normal;
  vVertex = _ViewMatrix * _ModelMatrix * vec4(_Vertex, 1.0);
  gl_Position = _ProjectionMatrix * vVertex;
}