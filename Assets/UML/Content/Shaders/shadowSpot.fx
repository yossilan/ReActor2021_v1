/*********************************************************************NVMH3****
$Revision: #3 $

Copyright NVIDIA Corporation 2007
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED
*AS IS* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL NVIDIA OR ITS SUPPLIERS
BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES
WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS,
BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR ANY OTHER PECUNIARY
LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF
NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

% Simple shadow map example using HW shadow textures and render ports.
% Plastic-style shading with quadratic light falloff.
% Both shadowed full-scene shadow and unshadowed materials provided.

date: 070701


To learn more about shading, shaders, and to bounce ideas off other shader
    authors and users, visit the NVIDIA Shader Library Forums at:

    http://developer.nvidia.com/forums/

******************************************************************************/

#define MAX_SHADOW_BIAS 0.001
#define FLIP_TEXTURE_Y

#include <include\\shadowMap.fxh>

// when DEBUG_VIEW is defined, texture using the RGB portion of the
//		shadow pass, to verify that projection is correct
//#define DEBUG_VIEW
#include <include\\spot_tex.fxh>

#ifdef _3DSMAX_
int ParamID = 0x0003; // Defined by Autodesk
#endif /* _3DSMAX_ */

float Script : STANDARDSGLOBAL <
	string UIWidget = "none";
	string ScriptClass = "sceneorobject";
	string ScriptOrder = "standard";
	string ScriptOutput = "color";
	string Script = "Technique=Technique?Shadowed:Unshadowed;";
> = 0.8; // version #

float4 ClearColor <
    string UIWidget = "Color";
    string UIName = "Background";
> = {0,0,0,0};

float ClearDepth <string UIWidget = "none";> = 1.0;

//// UN-TWEAKABLES - AUTOMATICALLY-TRACKED TRANSFORMS ////////////////

float4x4 WorldITXf : WorldInverseTranspose < string UIWidget="None"; >;
float4x4 WvpXf : WorldViewProjection < string UIWidget="None"; >;
float4x4 WorldXf : World < string UIWidget="None"; >;
float4x4 ViewIXf : ViewInverse < string UIWidget="None"; >;

DECLARE_SHADOW_XFORMS("SpotLight0",LampViewXf,LampProjXf,ShadowViewProjXf)
DECLARE_SHADOW_BIAS
DECLARE_SHADOW_MAPS(ColorShadMap,ColorShadSampler,ShadDepthTarget,ShadDepthSampler)

///////////////////////////////////////////////////////////////
/// TWEAKABLES ////////////////////////////////////////////////
///////////////////////////////////////////////////////////////

////////////////////////////////////////////// spot light

// SpotLamp 0 /////////////
float3 SpotLamp0Pos : Position <
    string Object = "SpotLight0";
    string UIName =  "Lamp 0 Position";
    string Space = "World";
> = {-0.5f,2.0f,1.25f};
float3 Lamp0Color : Specular <
    string UIName =  "Lamp 0";
    string Object = "Spotlight0";
    string UIWidget = "Color";
> = {1.0f,1.0f,1.0f};
float Lamp0Intensity <
    string UIWidget = "slider";
    float UIMin = 1.0;
    float UIMax = 10000.0f;
    float UIStep = 0.1;
    string UIName =  "Lamp 0 Quadratic Intensity";
> = 20.0f;

////////////////////////////////////////////// ambient light

// Ambient Light
float3 AmbiColor : Ambient <
    string UIName =  "Ambient Light";
    string UIWidget = "Color";
> = {0.07f,0.07f,0.07f};

////////////////////////////////////////////// surface attributes

float3 SurfaceColor : DIFFUSE <
    string UIName =  "Surface";
    string UIWidget = "Color";
> = {1.0f, 1.0f, 1.0f};

float Kd <
    string UIWidget = "slider";
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.01;
    string UIName =  "Diffuse";
> = 0.9;

float Ks <
    string UIWidget = "slider";
    float UIMin = 0.0;
    float UIMax = 1.0;
    float UIStep = 0.05;
    string UIName =  "Specular";
> = 0.4;


float SpecExpon : SpecularPower
<
    string UIWidget = "slider";
    float UIMin = 1.0;
    float UIMax = 128.0;
    float UIStep = 1.0;
    string UIName = "Specular power";
> = 12.0;

////////////////////////////////////////////////////////////////////////////
/// SHADER CODE BEGINS /////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

