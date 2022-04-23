struct Point_Light_Data
{
	float3 Pos;
	float AttSqrInv;
	float3 Col;
};

struct Spot_Light_Data
{
	float3 Pos;
	float AttSqrInv;
	float3 Col;
	float ConeAngle;
	float3 Dir;
	float OneMinusConeAngle;
};

Point_Light_Data _PointLight : POINTLIGHT;
Spot_Light_Data _SpotLight : SPOTLIGHT;

float4 _LightPositionAndAttSqrInv : LightPositionAndAttSqrInv;
float4 _LightColor : LightColor;

float3 Calc_PV_Point(Point_Light_Data Input, float3 WorldPos, float3 Normal)
{
	float3 LightVec = _LightPositionAndAttSqrInv.xyz - WorldPos;
	float RadialAtt = saturate(1.0 - dot(LightVec, LightVec) * _LightPositionAndAttSqrInv.w);

	LightVec = normalize(LightVec);
	float Intensity = dot(LightVec, Normal) * RadialAtt;
	return Intensity * _LightColor.xyz;
}

float3 Calc_PV_Point_Terrain(float3 WorldPos, float3 Normal)
{
	float3 LightVec = _PointLight.Pos - WorldPos;
	float RadialAtt = saturate(1.0 - (dot(LightVec, LightVec)) * _PointLight.AttSqrInv);
	// return RadialAtt * _PointLight.Col;

	LightVec = normalize(LightVec);
	float Intensity = dot(LightVec, Normal) * RadialAtt;
	return Intensity * _PointLight.Col;
}

float3 Calc_PV_Spot(Spot_Light_Data Input, float3 WorldPos, float3 Normal)
{
	float3 LightVec = Input.Pos - WorldPos;
	
	float RadialAtt = saturate(1.0 - dot(LightVec, LightVec) * Input.AttSqrInv);
	LightVec = normalize(LightVec);
	
	float ConicalAtt = saturate(dot(LightVec, Input.Dir) - Input.OneMinusConeAngle) / Input.ConeAngle;

	float Intensity = dot(LightVec, Normal) * RadialAtt * ConicalAtt;

	return Intensity * Input.Col;
}
