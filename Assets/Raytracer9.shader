﻿Shader "Unlit/SingleColor"
{

	Properties
{
// inputs from gui, NB remember to also define them in "redeclaring" section
[Toggle] _boolchooser("myBool", Range(0,1)) = 0 // [Toggle] creates a checkbox in gui and gives it 0 or 1
_floatchooser("myFloat", Range(-1,1)) = 0
_colorchooser("myColor", Color) = (1,0,0,1)
_vec4chooser("myVec4", Vector) = (0,0,0,0)
}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// redeclaring gui inputs
			int _boolchooser;
			float _floatchooser;
			float4 _colorchooser;// alternative use fixed4; range of –2.0 to +2.0 and 1/256th precision. (https://docs.unity3d.com/Manual/SL-
			//DataTypesAndPrecision.html)
			float4 _vec4chooser;
			//sampler2D _texturechooser

			typedef vector <float, 3> vec3;  // to get more similar code to book
			typedef vector <float, 2> vec2;
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

			};
	
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			static const uint NUMBER_OF_SAMPLES = 30;
			static const uint MAXIMUM_DEPTH = 10;

			static float rand_seed = 0.0;
			static float2 rand_uv = float2(0.0, 0.0);

			float noise(in vec2 coordinate) {
				float2 noise = frac(sin(dot(coordinate, float2(12.9898, 78.233) * 2.0)) * 43758.5453);
				return abs(noise.x + noise.y) * 0.5;
			}

			static float random_number() {
				float2 uv = float2(rand_uv.x + rand_seed, rand_uv.y + rand_seed);
				float random = noise(uv);
				rand_seed += 0.01;

				return random;
			}

			vec3 random_in_unit_sphere() {
						vec3 p;
						do {
							p = 2.0 * vec3(random_number(), random_number(), random_number()) - vec3(1.0, 1.0, 1.0);
						} while (dot(p, p) >= 1.0); // Ensure it's inside a unit sphere
						return p;
}


			struct hit_record {
				float t;
				vec3 position;
				vec3 normal;
				uint index;
				
			};

			struct ray
			{
				vec3 origin;
				vec3 direction;	

				static ray from(vec3 origin, vec3 direction) {
					ray r;
					r.origin = origin;
					r.direction = direction;

					return r;
				}

				vec3 point_at(float t) {
					return origin + t *direction;
				}
			};

			struct camera {
				

				vec3 origin;
				vec3 horizontal;
				vec3 vertical;
				vec3 lower_left_corner;
				
				ray get_ray(float u, float v) {
					return ray::from(origin, lower_left_corner + u * horizontal + v * vertical);
				}

				static camera create() {
					camera c;

					c.lower_left_corner = vec3(-2, -1, -1);
					c.horizontal = vec3(4.0, 0, 0);
					c.vertical = vec3(0, 2.0, 0);
					c.origin = vec3(0, 0, 0);

					return c;
				}
			};
			

	bool refract(vec3 v, vec3 n, float3 ni_over_nt, out vec3 refracted)
	{
		vec3 uv = normalize(v);
		float dt = dot(uv, n);
		float discriminant = 1.0 - ni_over_nt * ni_over_nt * (1 - dt * dt);
		if(discriminant > 0) {
			refracted = ni_over_nt * (uv - n * dt) - n * sqrt(discriminant);
			return true;
			} else {
				return false;
				}
		}

		float schlick(float cosine, float ref_idx) {
			float r0 = (1-ref_idx) / (1 + ref_idx);
			r0 = r0 * r0;
			return r0 + (1 - r0) * pow((1- cosine), 5);
			}

		struct sphere
			{
				vec3 center;
				float radius;
				// material:
				vec3 albedo;
				bool isMetal;
				bool dialectric;
				float fuzz;

				bool intersect(ray r, float t_min, float t_max, out hit_record record) {
					record.index = 0;

					vec3 oc = r.origin - center;
					float a = dot(r.direction, r.direction);
					float b = dot(oc, r.direction);
					float c = dot(oc, oc) - radius*radius;

					float discriminant = b * b - a * c;

					if (discriminant > 0) {
						float solution = (-b - sqrt(discriminant)) / a;
						if (solution < t_max && solution > t_min) {
							record.t = solution;
							record.position = r.point_at(record.t);
							record.normal = (record.position - center) / radius;
							return true;
						}
						solution = (-b + sqrt(discriminant)) / a;
						if (solution < t_max && solution > t_min) {
							record.t = solution;
							record.position = r.point_at(record.t);
							record.normal = (record.position - center) / radius;
							return true;
						}
					}
					return false;
				}

				

				bool scatter(ray r_in, hit_record record, out vec3 attenuation, out ray scattered) {
					if (isMetal) {
						vec3 reflected = reflect(normalize(r_in.direction), record.normal);
						scattered = ray::from(record.position, reflected + fuzz * random_in_unit_sphere());
						attenuation = albedo;
						return (dot(scattered.direction, record.normal) > 0);

					} 
					else if (dialectric) {
						vec3 outwardNormal;
						vec3 reflected = reflect(normalize(r_in.direction), record.normal);
						float ni_over_nt;
						attenuation = vec3(1.0, 1.0, 1.0); // glass does not absorb light
						vec3 refracted;
						float cosine;
						float reflect_prob;

						float dotDirNorm = dot(r_in.direction, record.normal);

						// Assume fuzz holds the refractive index for dielectrics
						float ref_idx = fuzz;

						if (dotDirNorm > 0.0) {
							outwardNormal = -record.normal;
							ni_over_nt = ref_idx;
							cosine = ref_idx * dotDirNorm / length(r_in.direction);
						} else {
							outwardNormal = record.normal;
							ni_over_nt = 1.0 / ref_idx;
							cosine = -dotDirNorm / length(r_in.direction);
						}

						bool canRefract = refract(r_in.direction, outwardNormal, ni_over_nt, refracted);

						if (canRefract) {
							reflect_prob = schlick(cosine, ref_idx);
						} else {
							reflect_prob = 1.0;
						}

						if (random_number() < reflect_prob) {
							scattered = ray::from(record.position, reflected);
						} else {
							scattered = ray::from(record.position, refracted);
						}

						return true;
					}

					else {
						vec3 target = record.position + record.normal + random_in_unit_sphere();
						scattered = ray::from(record.position, target - record.position);
						attenuation = albedo;
						return true;
					}
				}
			};

		static const uint NUMBER_OF_SPHERES = 5;
	

	static const sphere WORLD[NUMBER_OF_SPHERES] = {
    { vec3(0.0, 0.0, -1.0), 0.5, vec3(0.1, 0.2, 0.5), false, false, 0.0 },  // Lambertian
    { vec3(0.0, -100.5, -1.0), 100.0, vec3(0.8, 0.8, 0.0), false, false, 0.0 },  // Ground Lambertian
    { vec3(1.0, 0.0, -1.0), 0.5, vec3(0.8, 0.6, 0.2), true, false, 0.0 },   // Metal
    { vec3(-1.0, 0.0, -1.0), 0.5, vec3(1.0, 1.0, 1.0), false, true, 1.5 },
	{ vec3(-1.0, 0.0, -1.0), -0.45, vec3(1.0, 1.0, 1.0), false, true, 1.5 } // Dielectric (ref_idx = 1.5)
};


			bool intersect_world(ray r, float t_min, float t_max, out hit_record record) {
				hit_record temp_record;
				bool intersected = false;
				float closest = t_max;

				for (uint i = 0; i < NUMBER_OF_SPHERES; i++) {
					sphere s = WORLD[i];
					
					
					if (s.intersect(r, t_min, closest, temp_record)) {
						intersected = true;
						closest = temp_record.t;
						record = temp_record;
						record.index = i;
						
					}
				}
			
				return intersected;
			}

			vec3 background(ray r) {
				float t = 0.5 * (normalize(r.direction).y + 1.0);
				return lerp(vec3(1.0, 1.0, 1.0), vec3(0.5, 0.7, 1.0), t);
			}


	vec3 trace(ray r) {

				vec3 color = vec3(1.0, 1.0, 1.0);

				hit_record record;

				uint i = 0;
				while ((i < MAXIMUM_DEPTH) && intersect_world(r, 0.001, 100000.0, record)) {

					ray scattered;
					vec3 attenuation;

					WORLD[record.index].scatter(r, record, attenuation, scattered);

					r = scattered;
					color *= attenuation;

					i += 1;
				}

				if (i == MAXIMUM_DEPTH) {
					return vec3(0.0, 0.0, 0.0);
				}
				else {
					return color * background(r);
				}
			}


	vec3 reflect(vec3 v, vec3 n) {
		return v - 2 * dot(v,n) * n;
		}




			fixed4 frag(v2f i) : SV_Target
			{
				camera cam = camera::create();

				float u = i.uv.x;
				float v = i.uv.y;

				rand_uv = i.uv;

				col3 col = col3(0.0, 0.0, 0.0);

				for (uint i = 0; i < NUMBER_OF_SAMPLES; i++) {
					float du = random_number() / _ScreenParams.x;
					float dv = random_number() / _ScreenParams.y;

					ray r = cam.get_ray(u + du, v + dv);
					col += col3(trace(r));
				}

				col /= NUMBER_OF_SAMPLES;
				
				col = sqrt(col);

				return fixed4(col, 1.0);
			}
			
			ENDCG
		}
	}
}