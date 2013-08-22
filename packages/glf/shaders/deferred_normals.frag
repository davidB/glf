/// This fragment shader outputs normals to a floating point texture map
precision highp float;

varying vec3 vNormal;

void main(){
  gl_FragColor.rgb = normalize(vNormal);
  //TODO store depth into a
  gl_FragColor.a = 1.0;
}