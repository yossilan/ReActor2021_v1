//-----------------------------------------------------------------------------
// SkinnedModel.fx
//
// Skinned model with extrusion vertex shader
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
};

sampler Sketch1Sampler = sampler_state
{
    Texture = (Sketch1Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

sampler Sketch2Sampler = sampler_state
{
    Texture = (Sketch2Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
};

sampler Sketch3Sampler = sampler_state
{
    Texture = (Sketch3Texture);

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
	
    output.Position = mul(mul(position, View), Projection);
	
    return output;
}
const float threshold0 = 0.3f;
const float threshold1 = 0.45f;
const float threshold2 = 0.6f;
const float threshold3 = 0.8f;
const float threshold4 = 0.90f;
const float threshold5 = 1.0f;

const float texfade = 0.05f;

// Pixel shader program.
float4 PixelShader(VS_OUTPUT input) : COLOR0
{
    float cumulativeShadow = 0;
    float cumulativeLight = 0; 
    float shadow = 0;
    float3 light = 0;

    //color.rgb *= input.Lighting;
    
    float2 ProjectedTexCoords;
    for (int torch=0; torch < NumTorches; torch++)
	{
		float3 toTorch = normalize(LightPosition[torch] - input.WorldPosition);
		float lightDotNorm = dot(toTorch, input.Normal);

		shadow = 0.0f;

		if (lightDotNorm >= 0)
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
		
		//Assume white light (only need to add dot products)
		//cumulativeLight += (lightDotNorm * LightColor[torch]) * shadow;
		cumulativeLight += lightDotNorm * shadow;
	}
    float4 color = float4(0.8,0.8f,0.8,0.8f);
    
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
		e = min((cumulativeLight - threshold4) / texfade, 1.0f);
		d = 1.0f - e;		
	}
	
	if (bSketchInvert)
	{
		color = (tex2D(Sketch3Sampler, input.TexCoord) * a) +
				(tex2D(Sketch2Sampler, input.TexCoord) * b) +
				(tex2D(Sketch1Sampler, input.TexCoord) * c) +
				(tex2D(Sketch0Sampler, input.TexCoord) * d);

		color = float4(1.0f-color.r,1.0f-color.g,1.0f-color.b,1.0f);
		//color += float4(1.0f,1.0f,1.0f,0.0f) * e;		

		if (cumulativeLight < threshold0)
		{
			color = float4(0.0f,0.0f,0.0f,1.0f);
		}    		
	}
	else
	{
		color = (tex2D(Sketch3Sampler, input.TexCoord) * a) +
				(tex2D(Sketch2Sampler, input.TexCoord) * b) +
				(tex2D(Sketch1Sampler, input.TexCoord) * c) +
				(tex2D(Sketch0Sampler, input.TexCoord) * d) +
				(float4(1.0f,1.0f,1.0f,1.0f) * e);
	}
	color.a = 1.0f;
    				
	
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
