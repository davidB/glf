  attribute vec3 _Vertex;
  attribute vec3 _Normal;
  attribute vec2 _TexCoord0;

  uniform mat4 _ModelMatrix;
  uniform mat3 _NormalMatrix;
  uniform mat4 _ProjectionViewMatrix;

  uniform bool useLights;
  
  varying vec2 vTexCoord0;
  varying vec3 vNormal;
  varying vec3 vLightColor;
  varying vec3 vLightDirection;
  
  void main(void) {
    vTexCoord0 = _TexCoord0;

    if (useLights) {
        vLightColor = vec3(0.5, 0.5, 0.5);
        vLightDirection = vec3(0.5, 4, 4);
        normalize(vLightDirection);
        vNormal = normalize(_NormalMatrix * _Normal);
//        if (dot(vNormal, vec3(0,0,1)) < 0.0) {
//          vNormal = vNormal * -1.0;
//        }
    } else {  
        vLightColor = vec3(_TexCoord0.t, _TexCoord0.t, _TexCoord0.t);
        vLightDirection = vec3(1.0, 0.0, 0.0);
        vNormal = vec3(1.0, 0.0, 0.0);
    }

    gl_Position = _ProjectionViewMatrix * _ModelMatrix * vec4(_Vertex, 1.0);
  }