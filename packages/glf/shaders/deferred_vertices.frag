/// This fragment shader outputs vertex data to a floating point texture map

precision highp float;

uniform float _Near;
uniform float _Far;

varying vec4 vVertex;

void main(){
  // Calculate and include linear depth
  //float linearDepth = length(vPosition) / LinearDepth;
  gl_FragColor.rgb = vVertex.xyz;
  gl_FragColor.a = (length(vVertex.xyz) - _Near) / (_Far - _Near);
  //gl_FragColor.a = (vVertex.z - _Near) / (_Far - _Near);
}