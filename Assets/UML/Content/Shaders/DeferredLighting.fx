
texture NormalMap;
texture ColorMap;
texture DepthMap;

sampler NormalSampler = 
sampler_state
{
    Texture = < NormalMap >;
    MipFilter = NONE;
    MinFilter = NONE;
    MagFilter = NONE;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler ColorSampler = 
sampler_state
{
    Texture = < ColorMap >;
    MipFilter = NONE;
    MinFilter = NONE;
    MagFilter = NONE;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler DepthSampler = 
sampler_state
{
    Texture = < DepthMap >;
    MipFilter = NONE;
    MinFilter = NONE;
    MagFilter = NONE;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

struct VertexShaderInput
{
    float3 Position : POSITION0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 ScreenCoords : TEXCOORD0;
};

struct PixelShaderOutput
{
    float4 Diffuse : COLOR0;
    float4 Specular : COLOR1;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output;
    output.Position = float4(input.Position,1);
    output.ScreenCoords = input.Position.xy / 2 + float2(0.5,0.5);
    output.ScreenCoords.y = 1.0 - output.ScreenCoords.y;
    return output;
}

PixelShaderOutput PixelShaderFunction(VertexShaderOutput input)
{
    PixelShaderOutput output;
    
    output.Diffuse = tex2D(ColorSampler, input.ScreenCoords);
    output.Specular = tex2D(NormalSampler, input.ScreenCoords);

    return output;
}

technique LBufferClearTechnique1
{
    pass Pass1
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}

