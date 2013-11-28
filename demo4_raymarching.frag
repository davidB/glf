// based on
// http://geeks3d.developpez.com/GLSL/raymarching/
// http://9bitscience.blogspot.fr/2013/07/raymarching-distance-fields_14.html
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// https://www.shadertoy.com/view/MsXGWr
precision mediump float;

const float PI = 3.14159265358979323846264;
varying vec2 vTexCoord0;
uniform mat4 lightProj, lightView;
uniform mat4 _ModelMatrix;
uniform float time;

float obj_x0(in vec3 p)
{
//----------------
return length(p)-1.0;
//----------------
}


vec2 obj_x(in vec3 p)
{
  return vec2(obj_x0(p), 1.0);
}
vec2 obj_floor(in vec3 p)
{
  return vec2(p.z+1.0,0);
}

vec2 obj_union(in vec2 obj0, in vec2 obj1)
{
  if (obj0.x < obj1.x)
      return obj0;
  else
      return obj1;
}


vec2 obj_roundBox( vec3 p, vec3 b, float r )
{
  return vec2(length(max(abs(p)-b,0.0))-r, 1);
}

vec2 obj_sphere(in vec3 p)
{
  float d = length(p)-1.9;
  return vec2(d,1);
}
vec2 obj_torus(in vec3 p)
{
  vec2 r = vec2(2.1,0.5);
  vec2 q = vec2(length(p.xz)-r.x,p.y);
  float d = length(q)-r.y;
  return vec2(d,1);
}

vec2 obj_tetrahedron0(vec3 p)
{
	vec3 a1 = vec3(1,0,0);
	vec3 a2 = vec3(-1,-1,0);
	vec3 a3 = vec3(-1,1, 0);
	vec3 a4 = vec3(0,0,1);
  	float r = 3.0;
    float d = length(p-a1)-r;
	d = max(length(p-a2)-r,d);
  	d = max(length(p-a3)-r,d);
	d = max(length(p-a4)-r,d);
	return vec2(d, 1);
}

const float TIER = 1.0/3.0;

float tsphere(vec3 p, vec3 a1, vec3 a2, vec3 a3)
{

  vec3 c = vec3(a1);
  c = c + (a2 - c) * 0.5;
  c = c + (a3 - c) * 0.5;

  //vec3 c = (a1 + a2 + a3) * TIER;
  vec3 n = normalize(cross(a2 - a1, a3 - a1));
  float b = length(a1 - c);
  float r = max(b, 50.0);
  float h = sqrt(r*r - b*b);
  //float h = r ;//approx
  return length(p - (c + n * h))-r;
}
vec2 obj_tetrahedronArc(vec3 p)
{
	vec3 a1 = vec3(2,0,1);
	vec3 a2 = vec3(-1,-1,1);
	vec3 a3 = vec3(-1,1, 1);
	vec3 a4 = vec3(0,0,1.5);
  	float r = 3.0;
  	float d = 0.0;
	d = max(tsphere(p, a1, a3, a2),d);
  	d = max(tsphere(p, a1, a2, a4),d);
  	d = max(tsphere(p, a4, a2, a3),d);
  	d = max(tsphere(p, a1, a4, a3),d);
	return vec2(d, 1);
}

float thalfspace(vec3 p, vec3 a1, vec3 a2, vec3 a3)
{

  vec3 c = vec3(a1);
  c = c + (a2 - c) * 0.5;
  c = c + (a3 - c) * 0.5;

  //vec3 c = (a1 + a2 + a3) * TIER;
  vec3 n = -normalize(cross(a2 - a1, a3 - a1));
  float b = length(a1 - c);
  return max(0.0, dot(p-a1, n));
}

vec2 obj_tetrahedron(vec3 p)
{
	vec3 a1 = vec3(2,0,1);
	vec3 a2 = vec3(-1,-1,1);
	vec3 a3 = vec3(-1,1, 1);
	vec3 a4 = vec3(0,0,1.5);
  	float r = 3.0;
  	float d = 0.0;
	d = max(thalfspace(p, a1, a3, a2),d);
  	d = max(thalfspace(p, a1, a2, a4),d);
  	d = max(thalfspace(p, a4, a2, a3),d);
  	d = max(thalfspace(p, a1, a4, a3),d);
	return vec2(d, 1);
}

