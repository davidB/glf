precision highp float;

varying vec3 vNormal;

void main(void) {
  vec3 normal = normalize(vNormal);
  gl_FragColor = vec4(normal.xy* 0.5 + 0.5,  normal.z* 0.4 + 0.6, 1.0);
}