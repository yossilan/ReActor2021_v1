//-----------------------------------------------------------------------------
// SkinnedModel.fx
//-----------------------------------------------------------------------------


// Maximum number of bone matrices we can render using shader 2.0 in a single pass.
// If you change this, update SkinnedModelProcessor.cs to match.
#define MaxBones 59

// Input parameters.
float4x4 World;
float4x4 View;
float4x4 Projection;

float4x4 Bones[MaxBones];

texture Texture;

sampler Sampler = sampler_state
{
    Texture = (Texture);

    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
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
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
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
    
    // Skin the vertex position.
    float4 position = mul(input.Position, skinTransform);    
    output.Position = mul(mul(mul(position, World), View), Projection);

    output.TexCoord = input.TexCoord;
	
    return output;
}

// Pixel shader program.
float4 PixelShader(VS_OUTPUT input) : COLOR0
{   
    float4 color = tex2D(Sampler, input.TexCoord);
    
	return color;
}


technique SkinnedModelBasicRenderTechnique
{
    pass SkinnedModelPass
    {
        VertexShader = compile vs_2_0 VertexShader();
        PixelShader = compile ps_2_0 PixelShader();
    }
}
