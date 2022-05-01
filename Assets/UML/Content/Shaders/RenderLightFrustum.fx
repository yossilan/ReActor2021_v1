
//Input variables
float4x4 LightSpaceToScreenSpace;  //From Lightspace to view then project
float4x4 ScreenSpaceToLightSpace;
float4x4 LightProjection;

float3 LightSpaceViewerPosition;				

float ConeRadius = 0.0f;
float MaxDistanceToPointOnConeSurface = 0.0f;
float FarClip = 2048.0f;
float CosConeAngle = 0;

Texture ShadowMap;

struct VS_INPUT
{
	float4 PointInLightPos: POSITION0;		
	float2 PointOnLightCone: TEXCOORD0;	// x = rotation about z axis: y = 
};

struct VS_OUTPUT 
{
	float4 ScreenPos: POSITION0;
	float2 PointOnLightCone: TEXCOORD0;
//	float3 RayDirection: TEXCOORD1;		
//	float4 Color: COLOR;
};

struct PS_OUTPUT 
{
   float4 Color:   COLOR;
};

sampler shadowMapSampler = 
{
	sampler_state
	{
		Texture = <ShadowMap>;
		
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		
		AddressU = CLAMP;
		AddressV = CLAMP;
	}
};

VS_OUTPUT RenderLightFrustumVS(VS_INPUT In)
{
	VS_OUTPUT Out;

	float4 coneVertex = float4(mul(In.PointInLightPos.xy, ConeRadius), In.PointInLightPos.zw);
	
	Out.ScreenPos = mul(coneVertex, LightSpaceToScreenSpace);
	Out.ScreenPos /= Out.ScreenPos.w;
	
	Out.PointOnLightCone = In.PointOnLightCone;
//	Out.Color = In.Color;
	
//	Out.RayDirection = normalize(In.PointInLightPos - LightSpaceViewerPosition);
//	Out.PointInLightPos = coneVertex;
    
	return Out;
}

PS_OUTPUT RenderLightFrustumPS(VS_OUTPUT In)
{
	PS_OUTPUT Out;
	bool bInFrustum = true;

//	float4 LightPos = float4(mul(In.ScreenPos, ScreenSpaceToLightSpace));

//	float4 attenuation = 0;
//	float len = length(LightPos) / FarClip;
//	float4 currentLightSample = normalize(LightPos);
//	float4 shadowProjection = 0;

//    float2 ProjectedTexCoords = 0;
//    Out.Color = 0;
//	int loopCounter = 0;

//	for (int i=0; i<10; i++)
//	while (bInFrustum)
//	{    			
//		shadowProjection = mul(currentLightSample, LightProjection);

//		ProjectedTexCoords[0] = shadowProjection.x / shadowProjection.w / 2.0f + 0.5f;
//		ProjectedTexCoords[1] = -shadowProjection.y / shadowProjection.w / 2.0f + 0.5f;
		
		//Calc distance to light
		//float len = length(currentLightSample) / FarClip;		
		
//		if (len>0.1)
//			bInFrustum = false;
		
//		float4 d = tex2D(shadowMapSampler, ProjectedTexCoords).x;
		
//		if (len < d.x)	
//		{
			float dToLight = In.PointOnLightCone.y;			
			float d2ToLight = dToLight * dToLight;			
//			l = l*l;
			Out.Color = float4(1-d2ToLight,1-d2ToLight,1-d2ToLight, 1-d2ToLight);
//		}
//		else
//			Out.Color = float4(0.0f,0.0,0.0,0.2);	
//	}		   
   	        
	return Out;
}

//--------------------------------------------------------------------------------------
struct RTVS_INPUT
{
	float4 PointInLightSpacePos: POSITION0;		
};

struct RTVS_OUTPUT 
{
	float4 ScreenPos: POSITION0;
	float4 PointOnLightCone: TEXCOORD0;
//	float3 RayDirection: TEXCOORD1;		
//	float4 Color: COLOR;
};

struct RTPS_OUTPUT 
{
   float4 Color:   COLOR;
};

