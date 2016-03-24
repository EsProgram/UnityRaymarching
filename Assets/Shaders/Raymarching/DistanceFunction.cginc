/*******************************************************************
*http://glslsandbox.com/e#23658*************************************
*http://iquilezles.org/www/articles/distfunctions/distfunctions.htm*
*******************************************************************/

#ifndef DISTANCE_FUNCTION
#define DISTANCE_FUNCTION

#include "UnityCG.cginc"

#ifndef PI
#define PI 3.14159265359
#endif //PI

////////////////////////////////////////////////////////////////////////////
//                                Primitive                               //
////////////////////////////////////////////////////////////////////////////
float sphere(float3 pos, float radius)
{
	return length(pos) - radius;
}

float round_box(float3 pos, float3 size, float round)
{
	return length(max(abs(pos) - size * 0.5, 0.0)) - round;
}

float box(float3 pos, float3 size)
{
	return round_box(pos, size, 0);
}

float torus(float3 pos, float2 radius)
{
	float2 r = float2(length(pos.xy) - radius.x, pos.z);
	return length(r) - radius.y;
}

float floor(float3 pos)
{
	return dot(pos, float3(0.0, 1.0, 0.0)) + 1.0;
}

float cylinder(float3 pos, float2 r) {
	float2 d = abs(float2(length(pos.xy), pos.z)) - r;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - 0.1;
}

////////////////////////////////////////////////////////////////////////////
//                                  Helper                                //
////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////
//                               FunctionMain                             //
////////////////////////////////////////////////////////////////////////////

float kaleidoscopic_IFS(float3 z)
{
	const int FRACT_ITER = 20;
	float FRACT_SCALE = 1.8;
	float FRACT_OFFSET = 1.0;

	float c = 2.0;
	z.y = mod(z.y, c) - c / 2.0;
	z = rotate_z(z, PI / 2.0);
	float r;
	int n1 = 0;
	for (int n = 0; n < FRACT_ITER; n++) {
		float rotate = PI*0.5;
		z = rotate_x(z, rotate);
		z = rotate_y(z, rotate);
		z = rotate_z(z, rotate);

		z.xy = abs(z.xy);
		if (z.x + z.y < 0.0) z.xy = -z.yx; // fold 1
		if (z.x + z.z < 0.0) z.xz = -z.zx; // fold 2
		if (z.y + z.z < 0.0) z.zy = -z.yz; // fold 3
		z = z*FRACT_SCALE - FRACT_OFFSET*(FRACT_SCALE - 1.0);
	}
	return (length(z)) * pow(FRACT_SCALE, -float(FRACT_ITER));
}

float tglad_formula(float3 z0)
{
	z0 = mod(z0, 2.);

	float mr = 0.25, mxr = 1.0;
	float4 scale = float4(-3.12, -3.12, -3.12, 3.12), p0 = float4(0.0, 1.59, -1.0, 0.0);
	float4 z = float4(z0, 1.0);
	for (int n = 0; n < 3; n++) {
		z.xyz = clamp(z.xyz, -0.94, 0.94)*2.0 - z.xyz;
		z *= scale / clamp(dot(z.xyz, z.xyz), mr, mxr)*1.;
		z += p0;
	}
	float dS = (length(max(abs(z.xyz) - float3(1.2, 49.0, 1.4), 0.0)) - 0.06) / z.w;
	return dS;
}

