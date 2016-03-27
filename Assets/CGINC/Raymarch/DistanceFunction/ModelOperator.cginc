#ifndef MODEL_OPERATOR
#define MODEL_OPERATOR

float3 mod(float3 a, float3 b)
{
	return frac(abs(a / b)) * abs(b);
}

float3 repeat(float3 pos, float3 span)
{
	return mod(pos, span) - span * 0.5;
}

float3 rotate_x(float3 p, float angle)
{
	float c = cos(angle);
	float s = sin(angle);
	return float3(p.x, c*p.y + s*p.z, -s*p.y + c*p.z);
}

float3 rotate_y(float3 p, float angle)
{
	float c = cos(angle);
	float s = sin(angle);
	return float3(c*p.x - s*p.z, p.y, s*p.x + c*p.z);
}

float3 rotate_z(float3 p, float angle)
{
	float c = cos(angle);
	float s = sin(angle);
	return float3(c*p.x + s*p.y, -s*p.x + c*p.y, p.z);
}

float3 rotate(float3 p, float angle, float3 axis)
{
	float3 a = normalize(axis);
	float s = sin(angle);
	float c = cos(angle);
	float r = 1.0 - c;
	float3x3 m = float3x3(
		a.x * a.x * r + c,
		a.y * a.x * r + a.z * s,
		a.z * a.x * r - a.y * s,
		a.x * a.y * r - a.z * s,
		a.y * a.y * r + c,
		a.z * a.y * r + a.x * s,
		a.x * a.z * r + a.y * s,
		a.y * a.z * r - a.x * s,
		a.z * a.z * r + c
		);
	return mul(m, p);
}

float3 twist_x(float3 p, float power)
{
	float s = sin(power * p.y);
	float c = cos(power * p.y);
	float3x3 m = float3x3(
		1.0, 0.0, 0.0,
		0.0, c, s,
		0.0, -s, c
		);
	return mul(m, p);
}

float3 twist_y(float3 p, float power)
{
	float s = sin(power * p.y);
	float c = cos(power * p.y);
	float3x3 m = float3x3(
		c, 0.0, -s,
		0.0, 1.0, 0.0,
		s, 0.0, c
		);
	return mul(m, p);
}

float3 twist_z(float3 p, float power)
{
	float s = sin(power * p.y);
	float c = cos(power * p.y);
	float3x3 m = float3x3(
		c, s, 0.0,
		-s, c, 0.0,
		0.0, 0.0, 1.0
		);
	return mul(m, p);
}

float op_union(float d1, float d2)
{
	return min(d1, d2);
}

float op_substract(float d1, float d2)
{
	return max(-d1, d2);
}

float op_intersect(float d1, float d2)
{
	return max(d1, d2);
}

#endif //MODEL_OPERATOR