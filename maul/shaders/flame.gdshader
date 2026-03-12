shader_type canvas_item;

uniform int   particleCount : hint_range(16, 256)  = 64;
uniform float speed         : hint_range(0.1, 5.0) = 1.0;
uniform float pixelSize     : hint_range(0.001, 0.1) = 0.025;
uniform float brightness    : hint_range(0.0001, 0.02) = 0.0012;
uniform float fireShift     : hint_range(0.0, 0.5)  = 0.18;
uniform float fireShiftFreq : hint_range(1.0, 10.0) = 5.0;
uniform vec3  fromColor                             = vec3(0.9, 0.2, 0.1);
uniform vec3  toColor                               = vec3(0.4, 0.35, 0.2);
uniform float flickerStrength : hint_range(0.0, 0.5) = 0.18;
uniform int   sparkCount    : hint_range(1, 50)    = 14;
uniform float sparkSize     : hint_range(0.0005, 0.008) = 0.004;
uniform float sparkSpeed    : hint_range(0.1, 3.0)  = 0.2;
uniform int   smokeCount    : hint_range(5, 50)    = 12;
uniform float smokeSize     : hint_range(0.001, 0.05) = 0.012;
uniform float smokeDrift    : hint_range(0.0, 0.5)  = 0.18;
uniform float windForce     : hint_range(-0.5, 0.5) = 0.0;
uniform float hueShift      : hint_range(-1.0, 1.0) = 0.0;
uniform float saturation    : hint_range(0.0, 2.0)  = 1.2;
uniform float aspectRatio   : hint_range(0.1, 5.0)  = 0.667;
uniform vec2  posOffset                             = vec2(0.0, 0.35);
uniform float alpha         : hint_range(0.0, 1.0)  = 0.92;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

vec3 shift_hue(vec3 col, float h) {
	if (abs(h) < 0.001) return col;
	vec3 k = vec3(0.57735);
	float c = cos(h * TAU);
	return col * c + cross(k, col) * sin(h * TAU) + k * dot(k, col) * (1.0 - c);
}

vec3 set_saturation(vec3 col, float s) {
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	return mix(vec3(lum), col, s);
}

void fragment() {
	vec2 uv = UV - posOffset;
	uv.x = (uv.x - 0.5) * aspectRatio + 0.5;

	// Pixelation
	uv = floor(uv / pixelSize) * pixelSize;

	float t = TIME * speed;

	// Flicker
	float flicker = 1.0 + flickerStrength * (hash(floor(t * 10.0)) * 2.0 - 1.0);

	// --- Fire ---
	float fire = 0.0;
	for (int i = 0; i < particleCount; i++) {
		float fi   = float(i);
		float s1   = hash(fi * 7.31 + 1.3);
		float s2   = hash(fi * 3.17 + 2.7);
		float life = fract(s1 * 0.7 + t * (0.3 + s2 * 0.4));
		float px   = (s1 - 0.5) * fireShift * sin(t * fireShiftFreq + fi)
		             + windForce * life * 0.3;
		vec2  pp   = vec2(0.5 + px, 1.0 - life);
		float dist = length((uv - pp) * vec2(1.0, 0.55));
		float sz   = brightness * flicker * (1.0 - life * 0.65);
		fire += sz / (dist * dist + 0.00008);
	}

	// --- Sparks ---
	float sparks = 0.0;
	for (int i = 0; i < sparkCount; i++) {
		float fi   = float(i);
		float s1   = hash(fi * 13.71 + 5.3);
		float s2   = hash(fi * 7.19  + 8.1);
		float s3   = hash(fi * 2.33  + 3.9);
		float life = fract(s3 + t * sparkSpeed * (0.5 + s1 * 0.5));
		float px   = (s1 - 0.5) * 0.28 + windForce * life * 0.5;
		vec2  sp   = vec2(0.5 + px, 1.0 - life * 1.15);
		float dist = length(uv - sp);
		float fade = 1.0 - life;
		sparks += sparkSize * fade / (dist * dist + 0.00008);
	}

	// --- Smoke ---
	float smoke = 0.0;
	for (int i = 0; i < smokeCount; i++) {
		float fi   = float(i);
		float s1   = hash(fi * 5.43 + 1.1);
		float s2   = hash(fi * 9.87 + 4.2);
		float life = fract(s2 + t * 0.14);
		float px   = (s1 - 0.5) * smokeDrift + windForce * life * 0.3
		             + sin(t * 0.5 + fi) * 0.04;
		vec2  sm   = vec2(0.5 + px, 1.0 - 0.25 - life * 0.85);
		float dist = length(uv - sm);
		float fade = life * (1.0 - life) * 4.0;
		smoke += smokeSize * fade / (dist * dist + 0.00008);
	}

	fire  = clamp(fire,  0.0, 1.0);
	sparks = clamp(sparks, 0.0, 1.0);
	smoke = clamp(smoke, 0.0, 0.35);

	// Color composition
	vec3 col = mix(toColor, fromColor, fire);
	col += sparks * fromColor * 2.2;
	col += smoke  * vec3(0.28, 0.28, 0.32);

	col = shift_hue(col, hueShift);
	col = set_saturation(col, saturation);

	float total_a = clamp((fire + sparks * 0.6 + smoke * 0.25) * alpha, 0.0, 1.0);

	COLOR = vec4(col, total_a);
}
