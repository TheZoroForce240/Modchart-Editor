#pragma header

//written by TheZoroForce240

uniform float zoom;
uniform float angle;
uniform float iTime;

uniform float x;
uniform float y;

uniform float warp;

varying vec3 perlinOffsets;

vec2 getUV( vec2 uv )
{
	uv.x += x + perlinOffsets.x;
	uv.y += y + perlinOffsets.y;
	
	//funny mirroring shit
	if ((uv.x > 1.0 || uv.x < 0.0) && abs(mod(uv.x, 2.0)) > 1.0)
		uv.x = -uv.x + 1.0;
	if ((uv.y > 1.0 || uv.y < 0.0) && abs(mod(uv.y, 2.0)) > 1.0)
		uv.y = -uv.y + 1.0;

	return vec2(abs(mod(uv.x, 1.0)), abs(mod(uv.y, 1.0)));
}

void main()
{	
	vec2 uv = openfl_TextureCoordv.xy;

	mat2 scaling = mat2(zoom, 0.0, 0.0, zoom );

	float rad = radians(angle + perlinOffsets.z);
	mat2 rotation = mat2(cos(rad), -sin(rad), sin(rad), cos(rad) );

	//used to stretch back into 16:9
	//0.5625 is from 9/16
	mat2 aspectRatioScale = mat2(0.5625, 0.0, 0.0, 1.0 );
	//need to do this otherwise rotation breaks the aspect ratio
	vec2 aspectRatio = vec2(16.0, 9.0);
	vec2 fragCoord = aspectRatio * uv;
	uv = ( fragCoord - 0.5 * aspectRatio ) * 0.111111; //0.111111 = 1/9, faster to multiply

	//apply scale/warp/rotation
	uv = uv * scaling;
	float dist = length(uv);
	uv *= (1.0 + warp*dist*dist);
	uv = (aspectRatioScale) * (rotation * uv);
	uv += vec2(0.5, 0.5); //move back to center
	
	gl_FragColor = flixel_texture2D(bitmap, getUV(uv));
}