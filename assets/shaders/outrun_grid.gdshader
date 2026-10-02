shader_type canvas_item;
// Outrun Grid background (concept N1): striped sunset sun over a scrolling perspective grid.
// Glow is computed in the shader so it works on the web Compatibility renderer without post-processing.

uniform vec2 size = vec2(540.0, 960.0);
uniform float horizon = 300.0;
uniform float speed = 0.9;
uniform vec4 sky_top : source_color = vec4(0.02, 0.004, 0.059, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.169, 0.039, 0.29, 1.0);
uniform vec4 floor_color : source_color = vec4(0.04, 0.008, 0.094, 1.0);
uniform vec4 grid_color : source_color = vec4(1.0, 0.247, 0.847, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.176, 0.886, 0.902, 1.0);
uniform vec4 sun_top : source_color = vec4(1.0, 0.827, 0.098, 1.0);
uniform vec4 sun_bottom : source_color = vec4(1.0, 0.161, 0.459, 1.0);
uniform float sun_radius = 120.0;

float grid_line(float coord, float glow_width) {
	float d = abs(fract(coord - 0.5) - 0.5) / max(fwidth(coord), 1e-4);
	return clamp(1.0 - d, 0.0, 1.0) + exp(-d / glow_width) * 0.35;
}

void fragment() {
	vec2 p = UV * size;
	vec3 col;
	if (p.y < horizon) {
		col = mix(sky_top.rgb, sky_bottom.rgb, p.y / horizon);
		vec2 to_sun = p - vec2(size.x * 0.5, horizon - 10.0);
		float dist = length(to_sun);
		float t = clamp((p.y - (horizon - 10.0 - sun_radius)) / sun_radius, 0.0, 1.0);
		// Horizontal cut stripes get thicker toward the horizon.
		float band = mod(horizon - p.y, 16.0);
		bool cut = t > 0.45 && band < (t - 0.45) * 14.0;
		if (dist < sun_radius && !cut) {
			col = mix(sun_top.rgb, sun_bottom.rgb, t);
		}
		col += sun_bottom.rgb * exp(-max(dist - sun_radius, 0.0) / 40.0) * 0.35;
	} else {
		float depth = max(p.y - horizon, 1.0);
		float z = 2400.0 / depth + TIME * speed * 8.0;
		float x = (p.x - size.x * 0.5) / depth * 6.0;
		float fade = clamp(depth / 220.0, 0.0, 1.0);
		float lines = max(grid_line(z * 0.25, 2.0), grid_line(x, 2.0));
		col = mix(floor_color.rgb, grid_color.rgb, lines * (0.25 + 0.75 * fade));
		col += horizon_color.rgb * exp(-depth / 6.0);
	}
	COLOR = vec4(col, 1.0);
}
