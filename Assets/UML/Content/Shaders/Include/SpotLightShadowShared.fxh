#ifndef _SPOTLIGHTSHADOW_FXH_
#define _SPOTLIGHTSHADOW_FXH_

#define MAX_TORCHES 7

float4x4 WorldLightViewProjection[MAX_TORCHES];

shared float4x4 WorldLightViewProjection0;
shared float4x4 WorldLightViewProjection1;
shared float4x4 WorldLightViewProjection2;
shared float4x4 WorldLightViewProjection3;
shared float4x4 WorldLightViewProjection4;
shared float4x4 WorldLightViewProjection5;
shared float4x4 WorldLightViewProjection6;

shared float3 LightDirection[MAX_TORCHES];
shared float3 LightPosition[MAX_TORCHES];
shared float4 LightColor[MAX_TORCHES];

shared float3 LightPosition0;
shared float3 LightPosition1;
shared float3 LightPosition2;
shared float3 LightPosition3;
shared float3 LightPosition4;
shared float3 LightPosition5;
shared float3 LightPosition6;

shared Texture ShadowMap0;
shared Texture ShadowMap1;
shared Texture ShadowMap2;
shared Texture ShadowMap3;
shared Texture ShadowMap4;
shared Texture ShadowMap5;
shared Texture ShadowMap6;

sampler shadowSampler[MAX_TORCHES] = 
{
	sampler_state
	{
		Texture = <ShadowMap0>;
		
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		
		AddressU = CLAMP;
		AddressV = CLAMP;
	},
	sampler_state
	{
		Texture = <ShadowMap1>;
		
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		
		AddressU = CLAMP;
		AddressV = CLAMP;
	},
	sampler_state
	{
		Texture = <ShadowMap2>;
		
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		
		AddressU = CLAMP;
		AddressV = CLAMP;
	},
	sampler_state
	{
		Texture = <ShadowMap3>;
		
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		
		AddressU = CLAMP;
		AddressV = CLAMP;
	},
	sampler_state
	{
		Texture = <ShadowMap4>;
		
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		
		AddressU = CLAMP;
		AddressV = CLAMP;
	},
	sampler_state
	{
		Texture = <ShadowMap5>;
		
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		
		AddressU = CLAMP;
		AddressV = CLAMP;
	},
	sampler_state
	{
		Texture = <ShadowMap6>;
		
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		
		AddressU = CLAMP;
		AddressV = CLAMP;
	},
};

shared Texture Mask;

sampler maskSampler = sampler_state
{
	Texture = <Mask>;
	
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	
	AddressU = CLAMP;
	AddressV = CLAMP;
};

#endif //_SPOTLIGHTSHADOW_FXH_