attribute vec3 _Vertex;
attribute vec3 _Normal;
//attribute vec2 _TexCoord0;
uniform vec3 _Color;

uniform mat4 _ProjectionViewMatrix;
uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

varying vec4 vColor;
varying vec3 vNormal;

void main(void) {
  vColor = vec4(_Color, 1.0);
  vNormal = _NormalMatrix * _Normal;
  gl_Position = _ProjectionViewMatrix * _ModelMatrix * vec4(_Vertex, 1.0);
}