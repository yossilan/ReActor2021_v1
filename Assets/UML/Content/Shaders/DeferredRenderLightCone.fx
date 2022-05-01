#include <include\\SpotLightShadowShared.fxh>
#include <include\\Lighting.fxh>

// Input parameters.
float4x4 World;
float4x4 View;
float4x4 Projection;
float4x4 InvertWorldViewProjection;
float4x4 InvertViewProjection;
float4x4 InvertProjection;

float4x4 LightView;
float4x4 LightProjection;
float4x4 LightSpaceToScreenSpace;

float4x4 EyeSpaceToLightProjectSpace;

float3 WorldCameraPosition=0;
float3 WorldLightPosition=0;
float3 WorldLightDirection=0;

float ScreenWidthOver2InWorldSpace=0;
float ScreenHeightOver2InWorldSpace=0;

float ConeRadius = 1.0;	//Radius of the light cone
float FarClip = 1.0;	
float2 HalfPixel = 0;	//Texel to pixel mapping adjustment
float TanFOVOver2 = 0;	//Tan FOV/2 of camera field of view
float FrustumDepth = 1.0;
float LightIntensity = 1.0;
int EmissiveShadows = 1;  //Basically whether or not to cast shadows onto the video screen which are considered as light emitters



texture NormalMap;
texture ColorMap;
texture DepthMap;
texture ShadowMap;

