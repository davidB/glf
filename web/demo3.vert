precision highp float;

/// Demo of NormalMap + MatCap
/// In fragment you can change the diffuseColor to use _MatCap0 or _MatCap1 or _MatCap2
#define NORMALMAP
  
attribute vec3 _Vertex;
attribute vec3 _Normal;
attribute vec2 _TexCoord0;
uniform vec4 _Color;

uniform mat4 _ProjectionViewMatrix;
uniform mat4 _ModelMatrix;
uniform mat3 _NormalMatrix;

varying vec4 vColor;
varying vec3 vNormal;
varying vec2 vTexCoord0;

#ifdef NORMALMAP
//attribute vec4 _Tangent;
varying vec3 mat;
#endif

vec3 approxTangent(vec3 normal){
  vec3 c1 = cross(normal, vec3(0.0, 0.0, 1.0));
  vec3 c2 = cross(normal, vec3(0.0, 1.0, 0.0));
  vec3 tangent = (length(c1)>length(c2)) ? c1 : c2;
  return normalize(tangent);
}

void main(void) {
  vColor = _Color;
  vTexCoord0 = _TexCoord0;
  vNormal = _NormalMatrix * _Normal;
  gl_Position = _ProjectionViewMatrix * _ModelMatrix * vec4(_Vertex, 1.0);

#ifdef NORMALMAP
  vec4 _Tangent = vec4 (approxTangent(vNormal), 1.0);
  vec3 n = normalize(vNormal);
  vec3 t = normalize(_NormalMatrix * _Tangent.xyz);
  vec3 b = cross(n, t) * -_Tangent.w;

  mat3 tbnMatrix = mat3(t, b, n);
  mat = vec3(1.0) * tbnMatrix;
  mat = normalize(mat);
#endif  
}