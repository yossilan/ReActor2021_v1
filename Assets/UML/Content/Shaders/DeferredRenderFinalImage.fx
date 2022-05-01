Texture ColorMap;
Texture DiffuseSpecularMap;
Texture LightScatterMap;

float AmbientLightIntensity = 0.0;
float2 HalfPixel;

sampler ColorSampler = 
sampler_state
{
    Texture = < ColorMap >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler DiffuseSpecularSampler = 
sampler_state
{
    Texture = < DiffuseSpecularMap >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler LightScatterSampler =
sampler_state
{
    Texture = < LightScatterMap >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

struct VertexShaderInput
{
    float4 Position : POSITION;
	float2 TexCoords: TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 ScreenPos : POSITION;
    float2 TexCoords : TEXCOORD0;
};

struct PixelShaderOutput
{
    float4 Color : COLOR0;
};

VertexShaderOutput DeferredRenderFinalImageVS(VertexShaderInput input)
{
    VertexShaderOutput output;

	output.ScreenPos = input.Position;
	output.TexCoords = input.TexCoords + HalfPixel;
    return output;
}

PixelShaderOutput DeferredRenderFinalImagePS(VertexShaderOutput input) 
{
	PixelShaderOutput output;
	
	float4 ambientColor			= float4(tex2D(ColorSampler, input.TexCoords.xy).xyz * AmbientLightIntensity, 0);
	float4 diffuseSpecularColor = tex2D(DiffuseSpecularSampler, input.TexCoords.xy);	
	float lightScatter			= tex2D(LightScatterSampler, input.TexCoords.xy).x;

	output.Color = ambientColor + float4(diffuseSpecularColor.r + lightScatter, diffuseSpecularColor.g + lightScatter, diffuseSpecularColor.b + lightScatter, 1);
	
    return output;
}

technique DeferredRenderFinalImageTechnique
{
    pass DeferredRenderFinalImagePass0
    {
        VertexShader = compile vs_3_0 DeferredRenderFinalImageVS();
        PixelShader = compile ps_3_0 DeferredRenderFinalImagePS();
    }
}
