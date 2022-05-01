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
float OuterSkinEmissive = 0.005f;
float OuterSkinThickness = 0.5f;

texture NoiseTexture;

//When overriding textures
texture PrimaryTexture;
//texture SecondaryTexture;
//texture SecondaryNormalMapMask;
//texture NormalMap;
//texture NormalMapMask;
texture ExtrusionMask;
//texture ExtrusionNoiseXZTexture;
//texture ExtrusionNoiseXYTexture;


float TopSkinSpecular = 0.1;
float UnderSkinSpecular = 0.8;
float NormalMaskIntensity = 0.5;
float PrimarySecondaryTextureRatio = 1.0;
float FBNoiseAmplitude = 5.0;
float time = 0.0f;

bool bExtrude = false;
bool bNoise = false;


sampler PrimaryTextureSampler = sampler_state
{
    Texture = (PrimaryTexture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};
//sampler SecondaryTextureSampler = sampler_state
//{
//    Texture = (SecondaryTexture);
//
//    MinFilter = Linear;
//    MagFilter = Linear;
//    MipFilter = Linear;
//};

//sampler NormalMapSampler = sampler_state
//{
//    Texture = (NormalMap);

//    MinFilter = Linear;
//    MagFilter = Linear;
//    MipFilter = Linear;
//    ADDRESSU = WRAP;
//    ADDRESSV = WRAP;    
//};
//sampler NormalMapMaskSampler = sampler_state
//{
//    Texture = (NormalMapMask);

//    MinFilter = Linear;
//    MagFilter = Linear;
//    MipFilter = Linear;
//};

//sampler SecondaryNormalMapMaskSampler = sampler_state
//{
//    Texture = (SecondaryNormalMapMask);
//
//    MinFilter = Linear;
//    MagFilter = Linear;
//    MipFilter = Linear;
//};

sampler ExtrusionMaskSampler = sampler_state
{
    Texture = (ExtrusionMask);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};


//sampler ExtrusionNoiseXZTextureSampler = sampler_state
//{
//    Texture = (ExtrusionNoiseXZTexture);

//    MinFilter = Linear;
//    MagFilter = Linear;
//    MipFilter = Linear;
//    ADDRESSU = WRAP;
//    ADDRESSV = WRAP;
//};

//sampler ExtrusionNoiseXYTextureSampler = sampler_state
//{
//    Texture = (ExtrusionNoiseXYTexture);

//    MinFilter = Linear;
//    MagFilter = Linear;
//    MipFilter = Linear;
//    ADDRESSU = WRAP;
//    ADDRESSV = WRAP;
//};

// Vertex shader input structure.
struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 BoneIndices : BLENDINDICES0;
    float4 BoneWeights : BLENDWEIGHT0;
//    float3 Tangent : TANGENT0;
//    float3 Binormal : BINORMAL0;
};

// Vertex shader output structure.
struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
	float4 WorldPosition	: TEXCOORD1;
//	float3x3 TangentToWorld : TEXCOORD2;


};

struct PS_OUTPUT
{
    float4 Color	: COLOR0;
    float4 Normal	: COLOR1;
	float4 Depth	: COLOR2;
//	float4 Light	: COLOR3;
};

// Vertex shader program.
VS_OUTPUT SkinnedModelDeferredFrancisBaconOuterVS(VS_INPUT input)
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
	
    //We will be storing view space normals.  Flip the normal because we are rendering inside out.
    output.Normal = -normal;

	//Calculate the normal in skin-space 
    float3 skinTransformSpaceNormal = mul(input.Normal, skinTransform);

    // Skin the vertex position. Make the outer layer slightly extruded from the inner maximum
    float4 position = mul(input.Position, skinTransform) + float4(skinTransformSpaceNormal,0.0f) * OuterSkinThickness;
    
    output.Position = mul(mul(mul(position, World), View), Projection);

	output.WorldPosition = mul(position, World);
	
    output.TexCoord = input.TexCoord;
		
    return output;
}

