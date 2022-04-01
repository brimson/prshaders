
/*
    Custom shader functions
*/

/*
    2-dimensional Gaussian distribution function
    Gaussian function: https://www.rastergrid.com/blog/2010/09/efficient-Gaussian-blur-with-linear-sampling/
*/

float Gaussian(float Index, float Sigma)
{
    const float Pi = 3.1415926535897932384626433832795;
    float Output = rsqrt(2.0 * Pi * (Sigma * Sigma));
    return Output * exp(-(Index * Index) / (2.0 * Sigma * Sigma));
}

/*
    Source: https://github.com/patriciogonzalezvivo/lygia
    Author: Patricio Gonzalez Vivo
    Description: pass a value and get some random normalize value between 0 and 1
    Use: float random[2|3](<float|float2|float3> value)
    License:
        Copyright (c) 2021 Patricio Gonzalez Vivo.

        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

float Random(in float2 st)
{
    return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453);
}

float Random(in float3 pos)
{
  return frac(sin(dot(pos.xyz, float3(70.9898, 78.233, 32.4355))) * 43758.5453123);
}

/*
    Max luminance approximation
    Used in https://gpuopen.com/learn/optimized-reversible-tonemapper-for-resolve/
*/

float4 Max3(float4 Color)
{
	return max(max(Color.r, Color.g), Color.b);
}
