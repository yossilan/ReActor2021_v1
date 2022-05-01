//Render a textured model (unskinned) with no shading, just diffuse texture.

float4x4 WorldCameraViewProjection;

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
	float4 Normal			: NORMAL;	
	float2 TexCoords		: TEXCOORD0;
};

struct SCENE_VS_OUTPUT
{
	float4 Position		: POSITION;
	float2 TexCoords    : TEXCOORD0;
};

SCENE_VS_OUTPUT ModelBasicRenderVS (VS_INPUT Input)
{
	SCENE_VS_OUTPUT Output;
	
	Output.Position = mul(Input.Position, WorldCameraViewProjection);
	Output.TexCoords = Input.TexCoords;

	return Output;
}

float4 ModelBasicRenderPS (SCENE_VS_OUTPUT Input) : COLOR0
{
    return tex2D(diffuseSampler, Input.TexCoords);
}

technique ModelBasicRenderTechnique
{
	pass ModelBasicRenderPass0
	{
 		VertexShader = compile vs_2_0 ModelBasicRenderVS();
		PixelShader  = compile ps_2_0 ModelBasicRenderPS();
	}
}