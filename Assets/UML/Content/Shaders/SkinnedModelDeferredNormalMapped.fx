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
float Emissive = 0.0;

texture NoiseTexture;

//When overriding textures
texture PrimaryTexture;
texture SecondaryTexture;
texture SecondaryNormalMapMask;
texture NormalMap;
texture NormalMapMask;


float TopSkinSpecular = 0.1;
float UnderSkinSpecular = 0.8;
float NormalMaskIntensity = 0.5;
float PrimarySecondaryTextureRatio = 1.0;

bool bExtrude = false;
bool bNoise = false;


sampler PrimaryTextureSampler = sampler_state
{
    Texture = (PrimaryTexture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};
sampler SecondaryTextureSampler = sampler_state
{
    Texture = (SecondaryTexture);

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

sampler SecondaryNormalMapMaskSampler = sampler_state
{
    Texture = (SecondaryNormalMapMask);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};


// Vertex shader input structure.
struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 BoneIndices : BLENDINDICES0;
    float4 BoneWeights : BLENDWEIGHT0;
    float3 Tangent : TANGENT0;
    float3 Binormal : BINORMAL0;
};

// Vertex shader output structure.
struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
	float4 WorldPosition	: TEXCOORD1;
	float3x3 TangentToWorld : TEXCOORD2;


};

struct PS_OUTPUT
{
    float4 Color	: COLOR0;
    float4 Normal	: COLOR1;
	float4 Depth	: COLOR2;
//	float4 Light	: COLOR3;
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
    
    // Skin the vertex normal
    float3 normal = normalize(mul(mul(input.Normal, skinTransform), World));
    //We will be storing view space normals
    output.Normal = mul(normal, View);

    // Skin the vertex tangent
    float3 tangent = normalize(mul(mul(input.Tangent, skinTransform), World));
    float3 binormal = normalize(mul(mul(input.Binormal, skinTransform), World));
        
	//Calculate the transform to tangent space
	output.TangentToWorld[0] = tangent;
	output.TangentToWorld[1] = binormal;
	output.TangentToWorld[2] = normal;

    // Skin the vertex position.
    float4 position = mul(input.Position, skinTransform);
    
    output.Position = mul(mul(mul(position, World), View), Projection);

	output.WorldPosition = mul(position, World);
	
    output.TexCoord = input.TexCoord;
		
    return output;
}


// Pixel shader program.
PS_OUTPUT PixelShader(VS_OUTPUT input) : COLOR0
{
	PS_OUTPUT output;

    float4 color = tex2D(PrimaryTextureSampler, input.TexCoord)*PrimarySecondaryTextureRatio +
	   		       tex2D(SecondaryTextureSampler, input.TexCoord)*(1.0-PrimarySecondaryTextureRatio);
    
    float4 normalMask = tex2D(NormalMapMaskSampler, input.TexCoord)*PrimarySecondaryTextureRatio + 
					    tex2D(SecondaryNormalMapMaskSampler, input.TexCoord)*(1.0-PrimarySecondaryTextureRatio);

	//Store Color
	output.Color.rgb = color.rgb*(1.0-NormalMaskIntensity) + color.rgb*normalMask*NormalMaskIntensity;
	output.Color.a = Emissive;
	
	//Store Normal
    float3 normalFromMap = tex2D(NormalMapSampler, input.TexCoord);
    //tranform to [-1,1]
    normalFromMap = 2.0f * normalFromMap - 1.0f;
    //transform into world space
    normalFromMap = mul(normalFromMap, input.TangentToWorld);
    //normalize the result
    normalFromMap = normalize(normalFromMap);
    //output the normal, in [0,1] space
    output.Normal.rgb = 0.5f * (normalFromMap + 1.0f);
    
    //Make recessed areas less specular.  Store specular power in the 
	if (normalMask.x > 0.5)
		output.Normal.a = TopSkinSpecular;
	else
		output.Normal.a = UnderSkinSpecular;
	
    //Store depth
    //float4 eyePos = mul(input.WorldPosition, View);
    //float depth = length(eyePos.xyz) / FarClip;
    
    float4 projPosition = mul(mul(input.WorldPosition, View), Projection);
    output.Depth		= 0;
    
    output.Depth.x = projPosition.z/projPosition.w;
        
//  output.Light = float4(0.3, 0, 0, 0);	//Our specular component
    
    return output;
}

technique SkinnedModeDeferredlNormalMappedTechnique
{
    pass SkinnedModelDeferredNormalMappedPass
    {
        VertexShader = compile vs_3_0 VertexShader();
        PixelShader = compile ps_3_0 PixelShader();
    }
}