// Pixel shader program.
PS_OUTPUT SkinnedModelDeferredFrancisBaconOuterPS(VS_OUTPUT input) : COLOR0
{
	PS_OUTPUT output;

    float4 color = tex2D(PrimaryTextureSampler, input.TexCoord);
    
	//Store Color
	output.Color.rgb = color.rgb;
	output.Color.a = OuterSkinEmissive;

	//Map normal in 0..1 (converted back for the lighting equation)
	output.Normal.xyz = (0.5f * (input.Normal + 1.0f)).xyz;

	//Store out normal, with specular in the w component	
	output.Normal.w = TopSkinSpecular;
    
    float4 projPosition = mul(mul(input.WorldPosition, View), Projection);
    output.Depth		= 0;
    
    output.Depth.x = projPosition.z/projPosition.w;
        
    return output;
}

// Vertex shader program.
VS_OUTPUT SkinnedModelDeferredFrancisBaconInnerVS(VS_INPUT input)
{
    VS_OUTPUT output;
    
    // Blend between the weighted bone matrices.
    float4x4 skinTransform = 0;
    
    skinTransform += Bones[input.BoneIndices.x] * input.BoneWeights.x;
    skinTransform += Bones[input.BoneIndices.y] * input.BoneWeights.y;
    skinTransform += Bones[input.BoneIndices.z] * input.BoneWeights.z;
    skinTransform += Bones[input.BoneIndices.w] * input.BoneWeights.w;
    
    // Skin the vertex normal
    float3 skinSpaceNormal = normalize(mul(input.Normal, skinTransform));
    
    output.Normal = mul(skinSpaceNormal, World);

    // Skin the vertex position.
    float4 baseVertexPosition = mul(input.Position, skinTransform);
    
    float extrusion = tex2Dlod(ExtrusionMaskSampler, float4(input.TexCoord.xy,0,0)).r;
    
    float4 worldPosition = mul(baseVertexPosition - (FBNoiseAmplitude * extrusion) * float4(skinSpaceNormal,0.0f), World);
    
    output.Position			= mul(mul(worldPosition, View), Projection);
    output.WorldPosition	= worldPosition;	
    output.TexCoord			= input.TexCoord;
		
    return output;
}


// Pixel shader program.
PS_OUTPUT SkinnedModelDeferredFrancisBaconInnerPS(VS_OUTPUT input) : COLOR0
{
	PS_OUTPUT output;

    float4 color = tex2D(PrimaryTextureSampler, input.TexCoord);

	//Store Color
	output.Color.rgb = color.rgb;
	output.Color.a = 0.0f;
	
	//Map normal in 0..1
	output.Normal.xyz = (0.5f * (normalize(input.Normal) + 1.0f)).xyz;
	
	//Store out normal, with specular in the w component	
	output.Normal.w = UnderSkinSpecular;

    //Store depth
    float4 projPosition = mul(mul(input.WorldPosition, View), Projection);
    output.Depth		= 0;    
    output.Depth.x = projPosition.z/projPosition.w;

    return output;
}

technique SkinnedModelDeferredFrancisBaconOuterTechnique
{
    pass SkinnedModelDeferredFrancisBaconOuterPass
    {
        VertexShader = compile vs_3_0 SkinnedModelDeferredFrancisBaconOuterVS();
        PixelShader = compile ps_3_0 SkinnedModelDeferredFrancisBaconOuterPS();
    }
}

technique SkinnedModelDeferredFrancisBaconInnerTechnique
{
    pass SkinnedModelDeferredFrancisBaconInnerPass
    {
        VertexShader = compile vs_3_0 SkinnedModelDeferredFrancisBaconInnerVS();
        PixelShader = compile ps_3_0 SkinnedModelDeferredFrancisBaconInnerPS();
    }
}
