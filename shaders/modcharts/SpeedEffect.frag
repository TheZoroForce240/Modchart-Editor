#pragma header

uniform float iTime;
uniform float effect;

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
	vec3 a = floor(p);
	vec3 d = p - a;
	d = d * d * (3.0 - 2.0 * d);

	vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
	vec4 k1 = perm(b.xyxy);
	vec4 k2 = perm(k1.xyxy + b.zzww);

	vec4 c = k2 + a.zzzz;
	vec4 k3 = perm(c);
	vec4 k4 = perm(c + 1.0);

	vec4 o1 = fract(k3 * (1.0 / 41.0));
	vec4 o2 = fract(k4 * (1.0 / 41.0));

	vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
	vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

	return o4.y * d.y + o4.x * (1.0 - d.y);
}

float speed = 25.0;
float size = 50.0;
float reduction = 0.55;
float cutoff = 0.2;

void main()
{
	
	
	vec2 uv = openfl_TextureCoordv.xy;
	vec4 Color = flixel_texture2D(bitmap, uv);
	
	vec2 centeredUV = uv-0.5;
	
	float dist = length(centeredUV);
	
	vec2 dir = normalize(centeredUV) * (size + noise(vec3(iTime)));
	
	float amount = noise(vec3(dir, iTime*speed)) * noise(vec3(dir, iTime*speed*1.2));
	
	amount *= smoothstep(cutoff, 0.7, dist);
	
	if (amount > 0.2)
		amount *= 3.0;
	else
		amount = 0.0;
		
	if (noise(vec3(dir, iTime)) > effect)
		amount = 0.0;
	
	Color.rgb += amount;
	
	
	//Color.rgb += dist;
	

	gl_FragColor = Color;
}