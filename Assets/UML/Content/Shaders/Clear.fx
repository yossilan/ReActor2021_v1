struct VertexShaderInput
{
    float4 Position : POSITION0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
};

struct DepthPixelShaderOutput
{
    float4 Depth : COLOR0;
};

struct ColorPixelShaderOutput
{
    float4 Color : COLOR0;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
	VertexShaderOutput output;
	
	output.Position = input.Position;
	
	return output;
}

DepthPixelShaderOutput DepthClearPS(VertexShaderOutput input)
{
    DepthPixelShaderOutput output;

    output.Depth = float4(1.0,0,0,0);

    return output;
}

ColorPixelShaderOutput ColorClearPS(VertexShaderOutput input)
{
    ColorPixelShaderOutput output;

    output.Color = float4(0,0,0,0);

    return output;
}

technique ColorClearTechnique
{
    pass ColorPass0
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 ColorClearPS();
    }
}

technique DepthClearTechnique
{
    pass DepthPass0
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 DepthClearPS();
    }
}