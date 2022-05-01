#include <Include\\SpotLightShadowShared.fxh>


float4x4 WorldCameraViewProjection;
float4x4 World;

float3 CameraPosition;

float FarClip = 2048;

struct VS_INPUT
{
	float4 Position			: POSITION;
	float4 Normal			: NORMAL;	
	float2 TexCoords		: TEXCOORD0;
};

struct SCENE_VS_OUTPUT
{
	float4 ProjPosition		: POSITION;
};

SCENE_VS_OUTPUT ModelSilhouetteVS (VS_INPUT Input)
{
	SCENE_VS_OUTPUT Output;
	
	Output.ProjPosition = Input.Position;
	Output.ProjPosition = mul(Input.Position, WorldCameraViewProjection);

	return Output;
}

float4 ModelSilhouettePS (SCENE_VS_OUTPUT Input) : COLOR0
{
	return float4(0,0,0,1.0);
}

technique ModelSilhouetteTechnique
{
	pass ModelSilhouetteTechniquePass0
	{
 		VertexShader = compile vs_3_0 ModelSilhouetteVS();
		PixelShader  = compile ps_3_0 ModelSilhouettePS();
	}
}