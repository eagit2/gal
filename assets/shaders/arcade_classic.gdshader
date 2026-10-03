shader_type canvas_item;
// Arcade Classic+ post-process (concept P1): punchy saturated colors with posterized steps and
// faint scanlines, like a 1981 cabinet.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float saturation = 1.6;
uniform float steps = 5.0;

void fragment() {
	vec3 col = texture(screen_texture, SCREEN_UV).rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = clamp(mix(vec3(l), col, saturation), 0.0, 1.0);
	col = floor(col * steps + 0.5) / steps;
	col *= 0.9 + 0.1 * step(0.5, fract(FRAGCOORD.y / 3.0));
	COLOR = vec4(col, 1.0);
}
