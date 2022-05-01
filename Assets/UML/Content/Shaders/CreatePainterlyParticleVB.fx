
//Input variables
//float4x4 worldViewProjection;
float4x4 InvertViewProjection;

texture NormalMap;
texture ColorMap;
texture DepthMap;
texture NoiseTexture;

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

struct VS_INPUT
{
    float4 ObjectPos: POSITION;
};

struct VS_OUTPUT 
{
   float4 ScreenPos : POSITION;
   float4 ScreenPosCopy : TEXCOORD0;
   float2 TextureCoords:	TEXCOORD1;
};

struct PS_OUTPUT 
{
   vector<float, 4> ColorAndDepth:   COLOR0;
};

VS_OUTPUT SimpleVS(VS_INPUT In)
{
	VS_OUTPUT Out;

	//The verts are already in screen space, no projection required
    Out.ScreenPos = In.ObjectPos;
    Out.ScreenPosCopy = In.ObjectPos;
    Out.ScreenPosCopy.w = 1.0f;
    
    //Convert screen coordinates to texture coordinated
    Out.TextureCoords.x = (In.ObjectPos.x + 1.0) / 2.0;
    Out.TextureCoords.y = (In.ObjectPos.y + 1.0) / 2.0;
    
    return Out;
}

PS_OUTPUT SimplePS(VS_OUTPUT input)
{
    PS_OUTPUT Out;


	Out.ColorAndDepth = tex2D(ColorSampler, input.TextureCoords.xy);
    
	// If we get a black pixel it's not a character so don't generate a coordinate.  Assign -1 for primIndex    
    if (Out.ColorAndDepth.r == 0 && Out.ColorAndDepth.g == 0 && Out.ColorAndDepth.b == 0)
    {
		Out.ColorAndDepth.a = -1.0f;
    }
    else
    {
	    //Store the primitive Index in the alpha component
		Out.ColorAndDepth.a = tex2D(DepthSampler, input.TextureCoords.xy).r;

//		float4 worldPosition=0;
//		worldPosition.x = input.ScreenPosCopy.x;
//		worldPosition.y = input.ScreenPosCopy.y;
//		worldPosition.z = tex2D(DepthSampler, input.TextureCoords.xy);
//		worldPosition.w = 1.0f;

		//transform to world space
//		Out.WorldPosition = mul(worldPosition, InvertViewProjection);
//		Out.WorldPosition /= worldPosition.w;
    }
    
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