
//Input variables
float4x4 worldViewProjection;

texture VideoTexture;

sampler VideoSampler = 
sampler_state
{
    Texture = < VideoTexture >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};
struct VS_INPUT
{
	float4 Position: POSITION;
	float2 TexCoords: TEXCOORD0;
};

struct VS_OUTPUT 
{
	float4 Position : POSITION;
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
    Out.TexCoords = In.TexCoords;
    
    return Out;
}

PS_OUTPUT SimplePS(VS_OUTPUT input)
{
    PS_OUTPUT Out;
	
	Out.Color  = tex2D(VideoSampler, input.TexCoords);
	
//	Out.Color *= 0.5;
	
	Out.Color.a = 1.0;
	
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