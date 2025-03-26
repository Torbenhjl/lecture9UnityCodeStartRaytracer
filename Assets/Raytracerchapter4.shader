
// Fra https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509640(v=vs.85).aspx
//https://msdn.microsoft.com/en-us/library/windows/desktop/ff471421(v=vs.85).aspx
// rand num generator http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
// http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
// https://docs.unity3d.com/Manual/RenderDocIntegration.html
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html

Shader "Unlit/SingleColor"
{

					Properties
{
// inputs from gui, NB remember to also define them in "redeclaring" section
[Toggle] _boolchooser("myBool", Range(0,1)) = 0 // [Toggle] creates a checkbox in gui and gives it 0 or 1
_floatchooser("myFloat", Range(-1,1)) = 0
_colorchooser("myColor", Color) = (1,0,0,1)
_vec4chooser("myVec4", Vector) = (0,0,0,0)
}
		SubShader{ Pass	{


			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		int _boolchooser;
float _floatchooser;
float4 _colorchooser;// alternative use fixed4; range of –2.0 to +2.0 and 1/256th precision. (https://docs.unity3d.com/Manual/SL-
//DataTypesAndPrecision.html)
float4 _vec4chooser;
//sampler2D _texturechooser

		typedef vector <float, 3> vec3;  // to get more similar code to book
		typedef vector <fixed, 3> col3;
	
	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
		float3 rayDir : TEXCOORD1;
	};

	// camera setup
	float3 camOrigin = float3(0.0,0.0,0.0);
	vec3 sphereCenter = vec3(0.0,0.0,-1.0);
	float sphereRadius = 0.5;
		
	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;

		float aspectRatio = _ScreenParams.x / _ScreenParams.y;
		float3 rayDir = normalize(float3((o.uv.x - 0.5) * 2.0 * aspectRatio, (o.uv.y - 0.5) * 2.0, -1.0));
        o.rayDir = rayDir;

		return o;
	}
	
	  bool hitSphere(vec3 center, float radius, float3 rayOrigin, float3 rayDir)
            {
                vec3 oc = rayOrigin - center;
                float a = dot(rayDir, rayDir);
                float b = 2.0 * dot(oc, rayDir);
                float c = dot(oc, oc) - (radius * radius);
                float discriminant = b * b - 4.0 * a * c;
                return (discriminant > 0);
            }

////////////////////////////////////////////////////////////////////////////////////////////////////////
	fixed4 frag(v2f i) : SV_Target
	{
		
		if(hitSphere(vec3(0,0,-1), 0.5, camOrigin, i.rayDir)) 
		{
			return fixed4(1,0,0,0); //red
		}
		
		float x = i.uv.x;
		float y = i.uv.y;

		float3 white = fixed3(1.0,1.0,1.0);
		fixed3 blue = fixed3(0.5,0.7,1.0);

	

		col3 col = lerp(white,blue,y);

		return fixed4(col * _colorchooser,1.0); 
	}
////////////////////////////////////////////////////////////////////////////////////


ENDCG

}}}