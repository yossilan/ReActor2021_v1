struct VertexShaderInput
{
    float4 Position : POSITION0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
};

struct PixelShaderOutput
{
    float4 Depth : COLOR0;
    float4 Diffuse : COLOR1;
    float4 Specular : COLOR2;
};
VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
	VertexShaderOutput output;
	
	output.Position = input.Position;
	
	return output;
}

PixelShaderOutput PixelShaderFunction(VertexShaderOutput input)
{
    PixelShaderOutput output;

    output.Depth = float4(0.0,0,0,0);
    output.Diffuse = float4(0,0,0,0);
    output.Specular = float4(0,0,0,0);

    return output;
}

technique LBufferClearTechnique1
{
    pass Pass1
    {
        VertexShader = compile vs_2_0 VertexShaderFunction();
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}