//-----------------------------------------------------------------------------
// SkinnedModel.fx
//
// Skinned Model with Normal Mapping
//
//-----------------------------------------------------------------------------

#include <include\\SpotLightShadowShared.fxh>

// Maximum number of bone matrices we can render using shader 2.0 in a single pass.
// If you change this, update SkinnedModelProcessor.cs to match.
#define MaxBones 59

#define MaxTorches 6;
int NumTorches = 6;

// Input parameters.
float4x4 World;
float4x4 View;
float4x4 Projection;

//We have 8 fixed position spotlights
float3 CameraPosition;

float FarClip = 2048;

float4x4 Bones[MaxBones];

float3 AmbientColor = 0.01;

texture Texture;
texture Extrusion;
texture NormalMap;
texture NormalMapMask;
texture NoiseTexture;

bool bExtrude = false;
bool bNoise = false;


sampler Sampler = sampler_state
{
    Texture = (Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

sampler ExtrusionSampler = sampler_state
{
    Texture = (Extrusion);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

sampler NormalMapSampler = sampler_state
{
    Texture = (NormalMap);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;    
};
sampler NormalMapMaskSampler = sampler_state
{
    Texture = (NormalMapMask);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

sampler NoiseSampler = 
sampler_state
{
    Texture = < NoiseTexture >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
};


// Vertex shader input structure.
struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 BoneIndices : BLENDINDICES0;
    float4 BoneWeights : BLENDWEIGHT0;
    float3 Tangent : TANGENT;
};

// Vertex shader output structure.
struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
	float4 WorldPosition	: TEXCOORD1;
	float4 LocalPosition	: TEXCOORD2;
	float3 Light0	: TEXCOORD3;
	float3 Light1	: TEXCOORD4;
	float3 Light2	: TEXCOORD5;
	float3 Light3	: TEXCOORD6;
	float3 Light4	: TEXCOORD7;
	float3 Light5	: TEXCOORD8;
};


// Vertex shader program.
VS_OUTPUT VertexShader(VS_INPUT input)
{
    VS_OUTPUT output;
    
    // Blend between the weighted bone matrices.
    float4x4 skinTransform = 0;
    
    skinTransform += Bones[input.BoneIndices.x] * input.BoneWeights.x;
    skinTransform += Bones[input.BoneIndices.y] * input.BoneWeights.y;
    skinTransform += Bones[input.BoneIndices.z] * input.BoneWeights.z;
    skinTransform += Bones[input.BoneIndices.w] * input.BoneWeights.w;
    
    // Skin the vertex normal, then compute lighting.
    float3 normal = normalize(mul(mul(input.Normal, skinTransform), World));
    float3 tangent = normalize(mul(mul(input.Tangent, skinTransform), World));
    
	//Calculate the transform to tangent space
	float3x3 worldToTangentSpace;
	worldToTangentSpace[1] = tangent;
	worldToTangentSpace[0] = cross(tangent,normal);
	worldToTangentSpace[2] = normal;

    // Skin the vertex position.
    float4 position = mul(input.Position, skinTransform);
    
    output.Position = mul(mul(mul(position, World), View), Projection);

	output.WorldPosition = mul(position, World);
	output.WorldPosition /= output.WorldPosition.w;
	
    output.TexCoord = input.TexCoord;
	
	float4 localPosition = mul(input.Position, skinTransform);
	output.LocalPosition = localPosition;
	
	output.Light0.xyz = mul(worldToTangentSpace,LightDirection[0]);		
	output.Light1.xyz = mul(worldToTangentSpace,LightDirection[1]);	
	output.Light2.xyz = mul(worldToTangentSpace,LightDirection[2]);	
	output.Light3.xyz = mul(worldToTangentSpace,LightDirection[3]);	
	output.Light4.xyz = mul(worldToTangentSpace,LightDirection[4]);	
	output.Light5.xyz = mul(worldToTangentSpace,LightDirection[5]);		
		
    return output;
}

float4 SpecularColour = float4(1.0f,1.0f,1.0f,1.0);
float SpecularIntensity = 1.0f;
float4 DiffuseColour = float4(1.0f,1.0f,1.0f,1.0);
float DiffuseIntensity = 0.5f;

static inline vector PhongSpecular(in float3 light, in float3 norm, in float3 view, in float roughness)
{
	//Calculate reflection vector
	float3 reflectionVector = 2 * dot(norm,light)*norm - light;
	
	return SpecularColour * SpecularIntensity * pow( saturate(dot(reflectionVector, view)), 1/roughness);
}

static inline vector LambertDiffuse(in float3 light, in float3 norm)
{
	return DiffuseColour * DiffuseIntensity * dot(norm, light);
}

// Pixel shader program.
float4 PixelShader(VS_OUTPUT input) : COLOR0
{
    float	cumulativeLight = 0; 
    float	shadow = 0;
    float3	light = 0;    
    float2	ProjectedTexCoords;
    float lightDotNorm = 0;
    float3 normalMap = 0;
	float4 shadowProjection = 0;
	float4 mask = 0;
	float3 tangentLightDir[6];
	float4 moments = 0;
	float4 toEyeNormal = -normalize(mul(input.WorldPosition, View));

	tangentLightDir[0] = input.Light0;
	tangentLightDir[1] = input.Light1;
	tangentLightDir[2] = input.Light2;
	tangentLightDir[3] = input.Light3;
	tangentLightDir[4] = input.Light4;
	tangentLightDir[5] = input.Light5;
	
    float4	color = tex2D(Sampler, input.TexCoord);
    float4  normalMask = tex2D(NormalMapMaskSampler, input.TexCoord);

	color = color*0.7 + color*normalMask*0.3;

   	float noise = tex2D(NoiseSampler, input.TexCoord);
    
    if (bNoise)
		color = color*0.7 + color*noise*0.3;
    
    for (int torch=0; torch < NumTorches; torch++)
	{
		shadow = 0.0f;
					
	    normalMap = tex2D(NormalMapSampler, input.TexCoord).xyz;
	    normalMap.x = 2 * (normalMap.x - 0.5);
	    normalMap.y = 2 * (normalMap.y - 0.5);
	    normalMap.z = 2 * (normalMap.z - 0.5);
	    
	    //tangentLightDir = normalize(tangentLightDir[torch]);
		lightDotNorm = saturate(dot(tangentLightDir[torch], normalMap));

		if (lightDotNorm > 0.02)
		{									    			
			shadowProjection = mul(input.LocalPosition, WorldLightViewProjection[torch]);
			
			ProjectedTexCoords[0] = shadowProjection.x / shadowProjection.w / 2.0f + 0.5f;
			ProjectedTexCoords[1] = -shadowProjection.y / shadowProjection.w / 2.0f + 0.5f;
		    
			float len = length(LightPosition[torch] - input.WorldPosition);
			float normLen = len / FarClip;
			
			moments = tex2D(shadowSampler[torch], ProjectedTexCoords);
			
  			float E_x2 = moments.y;
			float Ex_2 = moments.x * moments.x;
			float variance = min(max(E_x2 - Ex_2, 0.0) + 0.0001f, 1.0);
			float m_d = (moments.x - normLen);
			float p = variance / (variance + m_d * m_d);
		    	
			shadow = max(step(normLen, moments.x), p);
			mask = tex2D(maskSampler, ProjectedTexCoords);
			
			shadow = shadow * mask.r;

			float attenuation = 100000.0f/(len*len);
			
			cumulativeLight = saturate(cumulativeLight + attenuation * shadow * 
									  ( LambertDiffuse(tangentLightDir[torch], normalMap) +
									    PhongSpecular(tangentLightDir[torch], normalMap, toEyeNormal, 0.3)));
		}
		
	}
       
    return color*float4(AmbientColor,1.0f) + color*cumulativeLight;
}


technique SkinnedModelNormalMappedTechnique
{
    pass SkinnedModelNormalMappedPass
    {
        VertexShader = compile vs_3_0 VertexShader();
        PixelShader = compile ps_3_0 PixelShader();
    }
}
