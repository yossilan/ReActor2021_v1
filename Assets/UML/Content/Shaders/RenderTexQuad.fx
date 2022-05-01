
	//Input variables
	//float4x4 worldViewProjection;

	texture baseTexture;

	sampler baseSampler = 
	sampler_state
	{
		Texture = < baseTexture >;
		MipFilter = LINEAR;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		ADDRESSU = CLAMP;
		ADDRESSV = CLAMP;
	};

	struct VS_INPUT
	{
		float4 ObjectPos: POSITION;
		float2 TextureCoords: TEXCOORD0;
	};

	struct VS_OUTPUT 
	{
	   float4 ScreenPos:   POSITION;
	   float2 TextureCoords: TEXCOORD0;
	};

	struct PS_OUTPUT 
	{
	   float4 Color:   COLOR;
	};

	struct PS_INPUT
	{
	   float4 ScreenPos:   POSITION;
	   float2 TextureCoords: TEXCOORD0;
	   float2 ScreenPos2: VPOS; 
	};


	VS_OUTPUT SimpleVS(VS_INPUT In)
	{
	   VS_OUTPUT Out;

		//Move to screen space
		Out.ScreenPos = In.ObjectPos;
		Out.TextureCoords = In.TextureCoords;
	    
		return Out;
	}

	PS_OUTPUT SimplePS(PS_INPUT In)
	{
		PS_OUTPUT Out;

		float2 v = In.TextureCoords;

		Out.Color = tex2D(baseSampler,v);
	    
	        
		return Out;
	}

	//--------------------------------------------------------------//
	// Technique Section for Simple screen transform
	//--------------------------------------------------------------//
	technique Simple
	{
	   pass Single_Pass
	   {
	      
	 //       SrcBlend = One; DestBlend = SrcAlpha; 

			
			VertexShader = compile vs_3_0 SimpleVS();
			PixelShader = compile ps_3_0 SimplePS();
	                
	   }
	}