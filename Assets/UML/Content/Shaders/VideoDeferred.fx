#include <Include\\SpotLightShadowShared.fxh>

float4x4 World;
float4x4 View;
float4x4 WorldCameraViewProjection;

float VideoScreenEmissive = 0.3;
float PreviousNextTextureRatio = 0.5;

//The video textures of the next and previous frame
Texture VideoTexturePrevious;
Texture VideoTextureNext;
Texture VideoMask;

sampler videoTexturePreviousSampler = sampler_state
{
	Texture = <VideoTexturePrevious>;
	
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};
sampler videoTextureNextSampler = sampler_state
{
	Texture = <VideoTextureNext>;
	
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

sampler videoMaskSampler = sampler_state
{
	Texture = <VideoMask>;
	
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
};

struct VS_INPUT
{
	float4 Position			: POSITION;
	float3 Normal			: NORMAL;	
	float2 TexCoords		: TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 Position			: POSITION;
	float3 Normal			: NORMAL0;
	float4 LocalPosition	: TEXCOORD0;
	float2 TexCoords		: TEXCOORD1;	
};

struct PS_OUTPUT
{
    float4 Color	: COLOR0;
    float4 Normal	: COLOR1;
	float4 Depth	: COLOR2;
	float4 Light	: COLOR3;
};


VS_OUTPUT Scene_VS (VS_INPUT Input)
{
	VS_OUTPUT Output;
	
	Output.Position = mul(Input.Position, WorldCameraViewProjection);
	Output.LocalPosition = Input.Position;

	Output.TexCoords = Input.TexCoords;
	Output.Normal = normalize(mul(Input.Normal, World));
	
	return Output;
}

PS_OUTPUT Scene_PS(VS_OUTPUT input)
{
	PS_OUTPUT output;

	//Calculate the combination of the next and previous texture frame	
    float4 color =	tex2D(videoTexturePreviousSampler, input.TexCoords) * (1.0-PreviousNextTextureRatio) + 
					tex2D(videoTextureNextSampler, input.TexCoords) * PreviousNextTextureRatio;
					
    float videoMask = tex2D(videoMaskSampler, input.TexCoords).x;
    output.Color = color * videoMask;        
    output.Color.a = VideoScreenEmissive;
    
    output.Normal.xyz =  0.5f * (normalize(input.Normal.xyz) + 1.0f);
    output.Normal.w = 0.9; //Store specular power
    
    float4 projPosition = mul(input.LocalPosition, WorldCameraViewProjection);
    output.Depth = 0;
    output.Depth.x = projPosition.z / projPosition.w;
    
    output.Light = float4(0.2, 0, 0, 0);	//Our specular component
    
    return output;
}

technique VideoDeferredTechnique
{
	pass VideoDeferredTexturedLitPass0
	{
 		VertexShader = compile vs_3_0 Scene_VS();
		PixelShader  = compile ps_3_0 Scene_PS();
	}
}