/*********************************************************/
/*********** pixel shader ********************************/
/*********************************************************/


//
// core of the surface shading, shared by both shadowed and unshadowed versions
//
void lightingCalc(ShadowingVertexOutput IN,
					out float3 litContrib,
					out float3 ambiContrib)
{
    float3 Nn = normalize(IN.WNormal);
    float3 Vn = normalize(IN.WView);
    Nn = faceforward(Nn,-Vn,Nn);
    float falloff = 1.0 / dot(IN.LightVec,IN.LightVec);
    float3 Ln = normalize(IN.LightVec);
    float3 Hn = normalize(Vn + Ln);
    float hdn = dot(Hn,Nn);
    float ldn = dot(Ln,Nn);
    float4 litVec = lit(ldn,hdn,SpecExpon);
    ldn = litVec.y * Lamp0Intensity;
    ambiContrib = SurfaceColor * AmbiColor;
    float3 diffContrib = SurfaceColor*(Kd*ldn * Lamp0Color);
    float3 specContrib = ((ldn * litVec.z * Ks) * Lamp0Color);
    float3 result = diffContrib + specContrib;
    float cone = tex2Dproj(SpotSamp,IN.LProj).x;
    litContrib =  ((cone*falloff) * result);
}

// #define DEBUG_VIEW

float4 useShadowPS(ShadowingVertexOutput IN) : COLOR
{
#ifdef DEBUG_VIEW
    return tex2Dproj(ColorShadSampler,IN.LProj);	// show the RGB render instead
#else /*!DEBUG_VIEW */
    float3 litPart, ambiPart;
    lightingCalc(IN,litPart,ambiPart);
    float4 shadowed = tex2Dproj(ShadDepthSampler,IN.LProj);
    return float4((shadowed.x*litPart)+ambiPart,1);
#endif /*!DEBUG_VIEW */
}

float4 unshadowedPS(ShadowingVertexOutput IN) : COLOR
{
    float3 litPart, ambiPart;
    lightingCalc(IN,litPart,ambiPart);
    return float4(litPart+ambiPart,1);
}

////////////////////////////////////////////////////////////////////
/// TECHNIQUES /////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////



technique Shadowed <
    string Script = "Pass=MakeShadow;"
		    "Pass=UseShadow;";
> {
    pass MakeShadow <
	string Script = "RenderColorTarget0=ColorShadMap;"
			"RenderDepthStencilTarget=ShadDepthTarget;"
			"RenderPort=SpotLight0;"
			"ClearSetColor=ShadowMapClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
			"Draw=geometry;";
    > {
	    VertexShader = compile vs_2_0 shadowGenVS(WorldXf,
					WorldITXf,ShadowViewProjXf);
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = false;
		CullMode = None;
	    // no pixel shader!
    }
    pass UseShadow <
	    string Script = "RenderColorTarget0=;"
			    "RenderDepthStencilTarget=;"
			    "RenderPort=;"
			    "ClearSetColor=ClearColor;"
			    "ClearSetDepth=ClearDepth;"
			    "Clear=Color;"
			    "Clear=Depth;"
			    "Draw=geometry;";
    > {
	VertexShader = compile vs_2_0 shadowUseVS(WorldXf,
					WorldITXf, WvpXf, ShadowViewProjXf,
					ViewIXf, ShadBiasXf, SpotLamp0Pos);
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = false;
		CullMode = None;
	PixelShader = compile ps_2_a useShadowPS();

    }
}

technique Unshadowed < string Script = "Pass=NoShadow;"; > {
    pass NoShadow <
	string Script = "RenderColorTarget0=;"
			"RenderDepthStencilTarget=;"
			"RenderPort=;"
			"ClearSetColor=ClearColor;"
			"ClearSetDepth=ClearDepth;"
			"Clear=Color;"
			"Clear=Depth;"
			"Draw=geometry;";
    > {
	VertexShader = compile vs_2_0 shadowUseVS(WorldXf,
					WorldITXf, WvpXf, ShadowViewProjXf,
					ViewIXf, ShadBiasXf, SpotLamp0Pos);
		ZEnable = true;
		ZWriteEnable = true;
		ZFunc = LessEqual;
		AlphaBlendEnable = false;
		CullMode = None;
	PixelShader = compile ps_2_a unshadowedPS();
    }
}

/***************************** eof ***/
