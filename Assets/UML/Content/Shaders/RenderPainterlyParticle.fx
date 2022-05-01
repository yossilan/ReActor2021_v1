
//Input variables
float4x4 worldViewProjection;

texture NormalMap;
texture ColorMap;
texture DepthMap;
texture NoiseTexture;
texture PaintBrushTexture;

sampler NormalSampler = 
sampler_state
{
    Texture = < NormalMap >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

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

sampler DepthSampler = 
sampler_state
{
    Texture = < DepthMap >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
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

sampler PaintBrushSampler = 
sampler_state
{
    Texture = < PaintBrushTexture >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

struct VS_INPUT
{
	float4 Position: POSITION;
	float4 Color : Color;
	float2 TexCoords: TEXCOORD0;
};

struct VS_OUTPUT 
{
	float4 Position : POSITION;
	float4 Color : Color;
    float2 TexCoords: TEXCOORD0;    
};

struct PS_OUTPUT 
{
   float4 Color :   COLOR0;
};

VS_OUTPUT SimpleVS(VS_INPUT In)
{
	VS_OUTPUT Out;

    Out.Position = mul(In.Position, worldViewProjection);
    Out.Color = In.Color;
    Out.TexCoords = In.TexCoords;
    
    return Out;
}

PS_OUTPUT SimplePS(VS_OUTPUT input)
{
    PS_OUTPUT Out;
	
	float4 brush = tex2D(PaintBrushSampler, input.TexCoords);
	
	Out.Color = input.Color;
//	Out.Color *= brush.a;
    Out.Color.a = brush.a;

    return Out;
}

//--------------------------------------------------------------//
// Technique Section for Simple screen transform
//--------------------------------------------------------------//
technique Simple
{
   pass Single_Pass
   {      
        VertexShader = compile vs_3_0 SimpleVS();
        PixelShader = compile ps_3_0 SimplePS();                
   }
}