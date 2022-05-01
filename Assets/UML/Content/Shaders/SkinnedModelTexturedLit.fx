//-----------------------------------------------------------------------------
// SkinnedModel.fx
//-----------------------------------------------------------------------------

#include <include\\SpotLightShadowShared.fxh>
#include <include\\Lighting.fxh>

// Maximum number of bone matrices we can render using shader 2.0 in a single pass.
// If you change this, update SkinnedModelProcessor.cs to match.
#define MaxBones 59

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
    float4 Position		: POSITION0;
    float3 Normal		: NORMAL0;
    float2 TexCoord		: TEXCOORD0;
    float4 BoneIndices	: BLENDINDICES0;
    float4 BoneWeights	: BLENDWEIGHT0;
};


// Vertex shader output structure.
struct VS_OUTPUT
{
    float4 Position			: POSITION0;
	float3 Normal			: NORMAL0;    
    float2 TexCoord			: TEXCOORD0;
	float4 WorldPosition	: TEXCOORD1;
	float4 LocalPosition	: TEXCOORD3;
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
    output.Normal = normalize(mul(mul(input.Normal, skinTransform), World));
    
    // Skin the vertex position.
    float4 position = mul(input.Position, skinTransform);
    if (bExtrude)
    {
		float height = tex2Dlod ( ExtrusionSampler, float4(input.TexCoord.xy , 0 , 0 ) ).r * 20.0f;
    
		float3 extrude = mul(output.Normal, height);
		position += float4(extrude, 0);
	}
    
    output.Position = mul(mul(mul(position, World), View), Projection);

	output.WorldPosition = mul(position, World);
	output.WorldPosition /= output.WorldPosition.w;
	
    output.TexCoord = input.TexCoord;
	
	float4 localPosition = mul(input.Position, skinTransform);
	output.LocalPosition = localPosition;
	
    return output;
}

// Pixel shader program.
float4 PixelShader(VS_OUTPUT input) : COLOR0
{   
   	float noise = tex2D(NoiseSampler, input.TexCoord);
    float4 color = tex2D(Sampler, input.TexCoord);
        
    if (bNoise)
		color = color*0.7 + color*noise*0.3;

    float cumulativeShadow = 0;
    float cumulativeLight = 0; 
    float shadow = 0;
    float3 light = 0;
	float lightDotNorm = 0;
	float3 toTorch = 0;
	
    //color.rgb *= input.Lighting;
    
    float2 ProjectedTexCoords;
    for (int torch=0; torch < NumTorches; torch++)
	{
		toTorch = normalize(LightPosition[torch] - input.WorldPosition);
		lightDotNorm = dot(toTorch, input.Normal);

		shadow = 0.0f;

		if (lightDotNorm >= 0.02)
		{					
			float4 shadowProjection = mul(input.LocalPosition, WorldLightViewProjection[torch]);
			
			ProjectedTexCoords[0] = shadowProjection.x / shadowProjection.w / 2.0f + 0.5f;
			ProjectedTexCoords[1] = -shadowProjection.y / shadowProjection.w / 2.0f + 0.5f;
		    
			float len = length(LightPosition[torch] - input.WorldPosition) / FarClip;
			
			//color = 1.0f - len;
			
			float4 moments = tex2D(shadowSampler[torch], ProjectedTexCoords);
			
  			float E_x2 = moments.y;
			float Ex_2 = moments.x * moments.x;
			float variance = min(max(E_x2 - Ex_2, 0.0) + 0.0001f, 1.0);
			float m_d = (moments.x - len);
			float p = variance / (variance + m_d * m_d);
		    	
			shadow = max(step(len, moments.x), p);
		    
			float4 mask = tex2D(maskSampler, ProjectedTexCoords);
		    
			shadow = shadow * mask.r;

			//cumulativeLight += lightDotNorm * shadow;
			cumulativeLight = saturate(cumulativeLight + lightDotNorm * shadow) * 0.95f;
		}
	}		
   
	return color*float4(AmbientColor,1.0f) + color*cumulativeLight;
}


technique SkinnedModelTexturedLitTechnique
{
    pass SkinnedModelTexturedLitPass
    {
        VertexShader = compile vs_3_0 VertexShader();
        PixelShader = compile ps_3_0 PixelShader();
    }
}
