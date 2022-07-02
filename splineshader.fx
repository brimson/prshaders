#line 2 "SplineShader.fx"

uniform float4x4 _WorldViewProj : WorldViewProjection;
uniform float4 _DiffuseColor : DiffuseColor;

float4 Spline_VS(float4 AppPos : POSITION, float3 AppNormal : NORMAL) : POSITION
{
	AppPos.xyz -= 0.035 * AppNormal;
	return mul(AppPos, _WorldViewProj);
}

float4 Spline_PS() : COLOR
{
	return _DiffuseColor;
	// return float4(1.0, 0.0, 0.0, 0.5);
}

technique spline
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
	    // Lighting = TRUE;
		// FillMode = WIREFRAME;
		// ColorWriteEnable = 0;
		// ZWriteEnable = 0;
		// ZEnable = (zbuffer);
		// ZEnable = FALSE;
		DepthBias = -0.0003;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_3_0 Spline_VS();
		PixelShader = compile ps_3_0 Spline_PS();
	}
}

float4 ControlPoint_VS(float4 AppPos : POSITION) : POSITION
{
	return mul(AppPos, _WorldViewProj);
}

float4 ControlPoint_PS() : COLOR
{
	return _DiffuseColor;
}

technique controlpoint
<
	int DetailLevel = DLHigh+DLNormal+DLLow+DLAbysmal;
	int Compatibility = CMPR300+CMPNV2X;
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		DepthBias = -0.0003;
	
		VertexShader = compile vs_3_0 ControlPoint_VS();
		PixelShader = compile ps_3_0 ControlPoint_PS();
	}
}

