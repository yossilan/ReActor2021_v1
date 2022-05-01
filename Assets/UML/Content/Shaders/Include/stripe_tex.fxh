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

// Utility for texture-based stripes and checks.
// Creates the texture and provides functions:
//    	stripe() numeric_stripe()
//	checker2D() checker3D() checker3Drgb()


To learn more about shading, shaders, and to bounce ideas off other shader
    authors and users, visit the NVIDIA Shader Library Forums at:

    http://developer.nvidia.com/forums/

******************************************************************************/


#ifndef _H_STRIPE_TEX_
#define _H_STRIPE_TEX_

// caller-override-able

#ifndef STRIPE_TEX_SIZE
#define STRIPE_TEX_SIZE 128
#endif /* STRIPE_TEX_SIZE */

#ifndef DEFAULT_BALANCE
#define DEFAULT_BALANCE (0.5)
#endif /* DEFAULT_BALANCE */

/************************************************************/
/*** TWEAKABLES *********************************************/
/************************************************************/

#define DECLARE_BALANCE float Balance < \
    string UIWidget = "slider"; \
    float uimin = 0.01; \
    float uimax = 0.99; \
    float uistep = 0.01; \
    string UIName = "Balance"; \
> = DEFAULT_BALANCE;

/////////////// prodecural texture /////////////

/*********** texture shader ******/

float4 make_stripe_tex(float2 Pos : POSITION,float ps : PSIZE) : COLOR
{
   float v = 0;
   float nx = Pos.x+ps; // keep the last column full-on, always
   v = nx > Pos.y;
   return float4(v.xxxx);
}

// texture declaration

texture _StripeTexture <
    string function = "make_stripe_tex";
    string UIWidget = "None";
    float2 Dimensions = { STRIPE_TEX_SIZE, STRIPE_TEX_SIZE };
>;

sampler2D _StripeSampler = sampler_state {
    Texture = <_StripeTexture>;
    MinFilter = Linear;
    MipFilter = Linear;
    MagFilter = Linear;
    AddressU = Wrap;
    AddressV = Clamp;
};

////////////////////////////////////////////
// Utility Functions ///////////////////////
////////////////////////////////////////////

// base function: "Balance" is in W term
float stripe(float4 XYZW) { return tex2D(_StripeSampler,XYZW.xw).x; }

float stripe(float4 XYZW,float Balance) {
    return stripe(float4(XYZW.xyz,Balance)); }

float stripe(float3 XYZ,float Balance) {
    return stripe(float4(XYZ.xyz,Balance)); }

float stripe(float2 XY,float Balance) {
    return stripe(float4(XY.xyy,Balance)); }

float stripe(float X,float Balance) {
    return stripe(float4(X.xxx,Balance)); }

// use default balance (can't do float4 version, would interfere): //

float stripe(float3 XYZ) {
    return stripe(float4(XYZ.xyz,DEFAULT_BALANCE)); }

float stripe(float2 XY) {
    return stripe(float4(XY.xyy,DEFAULT_BALANCE)); }

float stripe(float X) {
    return stripe(float4(X.xxx,DEFAULT_BALANCE)); }

///////////////////////////////////
// texture-free alternative ///////
///////////////////////////////////

float numeric_stripe(
	    float Value,
	    float Balance,
	    float Oversample,
	    float PatternScale
) {
    float width = abs(ddx(Value)) + abs(ddy(Value));
    float w = width*Oversample;
    float x0 = Value/PatternScale - (w/2.0);
    float x1 = x0 + w;
    float i0 = (1.0-Balance)*floor(x0) + max(0.0, frac(x0)-Balance);
    float i1 = (1.0-Balance)*floor(x1) + max(0.0, frac(x1)-Balance);
    float stripe = (i1 - i0)/w;
    stripe = min(1.0,max(0.0,stripe)); 
    return stripe;
}

///////////////////////////////////
// 2D checkerboard ////////////////
///////////////////////////////////

float checker2D(float4 XYZW)
{
    float stripex = tex2D(_StripeSampler,XYZW.xw).x;
    float stripey = tex2D(_StripeSampler,XYZW.yw).x;
    return abs(stripex - stripey);
}

// overloads of the above

float checker2D(float4 XYZW,float Balance) {
    return checker2D(float4(XYZW.xyz,Balance)); }

float checker2D(float3 XYZ,float Balance) {
    return checker2D(float4(XYZ.xyz,Balance)); }

float checker2D(float2 XY,float Balance) {
    return checker2D(float4(XY.xyy,Balance)); }

// use default balance ////////////////////////

float checker2D(float3 XYZ) {
    return checker2D(float4(XYZ.xyz,DEFAULT_BALANCE)); }

float checker2D(float2 XY) {
    return checker2D(float4(XY.xyy,DEFAULT_BALANCE)); }

float checker2D(float X) {
    return checker2D(float4(X.xxx,DEFAULT_BALANCE)); }

///////////////////////////////////
// 3D checkerboard ////////////////
///////////////////////////////////

float checker3D(float4 XYZW)
{
    float stripex = tex2D(_StripeSampler,XYZW.xw).x;
    float stripey = tex2D(_StripeSampler,XYZW.yw).x;
    float stripez = tex2D(_StripeSampler,XYZW.zw).x;
    float check = abs(abs(stripex - stripey) - stripez);
    return check;
}

// overloads of the above

float checker3D(float3 XYZ,float Balance) {
    return checker3D(float4(XYZ.xyz,Balance)); }

float checker3D(float4 XYZW,float Balance) {
    return checker3D(float4(XYZW.xyz,Balance)); }

// use default balance ////////////////////////

float checker3D(float3 XYZ) {
    return checker3D(float4(XYZ.xyz,DEFAULT_BALANCE)); }

float checker3D(float2 XY) {
    return checker3D(float4(XY.xyy,DEFAULT_BALANCE)); }

float checker3D(float X) {
    return checker3D(float4(X.xxx,DEFAULT_BALANCE)); }

/////////////

float3 checker3Drgb(float4 XYZW)
{
    float3 result;
    result.x = tex2D(_StripeSampler,XYZW.xw).x;
    result.y = tex2D(_StripeSampler,XYZW.yw).x;
    result.z = tex2D(_StripeSampler,XYZW.zw).x;
    return result;
}

float3 checker3Drgb(float3 XYZ,float Balance) {
    return checker3Drgb(float4(XYZ.xyz,Balance)); }

float3 checker3Drgb(float3 XYZ) {
    return checker3Drgb(float4(XYZ.xyz,DEFAULT_BALANCE)); }

#endif /* _H_STRIPE_TEX_ */

/***************************** eof ***/
