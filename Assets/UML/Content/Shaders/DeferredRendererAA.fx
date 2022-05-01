
Texture PreAAMap;
Texture DepthMap;
float2 HalfPixel;

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

sampler PreAASampler =
sampler_state
{
    Texture = < PreAAMap >;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

struct VertexShaderInput
{
    float4 Position : POSITION;
	float2 TexCoords: TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 ScreenPos : POSITION;
    float2 TexCoords : TEXCOORD0;
};

struct PixelShaderOutput
{
    vector Color : COLOR0;
};

VertexShaderOutput DeferredRenderAAVS(VertexShaderInput input)
{
    VertexShaderOutput output;

	output.ScreenPos = input.Position;
	output.TexCoords = input.TexCoords+HalfPixel;
    return output;
}


float AAColourThreshold = 0.2f;
float AADepthThreshold = 0.01f;

PixelShaderOutput DeferredRender4xAAPS(VertexShaderOutput input) 
{
	PixelShaderOutput output;
	float2 pixelLeft = float2(-HalfPixel.x * 2.0f,0.0f);
	float2 pixelRight = float2(HalfPixel.x * 2.0f,0.0f);
	float2 pixelUp = float2(0.0f, HalfPixel.y * 2.0f);
	float2 pixelDown = float2(0.0f, -HalfPixel.y * 2.0f);
	  
    float4 color		= tex2D(PreAASampler, input.TexCoords).rgba;
    float4 colorLeft	= tex2D(PreAASampler, input.TexCoords+pixelLeft).rgba;
    float4 colorRight	= tex2D(PreAASampler, input.TexCoords+pixelRight).rgba;
    float4 colorUp		= tex2D(PreAASampler, input.TexCoords+pixelUp).rgba;
    float4 colorDown	= tex2D(PreAASampler, input.TexCoords+pixelDown).rgba;
	
	float isContrastingWithLeft		= (distance(color, colorLeft) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithRight	= (distance(color, colorRight) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithUp		= (distance(color, colorUp) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithDown		= (distance(color, colorDown) > AAColourThreshold)? 1.0 : 0.0;
		
	float depthSample		= tex2D(DepthSampler, input.TexCoords).x;
	float depthSampleLeft	= tex2D(DepthSampler, input.TexCoords + pixelLeft).x;
	float depthSampleRight	= tex2D(DepthSampler, input.TexCoords + pixelRight).x;
	float depthSampleUp		= tex2D(DepthSampler, input.TexCoords + pixelUp).x;
	float depthSampleDown	= tex2D(DepthSampler, input.TexCoords + pixelDown).x;
	
	float isCloserThanLeft	= ((depthSampleLeft - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanRight = ((depthSampleRight - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanUp	= ((depthSampleUp - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanDown	= ((depthSampleDown - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;

	float totalPixels = isContrastingWithLeft*isCloserThanLeft + isContrastingWithRight*isCloserThanRight +
						isContrastingWithUp*isCloserThanUp + isContrastingWithDown*isCloserThanDown;

	if (totalPixels > 0.99)
	{	
		output.Color.rgba = float4((color.rbg +
									colorLeft.rgb * isContrastingWithLeft * isCloserThanLeft +
									colorRight.rgb * isContrastingWithRight * isCloserThanRight +
									colorUp.rgb  * isContrastingWithUp * isCloserThanUp +
									colorDown.rgb  * isContrastingWithDown * isCloserThanDown)/(totalPixels+1.0), 1.0f);	
	}
	else
	{
		output.Color = color;
	}
	
									
	return output;
}

PixelShaderOutput DeferredRender8xAAPS(VertexShaderOutput input) 
{
	PixelShaderOutput output;
	float2 pixelLeft = float2(-HalfPixel.x * 2.0f,0.0f);
	float2 pixelRight = float2(HalfPixel.x * 2.0f,0.0f);
	float2 pixelUp = float2(0.0f, HalfPixel.y * 2.0f);
	float2 pixelDown = float2(0.0f, -HalfPixel.y * 2.0f);
	  
    float4 color		= tex2D(PreAASampler, input.TexCoords).rgba;
    float4 colorLeft	= tex2D(PreAASampler, input.TexCoords+pixelLeft).rgba;
    float4 colorLeftUp	= tex2D(PreAASampler, input.TexCoords+pixelLeft+pixelUp).rgba;
    float4 colorLeftDown= tex2D(PreAASampler, input.TexCoords+pixelLeft+pixelDown).rgba;
    float4 colorRight	= tex2D(PreAASampler, input.TexCoords+pixelRight).rgba;
    float4 colorRightUp	= tex2D(PreAASampler, input.TexCoords+pixelRight+pixelUp).rgba;
    float4 colorRightDown= tex2D(PreAASampler, input.TexCoords+pixelRight+pixelDown).rgba;
    float4 colorUp		= tex2D(PreAASampler, input.TexCoords+pixelUp).rgba;
    float4 colorDown	= tex2D(PreAASampler, input.TexCoords+pixelDown).rgba;
	
	float isContrastingWithLeft		= (distance(color, colorLeft) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithLeftUp	= (distance(color, colorLeftUp) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithLeftDown	= (distance(color, colorLeftDown) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithRight	= (distance(color, colorRight) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithRightUp	= (distance(color, colorRightUp) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithRightDown= (distance(color, colorRightDown) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithUp		= (distance(color, colorUp) > AAColourThreshold)? 1.0 : 0.0;
	float isContrastingWithDown		= (distance(color, colorDown) > AAColourThreshold)? 1.0 : 0.0;
		
	float depthSample		= tex2D(DepthSampler, input.TexCoords).x;
	float depthSampleLeft	= tex2D(DepthSampler, input.TexCoords + pixelLeft).x;
	float depthSampleLeftUp	= tex2D(DepthSampler, input.TexCoords + pixelLeft + pixelUp).x;
	float depthSampleLeftDown = tex2D(DepthSampler, input.TexCoords + pixelLeft + pixelDown).x;
	float depthSampleRight	= tex2D(DepthSampler, input.TexCoords + pixelRight).x;
	float depthSampleRightUp= tex2D(DepthSampler, input.TexCoords + pixelRight + pixelUp).x;
	float depthSampleRightDown= tex2D(DepthSampler, input.TexCoords + pixelRight + pixelDown).x;
	float depthSampleUp		= tex2D(DepthSampler, input.TexCoords + pixelUp).x;
	float depthSampleDown	= tex2D(DepthSampler, input.TexCoords + pixelDown).x;
	
	float isCloserThanLeft	= ((depthSampleLeft - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanLeftUp= ((depthSampleLeftUp - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanLeftDown= ((depthSampleLeftDown - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanRight = ((depthSampleRight - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanRightUp = ((depthSampleRightUp - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanRightDown = ((depthSampleRightDown - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanUp	= ((depthSampleUp - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;
	float isCloserThanDown	= ((depthSampleDown - depthSample) >= AADepthThreshold) ? 1.0 : 0.0;

	float totalPixels = isContrastingWithLeft*isCloserThanLeft + isContrastingWithRight*isCloserThanRight +
						isContrastingWithLeftUp*isCloserThanLeftUp + isContrastingWithRightUp*isCloserThanRightUp +
						isContrastingWithLeftDown*isCloserThanLeftDown + isContrastingWithRightDown*isCloserThanRightDown +
						isContrastingWithUp*isCloserThanUp + isContrastingWithDown*isCloserThanDown;

	if (totalPixels > 0.99)
	{	
		output.Color.rgba = float4(color.rbg * 0.5+
									((colorLeft.rgb * isContrastingWithLeft * isCloserThanLeft +
									colorLeftUp.rgb * isContrastingWithLeftUp * isCloserThanLeftUp +
									colorLeftDown.rgb * isContrastingWithLeftDown * isCloserThanLeftDown +
									colorRight.rgb * isContrastingWithRight * isCloserThanRight +
									colorRightUp.rgb * isContrastingWithRightUp * isCloserThanRightUp +
									colorRightDown.rgb * isContrastingWithRightDown * isCloserThanRightDown +
									colorUp.rgb  * isContrastingWithUp * isCloserThanUp +
									colorDown.rgb  * isContrastingWithDown * isCloserThanDown)/totalPixels)*0.5, 1.0f);	
	}
	else
	{
		output.Color = color;
	}
	
									
	return output;
}

technique DeferredRenderAATechnique
{
    pass DeferredRenderColourBasedAAImagePass0
    {
        VertexShader = compile vs_3_0 DeferredRenderAAVS();
        PixelShader = compile ps_3_0 DeferredRender8xAAPS();
    }
}
