//-----------------------------------------------------------------------------
// SkinnedModel.fx
//
// Skinned model with an image space sketch shader
//
//-----------------------------------------------------------------------------

#include <include\\SpotLightShadowShared.fxh>

// Maximum number of bone matrices we can render using shader 2.0 in a single pass.
// If you change this, update SkinnedModelProcessor.cs to match.
#define MaxBones 59

shared bool bLit = false;
shared bool bSketchInvert = false;
shared bool bExtrude = false;

int NumTorches = 6;

// Input parameters.
float4x4 World;
float4x4 View;
float4x4 Projection;

//We have 8 fixed position spotlights
float3 CameraPosition;

float FarClip = 2048;

float4x4 Bones[MaxBones];

float3 AmbientColor = 0.1;

texture Texture;
texture Extrusion;


sampler Sampler = sampler_state
{
    Texture = (Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
	ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;    
};

sampler ExtrusionSampler = sampler_state
{
    Texture = (Extrusion);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

texture Sketch0Texture;
texture Sketch1Texture;
texture Sketch2Texture;
texture Sketch3Texture;

sampler Sketch0Sampler = sampler_state
{
    Texture = (Sketch0Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
	ADDRESSU = WRAP;
    ADDRESSV = WRAP;    
};

sampler Sketch1Sampler = sampler_state
{
    Texture = (Sketch1Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
	ADDRESSU = WRAP;
    ADDRESSV = WRAP;    
};

sampler Sketch2Sampler = sampler_state
{
    Texture = (Sketch2Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
	ADDRESSU = WRAP;
    ADDRESSV = WRAP;    
};

sampler Sketch3Sampler = sampler_state
{
    Texture = (Sketch3Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
	ADDRESSU = WRAP;
    ADDRESSV = WRAP;    
};


// Vertex shader input structure.
struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 BoneIndices : BLENDINDICES0;
    float4 BoneWeights : BLENDWEIGHT0;
};


// Vertex shader output structure.
struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
	float4 WorldPosition	: TEXCOORD1;
	float3 Normal : TEXCOORD2;
	float4 LocalPosition	: TEXCOORD3;
};

struct PS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
	float4 WorldPosition	: TEXCOORD1;
	float3 Normal : TEXCOORD2;
	float4 LocalPosition	: TEXCOORD3;
	float2 Screen  : VPOS; 
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
		float height = tex2Dlod ( ExtrusionSampler, float4(input.TexCoord.xy , 0 , 0 ) ) * 20.0f;
    
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
const float threshold0 = 0.1f;
const float threshold1 = 0.4f;
const float threshold2 = 0.5f;
const float threshold3 = 0.72f;
const float threshold4 = 1.0f;
const float threshold5 = 1.0f;

const float texfade = 0.15f;

// Pixel shader program.
float4 PixelShader(PS_INPUT input) : COLOR0
{
    float cumulativeShadow = 0;
    float cumulativeLight = 0; 
    float shadow = 0;
    float3 light = 0;
	float4 color = tex2D(Sampler, input.TexCoord);

    //color.rgb *= input.Lighting;
    
    float2 ProjectedTexCoords;
    for (int torch=0; torch < NumTorches; torch++)
	{
		float3 toTorch = normalize(LightPosition[torch] - input.WorldPosition);
		float lightDotNorm = dot(toTorch, input.Normal);

		shadow = 0.0f;

		if (lightDotNorm > 0)
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
		}
		else
		{
			shadow = 0;
		}
		
		//Assume white light (only need to add dot products)
		cumulativeLight += lightDotNorm * shadow;
	}
    
    //Parametric texture multipliers
    float a=0,b=0,c=0,d=0,e=0;		
    
	if (cumulativeLight >= threshold0 && cumulativeLight < threshold1)
    {
		a = min((cumulativeLight - threshold0) / texfade, 1.0f);
	}	 
    else if (cumulativeLight >= threshold1 && cumulativeLight < threshold2)
    {
		b = min((cumulativeLight - threshold1) / texfade, 1.0f);
		a = 1.0f - b;
	}
    else if (cumulativeLight >= threshold2 && cumulativeLight < threshold3)
    {
		c = min((cumulativeLight - threshold2) / texfade, 1.0f);
		b = 1.0f - c;
	}
    else if (cumulativeLight >= threshold3 && cumulativeLight < threshold4)
    {
		d = min((cumulativeLight - threshold3) / texfade, 1.0f);
		c = 1.0f - d;
	}
    else if (cumulativeLight >= threshold4)
    {
		e = 0.0f;
		e = min((cumulativeLight - threshold4) / texfade, 1.0f);
		d = 1.0f - e;		
	}
	    
	if (bLit)
	{
		float2 texCoord = float2(input.Screen.x/64, input.Screen.y/64);

		float4 colora = tex2D(Sketch0Sampler, texCoord);
		float4 colorb = tex2D(Sketch1Sampler, texCoord);
		float4 colorc = tex2D(Sketch2Sampler, texCoord);
		float4 colord = tex2D(Sketch3Sampler, texCoord);
		float4 color1 = 0;

		color1 =(tex2D(Sketch3Sampler, texCoord) * a) +
				(tex2D(Sketch2Sampler, texCoord) * b) +
				(tex2D(Sketch1Sampler, texCoord) * c) +
				(tex2D(Sketch0Sampler, texCoord) * d);

		color1 = (float4(1.0f-colora.r, 1.0f-colora.r, 1.0f-colora.b,1.0f)*a) +
				(float4(1.0f-colorb.r, 1.0f-colorb.r, 1.0f-colorb.b,1.0f)*b) +
				(float4(1.0f-colorc.r, 1.0f-colorc.r, 1.0f-colorc.b,1.0f)*c) +
				(float4(1.0f-colord.r, 1.0f-colord.r, 1.0f-colord.b,1.0f)*d) +
				(float4(1.0f,1.0f,1.0f,1.0f) * e);
				
		color = tex2D(Sampler, input.TexCoord);
		
		//color = float4(color.r*color1.r, color.g*color1.g, color.b*color1.b, 1.0f);
		color = color1;
	}
	else
	{
		if (bSketchInvert)
		{
			float2 texCoord = float2(input.Screen.x/64, input.Screen.y/64);

			float4 colora = tex2D(Sketch0Sampler, texCoord);
			float4 colorb = tex2D(Sketch1Sampler, texCoord);
			float4 colorc = tex2D(Sketch2Sampler, texCoord);
			float4 colord = tex2D(Sketch3Sampler, texCoord);
			float4 color1 = 0;

			color =(tex2D(Sketch3Sampler, texCoord) * a) +
					(tex2D(Sketch2Sampler, texCoord) * b) +
					(tex2D(Sketch1Sampler, texCoord) * c) +
					(tex2D(Sketch0Sampler, texCoord) * d);

			color1 = (float4(1.0f-colora.r, 1.0f-colora.r, 1.0f-colora.b,1.0f)*a) +
					(float4(1.0f-colorb.r, 1.0f-colorb.r, 1.0f-colorb.b,1.0f)*b) +
					(float4(1.0f-colorc.r, 1.0f-colorc.r, 1.0f-colorc.b,1.0f)*c) +
					(float4(1.0f-colord.r, 1.0f-colord.r, 1.0f-colord.b,1.0f)*d) +
					(float4(1.0f,1.0f,1.0f,1.0f) * e);
					
			color = tex2D(Sampler, input.TexCoord);
			
			color = float4(color.r*color1.r, color.g*color1.g, color.b*color1.b, 1.0f);
		}
		else
		{
			float2 texCoord = float2(input.Screen.x/64, input.Screen.y/64);

			float4 colora = tex2D(Sketch0Sampler, texCoord);
			float4 colorb = tex2D(Sketch1Sampler, texCoord);
			float4 colorc = tex2D(Sketch2Sampler, texCoord);
			float4 colord = tex2D(Sketch3Sampler, texCoord);
			float4 color1 = 0;

			color1 =((tex2D(Sketch3Sampler, texCoord) * a) +
					(tex2D(Sketch2Sampler, texCoord) * b) +
					(tex2D(Sketch1Sampler, texCoord) * c) +
					(tex2D(Sketch0Sampler, texCoord) * d) +
					(float4(1.0f,1.0f,1.0f,1.0f) * e));
					
			color = tex2D(Sampler, input.TexCoord);
			
			color = float4(color.r*color1.r, color.g*color1.g, color.b*color1.b, 1.0f);
		}
	}    				
	
	if (bLit)   
		return color*float4(AmbientColor,1.0f) + color*cumulativeLight;
	else
		return color;
}


technique SkinnedModelSketchTechnique
{
    pass SkinnedModelPass
    {
        VertexShader = compile vs_3_0 VertexShader();
        PixelShader = compile ps_3_0 PixelShader();
    }
}
