
// Custom shader functions go here

/*
    Max luminance approximation
    Used in https://gpuopen.com/learn/optimized-reversible-tonemapper-for-resolve/
*/

float4 Max3(float4 Color)
{
	return max(max(Color.r, Color.g), Color.b);
}
