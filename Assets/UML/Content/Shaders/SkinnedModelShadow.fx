

// Maximum number of bone matrices we can render using shader 2.0 in a single pass.
// If you change this, update SkinnedModelProcessor.cs to match.
#define MaxBones 59


// Input parameters.
float4x4 View;
float4x4 Projection;

float4x4 Bones[MaxBones];

texture Texture;

sampler Sampler = sampler_state
{
    Texture = (Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};



struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 BoneIndices : BLENDINDICES0;
    float4 BoneWeights : BLENDWEIGHT0;
};
    

float4x4 WorldCameraViewProjection;
float4x4 WorldLightViewProjection;

float4x4 World;

float3 WorldLightPosition;
float3 CameraPosition;

float FarClip = 2048;

/*
Depth Map Pass
==============
*/

struct DEPTH_VS_OUTPUT
{
	float4 Position			: POSITION;
	float2 TexCoord			: TEXCOORD0;
	float4 WorldPosition	: TEXCOORD1;
};

DEPTH_VS_OUTPUT Depth_VS (VS_INPUT input)
{
    DEPTH_VS_OUTPUT output;
    
    // Blend between the weighted bone matrices.
    float4x4 skinTransform = 0;
    
    skinTransform += Bones[input.BoneIndices.x] * input.BoneWeights.x;
    skinTransform += Bones[input.BoneIndices.y] * input.BoneWeights.y;
    skinTransform += Bones[input.BoneIndices.z] * input.BoneWeights.z;
    skinTransform += Bones[input.BoneIndices.w] * input.BoneWeights.w;
    
    // Skin the vertex position.
    float4 position = mul(input.Position, skinTransform);
    
    output.Position = mul(mul(mul(position, World), View), Projection);
	//output.Position = mul(position, WorldCameraViewProjection);
	output.WorldPosition = float4(mul(position, World).xyz,1);
	//output.WorldPosition /= output.WorldPosition.w;

    output.TexCoord = input.TexCoord;
    
    return output;
}





float4 Depth_PS (DEPTH_VS_OUTPUT Input) : COLOR0
{
	float depth = length(WorldLightPosition.xyz - Input.WorldPosition.xyz) / FarClip;
	
	return float4(depth, depth * depth, 0, 0);
}

technique SkinnedModelDepthMap
{
	pass P0
	{
 		VertexShader = compile vs_2_0 Depth_VS();
		PixelShader  = compile ps_2_0 Depth_PS();
	}
}