sampler NormalSampler = 
sampler_state
{
    Texture = < NormalMap >;
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
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

sampler ShadowSampler =
sampler_state
{
    Texture = < ShadowMap >;
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
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

//-------------------------------------------------------------------------------------
// RENDER LIGHT FULL SCREEN
//-------------------------------------------------------------------------------------

struct VertexShaderInputFullScreen
{
    float4 Position : POSITION0;
    float2 TexCoord	: TEXCOORD0;
};
struct VertexShaderOutputFullScreen
{
    float4 Position : POSITION0;
    float2 ScreenCoords: TEXCOORD0;
};

struct PixelShaderOutputFullScreen
{
    float4 Depth    : COLOR0;
    float4 Diffuse	: COLOR1;
    float4 Specular : COLOR2;
};

VertexShaderOutputFullScreen RenderLightFullScreenVS(VertexShaderInputFullScreen input)
{
    VertexShaderOutputFullScreen output;
    
    output.Position = input.Position;
    output.ScreenCoords.xy = input.Position.xy;

    return output;
}

PixelShaderOutputFullScreen RenderLightFullScreenPS(VertexShaderOutputFullScreen input)
{
    PixelShaderOutputFullScreen output;
    
    float4 TexelCoords = float4(input.ScreenCoords,0,0) * 0.5 + float4(0.5, 0.5, 0, 0);
    TexelCoords.y = 1.0 - TexelCoords.y;
    TexelCoords += float4(HalfPixel,0,0);

    //Retrieve normal for pixel and transform into lightspace
    float4 normalSample = tex2D(NormalSampler, TexelCoords);
    float3 normal = 2 * (normalSample.xyz - float3(0.5,0.5,0.5));
    float specularPower = normalSample.w;
    
    //Calculate distance from light
    float depth = tex2D(DepthSampler, TexelCoords).x;
    
    //Record the depth in the light volume depth buffer
    output.Depth = float4(depth,0,0,0);

    //compute screen-space position
    float4 position;
    position.x = input.ScreenCoords.x;
    position.y = input.ScreenCoords.y;
    position.z = depth;
    position.w = 1.0f;
                
    //transform to world space
    float4 worldPixelPosition = mul(position, InvertViewProjection);
    
    float lightSpaceDepth = length((worldPixelPosition/worldPixelPosition.w).xyz - WorldLightPosition.xyz);    
    float normLightSpaceDepth = lightSpaceDepth/FarClip;
    
    float4 lightSpaceProjection = mul(mul(worldPixelPosition,LightView),LightProjection);    
    
    float2 ProjectedLightCoords = 0;
	ProjectedLightCoords[0] = lightSpaceProjection.x / lightSpaceProjection.w / 2.0f + 0.5f;
	ProjectedLightCoords[1] = -lightSpaceProjection.y / lightSpaceProjection.w / 2.0f + 0.5f;
	
    float mask = tex2D(maskSampler, ProjectedLightCoords);       
	float4	moments = tex2D(ShadowSampler, ProjectedLightCoords);
			
	float E_x2 = moments.y;
	float Ex_2 = moments.x * moments.x;
	float variance = min(max(E_x2 - Ex_2, 0.0) + 0.0001f, 1.0);
	float m_d = (moments.x - normLightSpaceDepth);
	float p = variance / (variance + m_d * m_d);    	
    
	float shadow = max(step(normLightSpaceDepth, moments.x), p);
	
    //Calculate light attenutation by extracting the depth
    float attenuation = (100000.0 * LightIntensity) / (lightSpaceDepth * lightSpaceDepth);
    
   	float3 toEyeNormal = normalize(WorldCameraPosition.xyz - worldPixelPosition.xyz);
   	
   	//Extract diffuse color and specular power from the color map
   	float4 colorSample = tex2D(ColorSampler, TexelCoords.xy).rbga;
   	float3 diffuseColor = colorSample.rgb;
   	   	
    float4 intensity =	attenuation * mask * shadow *
						( 
							LambertDiffuse(WorldLightDirection, normal) +
							PhongSpecular(WorldLightDirection, normal, toEyeNormal, specularPower)
						);

    
    output.Diffuse = 0;
    output.Diffuse.rgb = tex2D(ColorSampler, TexelCoords.xy).xyz * intensity;
    output.Diffuse.a = 0.01;
    output.Specular.rgb = 0.5;
    output.Specular.a = 1.0;

    return output;
}


//-------------------------------------------------------------------------------------
// RENDER LIGHT CONE
//-------------------------------------------------------------------------------------


struct VertexShaderInput
{
    float4 PointInLightSpace : POSITION0;
    float2 TexCoord			 : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position			 : POSITION0;
    float4 PointInLightSpace : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4 Depth    : COLOR0;
    float4 Diffuse	: COLOR1;
    float4 Specular : COLOR2;
};

VS_OUTPUT RenderLightConeVS(VertexShaderInput input)
{
    VS_OUTPUT output;
    
   	float4 coneVertex = float4( mul(input.PointInLightSpace.xy, ConeRadius), mul(input.PointInLightSpace.z, FrustumDepth),1.0);

    output.Position = mul(coneVertex, LightSpaceToScreenSpace);
    output.PointInLightSpace = coneVertex;

    return output;
}

PS_OUTPUT RenderLightConePS(VS_OUTPUT input)
{
    PS_OUTPUT output;
       
    float4 ProjectCoords = mul(input.PointInLightSpace, LightSpaceToScreenSpace);
    
    float4 TexelCoords = (ProjectCoords/ProjectCoords.w) * 0.5 + float4(0.5, 0.5, 0, 0);
    TexelCoords.y = 1.0 - TexelCoords.y;
    TexelCoords += float4(HalfPixel,0,0);

    //Retrieve normal for pixel and transform into lightspace
    float4 normalSample = tex2D(NormalSampler, TexelCoords);
    float3 normal = 2 * (normalSample.xyz - float3(0.5,0.5,0.5));
    float specularPower = normalSample.w;
    
    //Calculate distance from light
    float depth = tex2D(DepthSampler, TexelCoords).x;
    
    //Record the depth in the light volume depth buffer
    output.Depth = float4(depth,0,0,0);
    
    //compute screen-space position
    float4 position;
    position.x = ProjectCoords.x/ProjectCoords.w;
    position.y = ProjectCoords.y/ProjectCoords.w;
    position.z = depth;
    position.w = 1.0f;
        
    //transform to world space
    float4 worldPixelPosition = mul(position, InvertViewProjection);
    
    float lightSpaceDepth = length((worldPixelPosition/worldPixelPosition.w).xyz - WorldLightPosition.xyz);    
    float normLightSpaceDepth = lightSpaceDepth/FarClip;
    
    float4 lightSpaceProjection = mul(mul(worldPixelPosition,LightView),LightProjection);    
    
    float2 ProjectedLightCoords = 0;
	ProjectedLightCoords[0] = lightSpaceProjection.x / lightSpaceProjection.w / 2.0f + 0.5f;
	ProjectedLightCoords[1] = -lightSpaceProjection.y / lightSpaceProjection.w / 2.0f + 0.5f;

    float mask = tex2D(maskSampler, ProjectedLightCoords);       
	float4	moments = tex2D(ShadowSampler, ProjectedLightCoords);
			
	float E_x2 = moments.y;
	float Ex_2 = moments.x * moments.x;
	float variance = min(max(E_x2 - Ex_2, 0.0) + 0.0001f, 1.0);
	float m_d = (moments.x - normLightSpaceDepth);
	float p = variance / (variance + m_d * m_d);    	
    
	float shadow = max(step(normLightSpaceDepth, moments.x), p);
	
    //Calculate light attenutation by extracting the depth
    float attenuation = (100000.0 * LightIntensity) / (lightSpaceDepth * lightSpaceDepth);
    
   	float3 toEyeNormal = normalize(WorldCameraPosition.xyz - worldPixelPosition.xyz);
   	
    float4 intensity =	saturate
						( 
									attenuation * mask * shadow *
									( 
										LambertDiffuse(WorldLightDirection, normal) +
										BlinnPhongSpecular(WorldLightDirection, normal, toEyeNormal, specularPower)
									)
						);

    float4 color = tex2D(ColorSampler, TexelCoords.xy);
    float emissive = color.a * mask;
    if (EmissiveShadows)
		emissive *= shadow;
    
    output.Diffuse = 0;
    output.Diffuse.rgb = saturate(color.xyz * emissive + color.xyz * intensity.xyz);
    output.Diffuse.a = 0.01;
    
    //TODO: Do we need a specular buffer
    output.Specular.rgb = 0.0;
    output.Specular.a = 0.0;

    return output;
}

technique DeferredRenderLightConeTechnique
{
    pass DeferredRenderLightConePass0
    {
        VertexShader = compile vs_3_0 RenderLightConeVS();
        PixelShader = compile ps_3_0 RenderLightConePS();
    }
}

technique DeferredRenderLightFullScreenTechnique
{
    pass DeferredRenderLightFullScreenPass0
    {
        VertexShader = compile vs_3_0 RenderLightFullScreenVS();
        PixelShader = compile ps_3_0 RenderLightFullScreenPS();
    }
}
