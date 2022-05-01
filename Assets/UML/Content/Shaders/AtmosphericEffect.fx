
//Include for access to shadow maps
#include <include\\SpotLightShadowShared.fxh>

float4x4 World;
float4x4 View;
float4x4 Projection;

float4x4 LightProjection0;
float4x4 LightProjection1;
float4x4 LightProjection2;
float4x4 LightProjection3;
float4x4 LightProjection4;
float4x4 LightProjection5;

float4x4 ViewToLightView0;
float4x4 ViewToLightView1;
float4x4 ViewToLightView2;
float4x4 ViewToLightView3;
float4x4 ViewToLightView4;
float4x4 ViewToLightView5;

float FractionOfMaxLayers = 1.0;
float FarClip = 2048;
int NumTorches = 1;

// TODO: add effect parameters here.

struct VSInput
{
    float4 Position : POSITION0;
    //float LayerFraction : TEXCOORD0;

    // TODO: add input channels such as texture
    // coordinates and vertex colors here.
};

struct VSOutput
{
    float4 Position : POSITION0;
    
    float4 EyePosition : TEXCOORD0;
    float LayerFraction : TEXCOORD1;
    //float4 Light0 : TEXCOORD2;

    // TODO: add vertex shader outputs such as colors and texture
    // coordinates here. These values will automatically be interpolated
    // over the triangle, and provided as input to your pixel shader.
};

VSOutput AtmosphericEffectVS(VSInput input)
{
    VSOutput output;

	output.Position = mul(input.Position, Projection );
	
	output.EyePosition = input.Position;
	output.LayerFraction = 0.0;
	
    return output;
}

float4 AtmosphericEffectPS(VSOutput input) : COLOR0
{
    // TODO: add your pixel shader code here.
    	
    
        //Compute attentuation 1/(s^2)

	float4 shadowProjection = mul(input.EyePosition, LightProjection0);

	float2 ProjectedTexCoords;
	ProjectedTexCoords[0] = shadowProjection.x / shadowProjection.w / 2.0f + 0.5f;
	ProjectedTexCoords[1] = -shadowProjection.y / shadowProjection.w / 2.0f + 0.5f;

	float3 Light0 = mul(input.EyePosition, ViewToLightView0);
	    
	float len = length(Light0) / FarClip;

	float4 moments = tex2D(shadowSampler[0], ProjectedTexCoords);
		
	float E_x2 = moments.y;
	float Ex_2 = moments.x * moments.x;
	float variance = min(max(E_x2 - Ex_2, 0.0) + 0.0001f, 1.0);
	float m_d = (moments.x - len);
	float p = variance / (variance + m_d * m_d);
	    	
	float shadow = max(step(len, moments.x), p);
	    
	float4 mask = tex2D(maskSampler, ProjectedTexCoords);
	    
	
//	if (len < moments.x)
//		shadow = 1.0f;
//	else
//		shadow = 0.0f;
	
	//shadow = shadow * mask.r;

	float intensityAtOrigin = 20000.0;
    float atten = 0.35f + intensityAtOrigin/ dot(Light0.xyz, Light0.xyz);
    float scale = 1.0f / input.LayerFraction;    
    float intensity = atten * shadow * mask.r; 
    //float intensity = scale * atten * shadow * mask.r; 
    
    return float4(intensity,intensity,intensity,0.003);
}

technique AtmosphericEffectTechnique
{
    pass AtmosphericEffectPass0
    {
        // TODO: set renderstates here.
		
        VertexShader = compile vs_3_0 AtmosphericEffectVS();
        PixelShader = compile ps_3_0 AtmosphericEffectPS();
    }
}
