precision highp float;

const vec2 ma = vec2(0.5,0.5);

attribute vec3 _Vertex;
//attribute vec3 _Normal;
//attribute vec2 _TexCoord0;

uniform mat4 _ProjectionViewMatrix;
uniform mat4 _ModelMatrix;
//uniform mat3 _NormalMatrix;

varying vec4 vColor;
//varying vec2 vTexCoord0;
//varying vec3 vNormal;
//varying vec4 vVertex;

void main(void) {
  vec4 v = _ModelMatrix * vec4(_Vertex, 1.0);
//  vVertex = v;
//  vNormal = _NormalMatrix * _Normal;
//  vTexCoord0 = _TexCoord0 * ma + ma;
  
  gl_Position = _ProjectionViewMatrix * v;
}