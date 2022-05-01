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
float4x4 LightSpaceToEyeSpace;

float4x4 EyeSpaceToLightProjectSpace;
float4x4 ProjectSpaceToLightSpace;
float4x4 ProjectSpaceToLightProjectSpace;

float ConeRadius = 1.0;	//Radius of the light cone
float FarClip = 1.0;	
float2 HalfPixel = 0;	//Texel to pixel mapping adjustment
float TanFOVOver2 = 0;	//Tan FOV/2 of camera field of view
float VolumeDepth = 1.0;
float VolumeStart = 0.0;  //Sometimes the volume starts at the near plane
float LightBeamOpacity = 0.5f; //Externally controls the opacity of the light beams

texture Noise;
texture NormalMap;
texture ColorMap;
texture DepthMap;
texture ShadowMap;
texture LightDepthMap;
texture LightDiffuseMap;

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
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler LightDepthSampler = 
sampler_state
{
    Texture = < LightDepthMap >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler LightDiffuseSampler = 
sampler_state
{
    Texture = < LightDiffuseMap >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler NoiseSampler = 
sampler_state
{
    Texture = < Noise >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
};

//-------------------------------------------------------------------------------------
// RENDER LIGHT VOLUME (BACK FACES)
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
    float4 Depth	: COLOR0;
};

VS_OUTPUT RenderDeferredLightVolumeDepthVS(VertexShaderInput input)
{
    VS_OUTPUT output;
    
   	float4 coneVertex = float4( mul(input.PointInLightSpace.xy, ConeRadius), mul(input.PointInLightSpace.z, VolumeDepth),1.0);

    output.Position = mul(coneVertex, LightSpaceToScreenSpace);
    output.PointInLightSpace = coneVertex;

    return output;
}

//Render out the depth of the back faces

PS_OUTPUT RenderDeferredLightVolumeBackFaceDepthPS(VS_OUTPUT input)
{
    PS_OUTPUT output;
    
    float4 projPosition = mul(input.PointInLightSpace, LightSpaceToScreenSpace);
    output.Depth = 0;
    output.Depth.x = projPosition.z / projPosition.w;

    return output;
}

//Render out the depth from the depth buffer (where the light cone intersects other geometry)
PS_OUTPUT RenderDeferredLightVolumeBackFaceIntersectDepthPS(VS_OUTPUT input)
{
    PS_OUTPUT output;
    
    float4 ProjectCoords = mul(input.PointInLightSpace, LightSpaceToScreenSpace);
    
    float4 TexelCoords = (ProjectCoords/ProjectCoords.w) * 0.5 + float4(0.5, 0.5, 0, 0);
    TexelCoords.y = 1.0 - TexelCoords.y;
    TexelCoords += float4(HalfPixel,0,0);

	output.Depth = 0;
    output.Depth.x = tex2D(DepthSampler, TexelCoords).x;

    return output;
}

technique DeferredRenderLightVolumeBackFaceDepthTechnique
{
    pass DeferredRenderLightVolumeBackFaceDepthPass0
    {
        VertexShader = compile vs_3_0 RenderDeferredLightVolumeDepthVS();
        PixelShader = compile ps_3_0 RenderDeferredLightVolumeBackFaceDepthPS();
    }
}

technique DeferredRenderLightVolumeBackFaceIntersectDepthTechnique
{
    pass DeferredRenderLightVolumeBackFaceDepthPass0
    {
        VertexShader = compile vs_3_0 RenderDeferredLightVolumeDepthVS();
        PixelShader = compile ps_3_0 RenderDeferredLightVolumeBackFaceIntersectDepthPS();
    }
}

//-------------------------------------------------------------------------------------
// RENDER LIGHT VOLUME (FRONT FACES)
//-------------------------------------------------------------------------------------


struct DeferredLightVolumePSOutput
{
    float4 Light	: COLOR0;
};

VS_OUTPUT RenderDeferredClippedLightVolumeVS(VertexShaderInput input)
{
    VS_OUTPUT output;
    
   	float4 coneVertex = float4( mul(input.PointInLightSpace.xy, ConeRadius), mul(input.PointInLightSpace.z, VolumeDepth),1.0);

	float4 eyePosition = mul(coneVertex, LightSpaceToEyeSpace);
	    
    if (eyePosition.z > -VolumeStart)
    {
		eyePosition.z = -VolumeStart;
    }
        
    output.Position = mul(eyePosition, Projection);
    output.PointInLightSpace = coneVertex;

    return output;
}

VS_OUTPUT RenderDeferredLightVolumeVS(VertexShaderInput input)
{
    VS_OUTPUT output;
    
   	float4 coneVertex = float4( mul(input.PointInLightSpace.xy, ConeRadius), mul(input.PointInLightSpace.z, VolumeDepth),1.0);

    output.Position = mul(coneVertex, LightSpaceToScreenSpace);
    output.PointInLightSpace = coneVertex;

    return output;
}


float getVSMShadow(float3 lightSpacePosition, float normDToLight)
{
	float4 shadowProjection = mul(float4(lightSpacePosition,1), LightProjection);
		
	float2 ShadowTexCoords = 0;
	ShadowTexCoords[0] = shadowProjection.x / shadowProjection.w / 2.0f + 0.5f;
	ShadowTexCoords[1] = -shadowProjection.y / shadowProjection.w / 2.0f + 0.5f;

	float shadow = 0.0;
	float4 moments = tex2D(ShadowSampler, ShadowTexCoords);
			
	float E_x2 = moments.y;
	float Ex_2 = moments.x * moments.x;
	float variance = min(max(E_x2 - Ex_2, 0.0) + 0.0001f, 1.0);
	float m_d = (moments.x - normDToLight);
	float p = variance / (variance + m_d * m_d);
			    	
	shadow = max(step(normDToLight, moments.x), p);
				
	float4 mask = tex2D(maskSampler, ShadowTexCoords);
	
	return shadow * mask;
}
		
float getShadow(float3 lightSpacePosition, float normDToLight)
{
	float4 shadowProjection = mul(float4(lightSpacePosition,1), LightProjection);
		
	float2 ShadowTexCoords = 0;
	ShadowTexCoords[0] = shadowProjection.x / shadowProjection.w / 2.0f + 0.5f;
	ShadowTexCoords[1] = -shadowProjection.y / shadowProjection.w / 2.0f + 0.5f;

	float4 moments = tex2D(ShadowSampler, ShadowTexCoords);			
				
	return step(normDToLight, moments.y) * tex2D(maskSampler, ShadowTexCoords).x;
}

float getLightMask(float3 lightSpacePosition)
{
	float4 shadowProjection = mul(float4(lightSpacePosition,1), LightProjection);
		
	float2 ShadowTexCoords = 0;
	ShadowTexCoords[0] = shadowProjection.x / shadowProjection.w / 2.0f + 0.5f;
	ShadowTexCoords[1] = -shadowProjection.y / shadowProjection.w / 2.0f + 0.5f;

	return tex2D(maskSampler, ShadowTexCoords).x;
}

//More samples when rendering shadows
const int ShadowSteps = 30;
const float fShadowSteps = 30.0f;

const int steps = 10;
const float fSteps = 10.0f;

const float intensityPerUnitLength = 50;

float3 NoiseTextureOffset = float3(0,0,0);

// Renders light volume without shadows but for the moment the branch in this shader causes 
// it to be slower than if you ran the shadow every time

DeferredLightVolumePSOutput RenderDeferredLightVolumePS(VS_OUTPUT input)
{
    DeferredLightVolumePSOutput output;
    
    float4 projectCoords = mul(input.PointInLightSpace, LightSpaceToScreenSpace);
    
    float4 texelCoords = (projectCoords/projectCoords.w) * 0.5 + float4(0.5, 0.5, 0, 0);
    texelCoords.y = 1.0 - texelCoords.y;
    texelCoords += float4(HalfPixel,0,0);

	float depth = tex2D(LightDepthSampler, texelCoords).x;

    //transform from project space to light space
    float4 projectedPixelPosition;
    projectedPixelPosition.x = projectCoords.x/projectCoords.w;
    projectedPixelPosition.y = projectCoords.y/projectCoords.w;
    projectedPixelPosition.z = depth;
    projectedPixelPosition.w = 1.0f;
                
    float4 lightPixelPosition = mul(projectedPixelPosition, ProjectSpaceToLightSpace);
    lightPixelPosition /= lightPixelPosition.w;

    float3 eyeRay =  lightPixelPosition.xyz - input.PointInLightSpace.xyz;
    float eyeRayLength = length(eyeRay);    
	
	//Accumulate intensity along the ray
	//Lets take a fixed number of samples for now, starting from the back
	float3 rayStep = (eyeRay.xyz / fSteps);
    float rayStepLengthOver2 = eyeRayLength / (2.0*fSteps);
	
	float3 currentPosOnRay = input.PointInLightSpace.xyz;
	float dToLightSquared = dot(currentPosOnRay.xyz, currentPosOnRay.xyz); 
	float dToLight = length(currentPosOnRay);
	
	float currentIntensity = ((intensityPerUnitLength * LightBeamOpacity) / dToLightSquared) * getLightMask(currentPosOnRay);
	float nextIntensity = 0.0;
	float accIntensity = currentIntensity;
	
	float dropOff = 1.0f;
	
	for (int i=0; i < steps; i++)
	{
		currentPosOnRay += rayStep;
						
		dToLightSquared = dot(currentPosOnRay.xyz, currentPosOnRay.xyz);
			
		nextIntensity = ((intensityPerUnitLength * LightBeamOpacity) / dToLightSquared);
					
		accIntensity += rayStepLengthOver2 * (currentIntensity + nextIntensity) * getLightMask(currentPosOnRay);
			
		currentIntensity = nextIntensity;			
	}
	
	output.Light = float4(accIntensity, accIntensity, accIntensity, 0.1);

	return output;
}
	
DeferredLightVolumePSOutput RenderDeferredLightVolumeWithShadowsPS(VS_OUTPUT input)
{
    DeferredLightVolumePSOutput output;
    
    float4 projectCoords = mul(input.PointInLightSpace, LightSpaceToScreenSpace);
    
    float4 texelCoords = (projectCoords/projectCoords.w) * 0.5 + float4(0.5, 0.5, 0, 0);
    texelCoords.y = 1.0 - texelCoords.y;
    texelCoords += float4(HalfPixel,0,0);

	float depth = tex2D(LightDepthSampler, texelCoords).x;

    //transform from project space to light space
    float4 position;
    position.x = projectCoords.x/projectCoords.w;
    position.y = projectCoords.y/projectCoords.w;
    position.z = depth;
    position.w = 1.0f;
                
    float4 lightPixelPosition = mul(position, ProjectSpaceToLightSpace);
    lightPixelPosition /= lightPixelPosition.w;

    float3 eyeRay =  lightPixelPosition.xyz - input.PointInLightSpace.xyz;
    float eyeRayLength = length(eyeRay);

	//Accumulate intensity along the ray
	//Lets take a fixed number of samples for now, starting from the back
	float3 rayStep = (eyeRay.xyz / fShadowSteps);
    float rayStepLengthOver2 = eyeRayLength / (2.0*fShadowSteps);
	
	float3 currentPosOnRay = input.PointInLightSpace.xyz;
	float dToLight = length(currentPosOnRay);
	float dToLightEnd = length(lightPixelPosition);
//	float normDToLight = dToLight / FarClip;
	float normDToLightSqrd =  dToLight * dToLight / (FarClip * FarClip);
	
	float currentIntensity = ((intensityPerUnitLength * LightBeamOpacity) / (dToLight *dToLight)) * getShadow(currentPosOnRay, normDToLightSqrd);
	float nextIntensity = 0.0;
	float accIntensity = currentIntensity;

	float dToLightSquared = 0; 
	
	//Do we need to check for shadows in this ray
	for (int i=0; i<ShadowSteps; i++)
	{
		currentPosOnRay += rayStep;
		
		dToLightSquared = dot(currentPosOnRay.xyz, currentPosOnRay.xyz);
			
		float noiseValue = 0.5 + tex2D(NoiseSampler, (currentPosOnRay + NoiseTextureOffset)/128)*0.5;
		normDToLightSqrd =  dToLightSquared / (FarClip * FarClip);
		nextIntensity = ((intensityPerUnitLength * LightBeamOpacity) / dToLightSquared) * getShadow(currentPosOnRay, normDToLightSqrd)*noiseValue;
					
		accIntensity += rayStepLengthOver2 * (currentIntensity + nextIntensity);
			
		currentIntensity = nextIntensity;			
	}

	output.Light = float4(accIntensity, accIntensity, accIntensity, 0.1);

	return output;
}
	
technique DeferredRenderLightVolumeTechnique
{
    pass DeferredRenderLightVolumePass0
    {
        VertexShader = compile vs_3_0 RenderDeferredLightVolumeVS();
        PixelShader = compile ps_3_0 RenderDeferredLightVolumePS();
    }
}

technique DeferredRenderLightVolumeWithShadowsTechnique
{
    pass DeferredRenderLightVolumeWithShadowsPass0
    {
        VertexShader = compile vs_3_0 RenderDeferredLightVolumeVS();
        PixelShader = compile ps_3_0 RenderDeferredLightVolumeWithShadowsPS();
    }
}

technique DeferredRenderClippedLightVolumeWithShadowsTechnique
{
    pass DeferredRenderClippedLightVolumeWithShadowsPass0
    {
        VertexShader = compile vs_3_0 RenderDeferredClippedLightVolumeVS();
        PixelShader = compile ps_3_0 RenderDeferredLightVolumeWithShadowsPS();
    }
}
