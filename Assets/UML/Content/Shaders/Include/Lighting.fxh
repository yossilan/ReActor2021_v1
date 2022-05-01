#ifndef _LIGHTING_FXH_
#define _LIGHTING_FXH_

#define ISpec 1.0f
#define CSpec 1.0f

float4 SpecularColour = float4(1.0f,1.0f,1.0f,1.0);
float SpecularIntensity = 1.0f;
float4 DiffuseColour = float4(1.0f,1.0f,1.0f,1.0);
float DiffuseIntensity = 0.5f;

static inline vector PhongSpecular(in float3 light, in float3 norm, in float3 view, in float roughness)
{
	//Calculate reflection vector
	float normDotLight = dot(norm,light);
	
	float3 reflectionVector = 2 * normDotLight*norm - light;
	
	return SpecularColour * SpecularIntensity * pow( saturate(dot(reflectionVector, view)), 1/roughness);
}

static inline vector LambertDiffuse(in float3 light, in float3 norm)
{
	float normDotLight = dot(norm, light);
	return DiffuseColour * DiffuseIntensity * dot(norm, light);
}

//static inline vector Ambient()
//{
//	// Ambient intensity * Ambient Color
//	return Iamb * Camb;
//}

//static inline vector PhongSpecular(in float3 light, in float3 norm, in float3 view, in float roughness)
//{
	//Calculate reflection vector
//	float3 reflectionVector = 2 * dot(norm,light)*norm - light;
	
//	return ISpec * CSpec * pow( saturate(dot(reflectionVector, view)), 1/roughness);
//}

//static inline vector LambertianDiffuse(in float3 light, in float3 norm)
//{
//	return Idif * Cdif * dot(norm, light);
//}

static inline vector BlinnPhongSpecular(in float3 light, in float3 norm, in float3 view, in float roughness)
{
	float3 halfAngleVector = light + view;
	
	halfAngleVector /= length(halfAngleVector);
	
	return SpecularIntensity * SpecularColour * pow( saturate(dot(halfAngleVector, norm)), 1/roughness);
}


static inline float2 PackFloat16(float depth) 
{
	depth /= 4;

	float Integer = floor(depth);
	float fraction = frac(depth);

	return float2(Integer/256, fraction);
}


static inline float UnpackFloat16(float2 depth) 
{
	const float2 unpack = float2(1024.0f, 4.0f);

	return dot(unpack, depth);
}
//struct VS_INPUT {
//float4 Position : POSITION0;
//float3 Normal : NORMAL;
//}; 
//struct VS_OUTPUT {
//float4 Position : POSITION0;
//float2 Texcoord : TEXCOORD0;
//float3 EyeRay : TEXCOORD1;
//float3 Light : TEXCOORD3;
//};

//When rendering a quad for the lighting pass
//VS_OUTPUT vs_main(VS_INPUT Input) 
//{
//	VS_OUTPUT Output = (VS_OUTPUT)0;

//	Output.Position = float4(Input.Position.xy, 0.0, 1.0);
//	Output.Texcoord = float2(Output.Position.x, -Output.Position.y) * 0.5 + 0.5;

//	float ViewAspect = fViewportDimensions.x / fViewportDimensions.y;
//	Output.EyeRay = float3(Input.Position.x * ViewAspect, Input.Position.y, invTanHalfFOV);

//	Output.Light = mul(matWorldView, float4(LightPos, 1.0));
//	return(Output);
//}

//float4 ps_main(PS_INPUT i) : COLOR0 
//{
//	float4 Color;
//	float4 G_Buffer = tex2D(G_Buffer, i.Texcoord);
	
//	if (G_Buffer.w == 1.0) 
//	{
//		Color = ClearColor;
//	} 
//	else 
//	{
//		float3 N;
//		N.xy = G_Buffer.xy * 2 - 1;
//		N.z = -sqrt(1 - dot(N.xy, N.xy));
		
//		float depth = UnpackFloat16(G_Buffer.zw);
//		float3 Pos = normalize(i.EyeRay.xyz) * depth;
//		float3 L = normalize(i.Light - Pos);
//		...
//		Color = ObjectColor + ObjectColor * D * DiffIntensity + SpecColor * SpecIntensity * S;
//	}
//	return Color;
//}
#endif //_LIGHTING_FXH_