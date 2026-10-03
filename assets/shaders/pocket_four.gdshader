shader_type canvas_item;
// Pocket Four post-process (concept P3, Graze mode): maps the screen to a 4-shade handheld green
// palette with a light ordered dither, so the base pixel art reads as a pocket console.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 shade0 : source_color = vec4(0.06, 0.22, 0.06, 1.0);
uniform vec4 shade1 : source_color = vec4(0.19, 0.38, 0.19, 1.0);
uniform vec4 shade2 : source_color = vec4(0.55, 0.67, 0.06, 1.0);
uniform vec4 shade3 : source_color = vec4(0.61, 0.74, 0.06, 1.0);

void fragment() {
	vec3 col = texture(screen_texture, SCREEN_UV).rgb;
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	vec2 cell = mod(floor(FRAGCOORD.xy / 2.0), 2.0);
	float dither = (cell.x * 2.0 + cell.y - 1.5) * 0.06;
	l = clamp(l * 1.2 + dither, 0.0, 0.999);
	int i = int(l * 4.0);
	COLOR = i == 0 ? shade0 : (i == 1 ? shade1 : (i == 2 ? shade2 : shade3));
}
