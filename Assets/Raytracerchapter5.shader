﻿
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
		typedef vector <float, 2> vec2;
	
	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
		
	};

	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;

		return o;
	};

	struct ray 
	{
		vec3 origin;
		vec3 direction;

		static ray from(vec3 origin, vec3 direction) 
		{
			ray r;
			r.origin = origin;
			r.direction = direction;

			return r;
		}

		vec3 point_at(float t)
		{
			return origin + t * direction;
		}
			
	};

	struct camera{
		vec3 origin;
		vec3 horizontal;
		vec3 vertical;
		vec3 lower_left_corner;

		ray get_ray(float u, float v)
		{
			return ray::from(origin, lower_left_corner + u *horizontal + v * vertical);
			}

			static camera create()
			{
				camera c;

				c.lower_left_corner = vec3(-2, -1, -1);
				c.horizontal = vec3(4.0, 0, 0);
				c.vertical = vec3(0, 2.0, 0);
				c.origin = vec3(0,0,0);

				return c;
				}
		};
	
	

	struct hit_record
	{
		float t;
		vec3 position;
		vec3 normal;
	};




	struct sphere
	{
		vec3 center;
		float radius;

		static sphere from(vec3 center, float radius)
		{
			sphere s;
			s.center = center;
			s.radius = radius;

			return s;
		}
	

	  bool hitSphere(ray r, float t_min, float t_max, out hit_record rec)
            {
                vec3 oc = r.origin - center;
                float a = dot(r.direction, r.direction);
                float b = dot(oc, r.direction);
                float c = dot(oc, oc) - (radius * radius);
				
                float discriminant = b * b -  a * c;
				if(discriminant > 0) {
					float temp = (-b -sqrt(b*b - a*c)) / a;
					if(temp < t_max && temp > t_min)
					{
						rec.t = temp;
						rec.position = r.point_at(rec.t);
						rec.normal = (rec.position - center) / radius;
						return true;
					}
					temp = (-b + sqrt(discriminant)) / a;
					if(temp < t_max && temp > t_min)
					{
						rec.t = temp;
						rec.position = r.point_at(rec.t);
						rec.normal = (rec.position - center) / radius;
						return true;
					}
				} 
				return false;
                
            }
	};

	static const uint NUM_SPHERES = 2;
	static const sphere WORLD[NUM_SPHERES] = 
	{
			{vec3(0.0,0.0,-1.0), 0.5},
			{vec3(0.0, -100.5, -1), 100.0}
	};




	bool intersect_world(ray r, float t_min, float t_max, out hit_record rec) 
	{
		hit_record temp_rec;
		bool hit_anything = false;
		float closest_so_far = t_max;

		for(int i = 0; i < NUM_SPHERES; i++) {
			sphere s = WORLD[i];
			if(s.hitSphere(r, t_min, closest_so_far, temp_rec))
			{
				hit_anything = true;
				closest_so_far = temp_rec.t;
				rec = temp_rec;
				}
			}
			return hit_anything;

	}

	vec3 background(ray r) 
	{
			float t = 0.5 * (normalize(r.direction).y + 1.0);
			return lerp(vec3(1.0,1.0,1.0), vec3(0.5,0.7,1.0), t);
	}

			vec3 trace(ray r) {

				vec3 color = vec3(1.0, 1.0, 1.0);

				hit_record record;

				if (intersect_world(r, 0.001, 100000.0, record)) {
					return 0.5 * vec3(record.normal.x + 1.0, record.normal.y + 1.0, record.normal.z + 1.0);
				} else {
					return color * background(r);
				}

			}
////////////////////////////////////////////////////////////////////////////////////////////////////////
	fixed4 frag(v2f i) : SV_Target
	{
		
		camera cam = camera::create();

		float u = i.uv.x;
		float v = i.uv.y;

		ray r = cam.get_ray(u,v);

		return fixed4(trace(r) * _colorchooser, 1.0);
	}
////////////////////////////////////////////////////////////////////////////////////


ENDCG

}}}