vec3 opTx( vec3 p, mat4 m)
{
    vec4 q = m * vec4(p, 1.0); //invert(m) * p
    return q.xyz;
}
// Union d'objets
vec2 distance_to_obj(in vec3 p)
{
  vec2 d = obj_floor(p);
  /*
  //mat4 m = mat4(_ModelMatrix);
  mat4 m = mat4(1.0);
  for(int i=0; i< 30; i++) {
    m[3].x = m[3].x + 0.2;
    m[3].z = m[3].z + 0.2;
  	d = obj_union(obj_roundBox(opTx(p, m), vec3(2.0,1.0,1.0), 0.2), d);
  }
  */
  //d = obj_union(obj_roundBox(p, vec3(0.5,0.5,0.5), 0.0), d);
  //d = obj_union(obj_tetrahedron(p), d);
  d = obj_union(obj_x(p), d);
  //d = obj_union(obj_torus(p),d);
  return d;
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
	float h = 1.0;
    for( int i=0; i<35; i++ )
    {
        h = distance_to_obj(ro + rd*t).x;
        res = min( res, k*h/t );
		t += clamp( h, 0.02, 2.0 );
    }
    return clamp(res,0.0,1.0);
}

// Couleur du sol (damier)
vec4 floor_color(in vec3 p)
{
  float m = floor(p.x) + floor(p.y);
  m = mod(m, 2.0) ;
  if ( m == 0.0)
  {
    return vec4(0.9,0.0,0.5,1);
  }
  else
  {
      return vec4(0.2,0.2,0.8,1);
   }
}

// Couleur du sol (damier)
vec4 floor_color0(in vec3 p)
{
  if (fract(p.x*0.2)>0.2)
  {
    if (fract(p.y*0.2)>0.2)
      return vec4(0,0.1,0.2,1.0);
    else
      return vec4(1,1,1,1.0);
  }
  else
  {
    if (fract(p.y*.2)>.2)
      return vec4(1,1,0,1.0);
    else
      return vec4(0.3,0,0,1.0);
   }
}

// Couleur de la primitive
vec4 prim_c(in vec3 p)
{
  //return vec4(0.9,0.3,0.7,1.0); // aurore
  //return vec4(1.0,0.9,0.8,1.0); //ryowen
  return vec4(1.0,0.9,0.8,1.0) + vec4(0.9,0.3,0.7,1.0);
}

vec3 e=vec3(0.02,0,0);
const vec3 lightPosition = vec3(-2.0,3.0,6.0);

vec3 getNormal(vec2 d, vec3 p)
{
   vec3 n = vec3(d.x-distance_to_obj(p-e.xyy).x,
                  d.x-distance_to_obj(p-e.yxy).x,
                  d.x-distance_to_obj(p-e.yyx).x);
   return normalize(n);

}
vec4 getColor(vec2 d, vec3 p)
{
  vec4 c;
      // y est utilisé pour gérer les matériaux
    if (d.y==0.0)
      c=floor_color(p);
    else
      c=prim_c(p);
	return c;
}

float attenuation(vec3 dir){
  float dist = length(dir);
  float radiance = 1.0/(1.0+pow(dist/10.0, 2.0));
  return clamp(radiance*10.0, 0.0, 1.0);
}

float influence(vec3 normal, float coneAngle){
  float minConeAngle = ((360.0-coneAngle-10.0)/360.0)*PI;
  float maxConeAngle = ((360.0-coneAngle)/360.0)*PI;
  return smoothstep(minConeAngle, maxConeAngle, acos(normal.z));
}

float lambert(vec3 surfaceNormal, vec3 lightDirNormal){
  return max(0.0, dot(surfaceNormal, lightDirNormal));
}

vec3 skyLight(vec3 normal){
  return vec3(smoothstep(0.0, PI, PI-acos(normal.y)))*0.4;
}


