shader_type canvas_item;
// Blends a sprite toward white for hit feedback. `flash` 0..1 is driven by DamageFx.

uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a);
}
