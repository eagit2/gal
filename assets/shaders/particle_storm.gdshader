shader_type canvas_item;
// Particle Storm background (concept N2, Chain Reaction mode): near-black with layers of
// drifting embers that streak downward, plus a warm pulse from the bottom.

uniform vec2 size = vec2(540.0, 960.0);
uniform vec4 base_color : source_color = vec4(0.03, 0.012, 0.02, 1.0);
uniform vec4 ember_hot : source_color = vec4(1.0, 0.85, 0.45, 1.0);
uniform vec4 ember_cool : source_color = vec4(1.0, 0.25, 0.3, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float embers(vec2 p, float scale, float speed, float seed) {
	vec2 q = p / scale;
	q.y -= TIME * speed;
	vec2 id = floor(q);
	vec2 f = fract(q);
	float h = hash(id + seed);
	if (h < 0.75) {
		return 0.0;
	}
	vec2 c = vec2(hash(id + seed + 1.3), hash(id + seed + 7.1)) * 0.8 + 0.1;
	vec2 d = (f - c) * vec2(1.0, 0.35);  // vertical streaks
	return exp(-dot(d, d) * 420.0) * (h - 0.75) * 4.0;
}

void fragment() {
	vec2 p = UV * size;
	float e = embers(p, 34.0, 2.6, 0.0) + embers(p, 58.0, 1.6, 4.0) * 0.8 + embers(p, 96.0, 0.9, 9.0) * 0.6;
	float pulse = (0.5 + 0.5 * sin(TIME * 3.0)) * 0.12 * smoothstep(0.6, 1.0, UV.y);
	vec3 col = base_color.rgb + mix(ember_cool.rgb, ember_hot.rgb, clamp(e, 0.0, 1.0)) * e + ember_cool.rgb * pulse;
	COLOR = vec4(col, 1.0);
}