const float rimStart = 0.5;
const float rimEnd = 1.0;
const float rimMultiplier = 0.1;
vec3  rimColor = vec3(0.0, 0.0, 0.5);

vec3 rimLight(vec3 viewPos, vec3 normal, vec3 position) {
  float normalToCam = 1.0 - dot(normalize(normal), normalize(viewPos.xyz - position.xyz));
  float rim = smoothstep(rimStart, rimEnd, normalToCam) * rimMultiplier;
  return (rimColor * rim);
}

vec4 shade1(vec2 d, vec3 p)
{
  vec4 c = getColor(d, p);
  vec3 lightSegment = lightPosition - p;
  vec3 lightDir = normalize(lightSegment);
  float lightConeAngle = 85.0;
  //vec3 normal = lightRot * normal;
  vec3 normal = getNormal(d, p);
  float lighting = (
    lambert(normal, lightDir)
    * influence(-lightDir, lightConeAngle)
    * attenuation(lightSegment)
    * softshadow( p+0.01*normal, lightDir, 0.0005, 32.0 )
  );
  c.rgb = (
    skyLight(normal) +
#ifdef RIMLIGHT
    rimLight(camPosition, normal, p) +
#endif
    clamp(lighting, 0.0, 1.0) * c.rgb
  );
  return c;
}
vec4 shade0(vec2 d, vec3 p)
{
    vec4 c = getColor(d, p);
    vec3 normal = getNormal(d, p);
    //spotlight

    vec3 lightSegment = lightPosition - p;
    vec3 lightDir = normalize(lightSegment);
    float lightIntensity = dot(normal, lightDir);
  	c.rgb = lightIntensity * c.rgb;
    c.rgb = (c.rgb + pow(lightIntensity,10.0))*(1.0-length(lightSegment)*.01);

    // directionnal light
    /*
    vec3 lightDir = normalize(vec3(1,1,1));
    float lightIntensity = dot(normal, lightDir);
  	c.rgb =lightIntensity*c.rgb;
    */
    //return getReflectance(p) * lightIntensity;
    //float sha = 1.0;
    float sha = softshadow( p+0.01*normal, lightDir, 0.0005, 32.0 );
  	c.rgb = c.rgb *sha;
  	//c.a = c.a*sha;
  	return c;
}

vec4 shade(vec2 d, vec3 p)
{
  if (d.y == 0.0) {
    return shade1(d, p);
  } else {
    return shade0(d, p);
  }
}

void main(void)
{
  vec2 q = vTexCoord0.xy;
  vec2 vPos = -1.0 + 2.0 * q;

  // Inclinaison de la caméra. (up)
  vec3 vuv=vec3(0,0,1);

  // Direction de la caméra. (target)
  vec3 vrp=vec3(0,0,0);

  //float mx=mouse.x*PI*2.0;
  //float my=mouse.y*PI/2.01;
  //vec3 prp=vec3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*6.0;
  vec3 prp = vec3(-1.0,0.0,3.0);//cam_pos;

  // Configuration de la caméra.
  vec3 vpn=normalize(vrp-prp);
  vec3 u=normalize(cross(vuv,vpn));
  vec3 v=cross(vpn,u);
  vec3 vcv=(prp+vpn);
  //vec3 scrCoord=vcv+vPos.x*u*resolution.x/resolution.y+vPos.y*v;
  vec3 scrCoord=vcv+vPos.x*u*0.8+vPos.y*v*0.8;
  vec3 scp=normalize(scrCoord-prp);

  // Raymarching.
  //const vec3 e=vec3(0.02,0,0);
  const float maxd=100.0; // Profondeur maximale
  vec2 d=vec2(0.02,0.0);
  vec3 c,p,N;

  float f=1.0;
  for(int i=0;i<256;i++)
  {
    if ((abs(d.x) < .001) || (f > maxd))
      break;

    f+=d.x;
    p=prp+scp*f;
    d = distance_to_obj(p);
  }

  if (f < maxd)
  {
	gl_FragColor = shade(d, p);
  }
  else
    gl_FragColor=vec4(0,0,1,1); // Couleur de fond
}