//--------------------------------------------------------------------------------------

RTVS_OUTPUT RenderLightFrustumRayTracedVS(RTVS_INPUT In)
{
	RTVS_OUTPUT Out;

	float4 coneVertex = float4(mul(In.PointInLightSpacePos.xy, ConeRadius), In.PointInLightSpacePos.zw);
	
	Out.ScreenPos = mul(coneVertex, LightSpaceToScreenSpace);
	Out.ScreenPos /= Out.ScreenPos.w;
	
	Out.PointOnLightCone = In.PointInLightSpacePos;

	return Out;
}

RTPS_OUTPUT RenderLightFrustumRayTracedPS(RTVS_OUTPUT In)
{
	RTPS_OUTPUT Out;
	
	float3 rayDirection = normalize(In.PointOnLightCone - LightSpaceViewerPosition);
	float3 rayStep = rayDirection * (length(In.PointOnLightCone) * length(In.PointOnLightCone) )* 0.05;
	float3 pointAlongRay = In.PointOnLightCone;

	float3 lightToPointOnLightNormalized = 0;
	float distanceSqrdToLight = 0;
	float intensity = 0;

	for (int i=0; i<30; i++)
	{
		lightToPointOnLightNormalized = pointAlongRay;		
		lightToPointOnLightNormalized = normalize(lightToPointOnLightNormalized);
		
		if (lightToPointOnLightNormalized.z > CosConeAngle)
		{			
			distanceSqrdToLight = length(pointAlongRay);//dot(pointAlongRay, pointAlongRay);
			intensity = saturate(intensity + 1 / distanceSqrdToLight);					
		}
		pointAlongRay += rayStep;
	}
	
	Out.Color = float4(intensity* 10, intensity* 10, intensity* 10, intensity* 10);

	return Out;

	bool bInFrustum = true;

//	float4 LightPos = float4(mul(In.ScreenPos, ScreenSpaceToLightSpace));

//	float4 attenuation = 0;
//	float len = length(LightPos) / FarClip;
//	float4 currentLightSample = normalize(LightPos);
//	float4 shadowProjection = 0;

//    float2 ProjectedTexCoords = 0;
//    Out.Color = 0;
//	int loopCounter = 0;

//	for (int i=0; i<10; i++)
//	while (bInFrustum)
//	{    			
//		shadowProjection = mul(currentLightSample, LightProjection);

//		ProjectedTexCoords[0] = shadowProjection.x / shadowProjection.w / 2.0f + 0.5f;
//		ProjectedTexCoords[1] = -shadowProjection.y / shadowProjection.w / 2.0f + 0.5f;
		
		//Calc distance to light
		//float len = length(currentLightSample) / FarClip;		
		
//		if (len>0.1)
//			bInFrustum = false;
		
//		float4 d = tex2D(shadowMapSampler, ProjectedTexCoords).x;
		
//		if (len < d.x)	
//		{
			float dToLight = In.PointOnLightCone.y;			
			float d2ToLight = dToLight * dToLight;			
//			l = l*l;
			Out.Color = float4(1-d2ToLight,1-d2ToLight,1-d2ToLight, 1-d2ToLight);
//		}
//		else
//			Out.Color = float4(0.0f,0.0,0.0,0.2);	
//	}		   
   	        
	return Out;
}

//--------------------------------------------------------------//
// Technique Section for Simple screen transform
//--------------------------------------------------------------//
technique RenderLightFrustumTechnique
{
   pass Single_Pass
   {
      
 //       SrcBlend = One; DestBlend = SrcAlpha; 

		
		VertexShader = compile vs_3_0 RenderLightFrustumVS();
		PixelShader = compile ps_3_0 RenderLightFrustumPS();
                
   }
}

technique RenderLightFrustumRayTracedTechnique
{
   pass Single_Pass
   {
      
 //       SrcBlend = One; DestBlend = SrcAlpha; 

		
		VertexShader = compile vs_3_0 RenderLightFrustumRayTracedVS();
		PixelShader = compile ps_3_0 RenderLightFrustumRayTracedPS();
                
   }
}