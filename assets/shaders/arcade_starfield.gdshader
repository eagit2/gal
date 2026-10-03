shader_type canvas_item;
// Arcade Classic+ background (concept P1, Arcade '81 mode): black with a scrolling field of
// twinkling square stars in the 1981 arcade palette.

uniform vec2 size = vec2(540.0, 960.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.1))) * 15731.743);
}

vec3 star_layer(vec2 p, float cell, float speed, float seed) {
	vec2 q = vec2(p.x, p.y - TIME * speed) / cell;
	vec2 id = floor(q);
	float h = hash(id + seed);
	if (h < 0.9) {
		return vec3(0.0);
	}
	vec2 pos = vec2(hash(id + seed + 3.1), hash(id + seed + 5.7)) * (cell - 3.0);
	vec2 local = fract(q) * cell - pos;
	float on = step(0.0, local.x) * step(local.x, 2.0) * step(0.0, local.y) * step(local.y, 2.0);
	float twinkle = step(0.35, fract(TIME * (0.5 + h) + h * 9.0));
	vec3 tint = vec3(hash(id + 1.0), hash(id + 2.0), hash(id + 3.0));
	tint = step(0.5, tint) * 0.7 + 0.3;
	return tint * on * twinkle;
}

void fragment() {
	vec2 p = floor(UV * size);
	vec3 col = star_layer(p, 24.0, 60.0, 0.0) + star_layer(p, 40.0, 30.0, 11.0) * 0.7;
	COLOR = vec4(col, 1.0);
}
