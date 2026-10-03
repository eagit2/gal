shader_type canvas_item;
// Cold Hologram background (concept N3, Lock-On mode): deep navy, a slow scrolling cyan
// targeting grid, faint scanlines and a soft vignette.

uniform vec2 size = vec2(540.0, 960.0);
uniform vec4 base_color : source_color = vec4(0.012, 0.035, 0.078, 1.0);
uniform vec4 line_color : source_color = vec4(0.4, 0.95, 1.0, 1.0);
uniform float cell = 48.0;
uniform float speed = 22.0;

float line(float coord) {
	float d = abs(fract(coord - 0.5) - 0.5) / max(fwidth(coord), 1e-4);
	return clamp(1.0 - d, 0.0, 1.0) + exp(-d / 2.5) * 0.25;
}

void fragment() {
	vec2 p = UV * size;
	vec2 g = vec2(p.x, p.y - TIME * speed) / cell;
	float grid = max(line(g.x), line(g.y)) * 0.32;
	// Brighter ticks every 4 cells.
	grid += max(line(g.x / 4.0), line(g.y / 4.0)) * 0.3;
	float scan = 0.06 * step(0.5, fract(p.y / 3.0));
	float sweep = exp(-abs(fract(TIME * 0.12) * size.y * 1.4 - p.y) / 40.0) * 0.25;
	float vignette = smoothstep(0.95, 0.3, length(UV - 0.5));
	vec3 col = base_color.rgb + line_color.rgb * (grid + sweep) - scan;
	COLOR = vec4(col * mix(0.55, 1.0, vignette), 1.0);
}
