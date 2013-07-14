#ifdef GL_ES
precision highp float;
#endif

varying vec3 normal;

void main(void)
{
    gl_FragColor = vec4(normal.xy* 0.5 + 0.5,  normal.z* 0.4 + 0.6, 1.0);
}