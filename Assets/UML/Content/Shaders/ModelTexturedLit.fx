#include <Include\\SpotLightShadowShared.fxh>

float3 AmbientColor = 0.05;

float4x4 WorldCameraViewProjection;


float3 CameraPosition;
float4x4 World;

float4 diffuseColour = float4(0.3f, 0.3f, 0.3f, 1.0f);

float FarClip = 2048;
int NumTorches = 1;


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
	float4 ProjPosition		: POSITION;
	float4 Position			: TEXCOORD0;
	float4 WorldPosition	: TEXCOORD1;
	float2 TexCoords		: TEXCOORD2;	
	float4 Normal : TEXCOORD3;
};

SCENE_VS_OUTPUT Scene_VS (VS_INPUT Input)
{
	SCENE_VS_OUTPUT Output;
	
	Output.Position = Input.Position;
	Output.ProjPosition = mul(Input.Position, WorldCameraViewProjection);

	Output.WorldPosition = mul(Input.Position, World);
	Output.WorldPosition /= Output.WorldPosition.w;
	
	Output.TexCoords = Input.TexCoords;
	Output.Normal = normalize(mul(Input.Normal, World));
	
	return Output;
}

float4 Scene_PS (SCENE_VS_OUTPUT Input) : COLOR0
{
    float4 color = tex2D(diffuseSampler, Input.TexCoords);
    
	float2 ProjectedTexCoords;
//	float4 color= diffuseColour;
	float4 worldPosition = mul(Input.Position, World);
	
    float cumulativeShadow = 0;
    float cumulativeLight = 0; 
    float shadow = 0;
    float3 light = 0;
	{
		float4 ShadowProjection;
				
	    for (int torch=0; torch < NumTorches; torch++)
		{		
			float3 toTorch = normalize(LightPosition[torch] - Input.WorldPosition);
			float lightDotNorm = dot(toTorch, Input.Normal);
			
			shadow = 0.0f;
			if (lightDotNorm >= 0)
			{					
				ShadowProjection = mul(Input.Position, WorldLightViewProjection[torch]);
								
				ProjectedTexCoords[0] = ShadowProjection.x / ShadowProjection.w / 2.0f + 0.5f;
				ProjectedTexCoords[1] = -ShadowProjection.y / ShadowProjection.w / 2.0f + 0.5f;
			    
				float len = length(LightPosition[torch] - Input.WorldPosition) / FarClip;
				
				float4 moments = tex2D(shadowSampler[torch], ProjectedTexCoords);
				
  				float E_x2 = moments.y;
				float Ex_2 = moments.x * moments.x;
				float variance = min(max(E_x2 - Ex_2, 0.0) + 0.0001f, 1.0);
				float m_d = (moments.x - len);
				float p = variance / (variance + m_d * m_d);
			    	
				shadow = max(step(len, moments.x), p);
				
				float4 mask = tex2D(maskSampler, ProjectedTexCoords);
			    			    
				shadow = shadow * mask.r;
			}
			else
			{
				lightDotNorm = 0;
			}

			//Assume white light (only need to add dot products)
			//cumulativeLight += (lightDotNorm * LightColor[torch]) * shadow;
			cumulativeLight += lightDotNorm * shadow;

		}
	}
	//color *= float4(AmbientColor,1.0f);
	return color*float4(AmbientColor,1.0f) + color*cumulativeLight;
}

technique ModelTexturedLitTechnique
{
	pass ModelTexturedLitPass0
	{
 		VertexShader = compile vs_3_0 Scene_VS();
		PixelShader  = compile ps_3_0 Scene_PS();
	}
}