// distance function from Hartverdrahtet
// ( http://www.pouet.net/prod.php?which=59086 )
float hartverdrahtet(float3 f)
{
	float3 cs = float3(.808, .808, 1.167);
	float fs = 1.;
	float3 fc = float3(0, 0, 0);
	float fu = 10.;
	float fd = .763;

	// scene selection
	int i = mod(_Time.x / 2.0, 9.0);
	if (i == 0) cs.y = .58;
	if (i == 1) cs.xy = float2(0.5, 0.5);
	if (i == 2) cs.xy = float2(0.5, 0.5);
	if (i == 3) fu = 1.01, cs.x = .9;
	if (i == 4) fu = 1.01, cs.x = .9;
	if (i == 6) cs = float3(.5, .5, 1.04);
	if (i == 5) fu = .9;
	if (i == 7) fd = .7, fs = 1.34, cs.xy = float2(0.5, 0.5);
	if (i == 8) fc.z = -.38;

	//cs += sin(time)*0.2;

	float v = 1.;
	for (int loop = 0; loop < 12; loop++) {
		f = 2.*clamp(f, -cs, cs) - f;
		float c = max(fs / dot(f, f), 1.);
		f *= c;
		v *= c;
		f += fc;
	}
	float z = length(f.xy) - fu;
	return fd*max(z, abs(length(f.xy)*f.z) / sqrt(dot(f, f))) / abs(v);
}

float pseudo_kleinian(float3 p)
{
	const float3 CSize = float3(0.92436, 0.90756, 0.92436);
	const float Size = 1.0;
	const float3 C = float3(0.0, 0.0, 0.0);
	float DEfactor = 1.;
	const float3 Offset = float3(0.0, 0.0, 0.0);
	float3 ap = p + 1.;
	for (int i = 0; i < 10; i++) {
		ap = p;
		p = 2.*clamp(p, -CSize, CSize) - p;
		float r2 = dot(p, p);
		float k = max(Size / r2, 1.);
		p *= k;
		DEfactor *= k;
		p += C;
	}
	float r = abs(0.5*abs(p.z - Offset.z) / DEfactor);
	return r;
}

float pseudo_knightyan(float3 p)
{
	const float3 CSize = float3(0.63248, 0.78632, 0.775);
	float DEfactor = 1.;
	for (int i = 0; i < 6; i++) {
		p = 2.*clamp(p, -CSize, CSize) - p;
		float k = max(0.70968 / dot(p, p), 1.);
		p *= k;
		DEfactor *= k*1.1;
	}
	float rxy = length(p.xy);
	return max(rxy - 0.92784, abs(rxy*p.z) / length(p)) / DEfactor;
}

float repeat_sphere(float3 p, float radius, float3 repeat_span) {
	p = repeat(p, repeat_span);
	return sphere(p, radius);
}

float repeat_round_box(float3 p, float box_size, float box_round, float3 repeat_span) {
	p = repeat(p, repeat_span);
	return round_box(p, box_size, box_round);
}

float repeat_torus(float3 p, float2 radius, float3 repeat_span) {
	p = repeat(p, repeat_span);
	return torus(p, radius);
}

float repeat_round_box_rotate_around_own(float3 p, float box_size, float box_round, float angle, float3 axis, float3 repeat_span) {
	p = repeat(p, repeat_span);
	p = rotate(p, angle, axis);
	return round_box(p, box_size, box_round);
}

float repeat_torus_rotate_around_own(float3 p, float2 radius, float angle, float3 axis, float3 repeat_span) {
	p = repeat(p, repeat_span);
	p = rotate(p, angle, axis);
	return torus(p, radius);
}

float additive_pseudo_knightyan(float3 p) {
	const float SPAN = 0.7;
	const float SIZE = 0.1;

	float main_box = repeat_round_box_rotate_around_own(p, (SIZE * 0.7) * abs(_CosTime.z), 0.02, radians(90 * _Time.y), float3(1, 1, 1), SPAN);
	float op_prim = repeat_sphere(p, SIZE * 0.7, SPAN);
	float t1 = repeat_torus_rotate_around_own(p, abs(_CosTime.z) * float2(SIZE*1.13, 0.008), radians(90 * _Time.y), float3(1, -1, 1), SPAN);
	float t2 = repeat_torus_rotate_around_own(p, abs(_CosTime.z) * float2(SIZE, 0.008), radians(90 + 90 * _Time.y), float3(-1, 1, -1), SPAN);

	return op_union(op_union(op_union(op_substract(op_prim, main_box), t1), t2), pseudo_knightyan(p));
}
#endif //DISTANCE_FUNCTION