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

//
// Create a round pattern texture for spot lights
//


To learn more about shading, shaders, and to bounce ideas off other shader
    authors and users, visit the NVIDIA Shader Library Forums at:

    http://developer.nvidia.com/forums/

******************************************************************************/

#ifndef _H_SPOT_TEX
#define _H_SPOT_TEX

float spot_pattern(float2 UV,float InnerRadius,float OuterRadius)
{
    float2 v = UV - float2(0.5,0.5);
    float d = length(v)/OuterRadius;
    float s = 1.0 - smoothstep(InnerRadius,1,d);
    return s;
}

#ifndef SPOT_TEX_SIZE
#define SPOT_TEX_SIZE 64
#endif /* SPOT_TEX_SIZE */

#ifndef SPOT_TEX_INSIDE
#define SPOT_TEX_INSIDE 0.4
#endif /* SPOT_TEX_INSIDE */


// function used to fill texture
float4 spot_texel(float2 P : POSITION,float2 dP : PSIZE) : COLOR
{
    //adjust so the outer rows and columns are ALWAYS black
    float2 rad = float2(0.5,0.5) - dP;
    float s = spot_pattern(P,SPOT_TEX_INSIDE,rad.x); // for now simple case of (dP.x==dP.y)
    return float4(s.xxx,1.0);
}

texture SpotTex  <
    string TextureType = "2D";
    string UIName = "Spotlight Shape Texture";
    string function = "spot_texel";
    string UIWidget = "None";
    int width = SPOT_TEX_SIZE, height = SPOT_TEX_SIZE;
>;

// samplers
sampler2D SpotSamp = sampler_state 
{
    texture = <SpotTex>;
    AddressU  = Clamp;        
    AddressV  = Clamp;
    MinFilter = Linear;
    MipFilter = Linear;
    MagFilter = Linear;
};

#endif /* _H_SPOT_TEX */

