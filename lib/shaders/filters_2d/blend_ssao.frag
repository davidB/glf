precision highp float;
 
uniform vec3 _PixelSize; // (1.0/width, 1.0/height)
uniform sampler2D _Tex0; // Rendered scene texture
varying vec2 vTexCoord0;

/// see http://devmaster.net/posts/3095/shader-effects-screen-space-ambient-occlusion
/// This fragment shader calculates the ambient occlusion contributions for each fragment.
/// This shader requires:
/// 1. View-space position buffer
/// 2. View-space normal vector buffer
/// 3. Normalmap to preturb the sampling kernel

uniform sampler2D _TexVertices;	// View space position data
uniform sampler2D _TexNormals;	// View space normal vectors
uniform sampler2D _TexNormalsRandom;	// Normalmap to randomize the sampling kernel

/// Occluder bias to minimize self-occlusion.
uniform float _OccluderBias;

/// Specifies the size of the sampling radius.
uniform float _SamplingRadius;


/// Ambient occlusion attenuation values.
/// These parameters control the amount of AO calculated based on distance
/// to the occluders. You need to play with them to find the right balance.
///
/// .x = constant attenuation. This is useful for removing self occlusion. When
///		 set to zero or a low value, you will start to notice edges or wireframes
///		 being shown. Typically use a value between 1.0 and 3.0.
///
///	.y = linear attenuation. This provides a linear distance falloff.
/// .z = quadratic attenuation. Smoother falloff, but is not used in this shader.
uniform vec2 _Attenuation;


/// Sample the ambient occlusion at the following UV coordinate.
/// * [srcPosition] 3D position of the source pixel being tested.
/// * [srcNormal] Normal of the source pixel being tested.
/// * [uv] UV coordinate to sample/test for ambient occlusion.
///
/// Returns Ambient occlusion amount.
float samplePixels(vec3 srcPosition, vec3 srcNormal, vec2 uv){
	// Get the 3D position of the destination pixel
	vec3 dstPosition = texture2D(_TexVertices, uv).xyz;

	// Calculate ambient occlusion amount between these two points
	// It is simular to diffuse lighting. Objects directly above the fragment cast
	// the hardest shadow and objects closer to the horizon have minimal effect.
	vec3 positionVec = dstPosition - srcPosition;
	float intensity = max(dot(normalize(positionVec), srcNormal) - _OccluderBias, 0.0);

	// Attenuate the occlusion, similar to how you attenuate a light source.
	// The further the distance between points, the less effect AO has on the fragment.
	float dist = length(positionVec);
	float attenuation = 1.0 / (_Attenuation.x + (_Attenuation.y * dist));
	
	return intensity * attenuation;
}

float ambientOcclusion(vec2 uv, vec3 srcPosition, vec3 srcNormal, float srcDepth, vec2 randVec){
	// The following variable specifies how many pixels we skip over after each
	// iteration in the ambient occlusion loop. We can't sample every pixel within
	// the sphere of influence because that's too slow. We only need to sample
	// some random pixels nearby to apprxomate the solution.
	//
	// Pixels far off in the distance will not sample as many pixels as those close up.
	float kernelRadius = _SamplingRadius * (1.0 - srcDepth);
	
	// Sample neighbouring pixels
	vec2 kernel[4];
	kernel[0] = vec2(0.0, 1.0);		// top
	kernel[1] = vec2(1.0, 0.0);		// right
	kernel[2] = vec2(0.0, -1.0);	// bottom
	kernel[3] = vec2(-1.0, 0.0);	// left
	
	const float Sin45 = 0.707107;	// 45 degrees = sin(PI / 4)
	
	// Sample from 16 pixels, which should be enough to appromixate a result. You can
	// sample from more pixels, but it comes at the cost of performance.
	float occlusion = 0.0;
	
	vec2 psxy = _PixelSize.xy;
	for (int i = 0; i < 4; ++i){
		vec2 k1 = reflect(kernel[i], randVec);
		vec2 k2 = vec2(k1.x * Sin45 - k1.y * Sin45,
					   k1.x * Sin45 + k1.y * Sin45);
		k1 *= psxy;
		k2 *= psxy;
		
		occlusion += samplePixels(srcPosition, srcNormal, uv + k1 * kernelRadius);
		occlusion += samplePixels(srcPosition, srcNormal, uv + k2 * kernelRadius * 0.75);
		occlusion += samplePixels(srcPosition, srcNormal, uv + k1 * kernelRadius * 0.5);
		occlusion += samplePixels(srcPosition, srcNormal, uv + k2 * kernelRadius * 0.25);
	}
	
	// Average and clamp ambient occlusion
	occlusion /= 16.0;
	occlusion = clamp(occlusion, 0.0, 1.0);
	return occlusion;
}

void main(){
  // Get position and normal vector for this fragment
  vec3 srcPosition = texture2D(_TexVertices, vTexCoord0).xyz;
  vec3 srcNormal = texture2D(_TexNormals, vTexCoord0).xyz;
  float srcDepth = texture2D(_TexVertices, vTexCoord0).w;
  vec2 randVec = normalize(texture2D(_TexNormalsRandom, vTexCoord0).xy * 2.0 - 1.0);
	
  float ao = ambientOcclusion(vTexCoord0, srcPosition, srcNormal, srcDepth, randVec);

  vec3 color = texture2D(_Tex0, vTexCoord0).xyz;
  //gl_FragColor.rgb = vec3(ao);
  gl_FragColor.rgb = clamp(color - ao, 0.0, 1.0);
  gl_FragColor.a = 1.0;
}