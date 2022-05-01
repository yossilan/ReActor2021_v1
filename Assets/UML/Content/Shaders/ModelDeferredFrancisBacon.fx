#include <Include\\SpotLightShadowShared.fxh>

float3 AmbientColor = 0.05;

float4x4 World;
float4x4 View;
float4x4 WorldCameraViewProjection;

float4 diffuseColour = float4(0.3f, 0.3f, 0.3f, 1.0f);

float FarClip = 2048;
int NumTorches = 1;
float Transparency = 0.1;
float Emissive = 0.0;

Texture DiffuseTexture;

sampler diffuseSampler = sampler_state
{
	Texture = <DiffuseTexture>;
	
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


VS_OUTPUT FrancisBaconOuterVS (VS_INPUT Input)
{
	VS_OUTPUT Output;
	
	Output.Position = mul(Input.Position, WorldCameraViewProjection);
	Output.LocalPosition = Input.Position;

	Output.TexCoords = Input.TexCoords;
	Output.Normal = normalize(mul(Input.Normal, World));
	
	return Output;
}

PS_OUTPUT FrancisBaconOuterPS(VS_OUTPUT input)
{
	PS_OUTPUT output;
	
    output.Color = tex2D(diffuseSampler, input.TexCoords);
    output.Color.a = Emissive;
    
    output.Normal.xyz =  0.5f * (normalize(input.Normal.xyz) + 1.0f);
    output.Normal.w = 0.9; //Store specular power
    
    float4 projPosition = mul(input.LocalPosition, WorldCameraViewProjection);
    output.Depth = 0;
    output.Depth.x = projPosition.z / projPosition.w;
    
    output.Light = float4(0.2, 0, 0, 0);	//Our specular component
    
    return output;
}

VS_OUTPUT FrancisBaconInnerVS (VS_INPUT Input)
{
	VS_OUTPUT Output;
	
	Output.Position = mul(Input.Position, WorldCameraViewProjection);
	Output.LocalPosition = Input.Position;

	Output.TexCoords = Input.TexCoords;
	Output.Normal = normalize(mul(Input.Normal, World));
	
	return Output;
}

PS_OUTPUT FrancisBaconInnerPS(VS_OUTPUT input)
{
	PS_OUTPUT output;
	
    output.Color = tex2D(diffuseSampler, input.TexCoords);
    output.Color.a = Emissive;
    
    output.Normal.xyz =  0.5f * (normalize(input.Normal.xyz) + 1.0f);
    output.Normal.w = 0.9; //Store specular power
    
    float4 projPosition = mul(input.LocalPosition, WorldCameraViewProjection);
    output.Depth = 0;
    output.Depth.x = projPosition.z / projPosition.w;
    
    output.Light = float4(0.2, 0, 0, 0);	//Our specular component
    
    return output;
}

technique ModelDeferredFrancisBaconOuterTechnique
{
	pass ModelDeferredFrancisBaconOuterPass0
	{
		CULLMODE = CCW;
		
 		VertexShader = compile vs_3_0 FrancisBaconOuterVS();
		PixelShader  = compile ps_3_0 FrancisBaconOuterPS();
	}
}

//technique ModelDeferredFrancisBaconInnerTechnique
//{
//	pass ModelDeferredFrancisBaconInnerPass0
//	{
 //		VertexShader = compile vs_3_0 FrancisBaconInnerVS();
//		PixelShader  = compile ps_3_0 FrancisBaconInnerPS();
//	}
//}