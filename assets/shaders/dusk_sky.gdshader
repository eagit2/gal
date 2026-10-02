shader_type canvas_item;
// Dusk Armada background (concept P2): banded sunset with ordered dithering and drifting cloud bands.

uniform vec2 size = vec2(540.0, 960.0);
uniform float pixel = 2.0;
uniform vec4 c0 : source_color = vec4(0.078, 0.039, 0.157, 1.0);
uniform vec4 c1 : source_color = vec4(0.247, 0.086, 0.325, 1.0);
uniform vec4 c2 : source_color = vec4(0.451, 0.129, 0.373, 1.0);
uniform vec4 c3 : source_color = vec4(0.698, 0.22, 0.365, 1.0);
uniform vec4 c4 : source_color = vec4(0.91, 0.392, 0.314, 1.0);
uniform vec4 c5 : source_color = vec4(0.988, 0.647, 0.302, 1.0);
uniform vec4 cloud : source_color = vec4(0.133, 0.063, 0.227, 1.0);

float bayer4(vec2 q) {
	int x = int(mod(q.x, 4.0));
	int y = int(mod(q.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[i] / 16.0;
}

void fragment() {
	vec2 q = floor(UV * size / pixel);
	float h = q.y / (size.y / pixel);
	float level = h * 5.0 + (bayer4(q) - 0.5) * 0.9;
	int band = clamp(int(floor(level)), 0, 5);
	vec4 bands[6] = vec4[](c0, c1, c2, c3, c4, c5);
	vec3 col = bands[band].rgb;
	// Two parallax cloud layers drifting down.
	for (int layer = 0; layer < 2; layer++) {
		float speed = layer == 0 ? 6.0 : 15.0;
		float y = q.y * pixel - TIME * speed;
		float wave = sin(q.x * pixel * 0.012 + float(layer) * 2.1 + floor(y / 180.0) * 1.7) * 18.0;
		float d = mod(y + wave, 180.0 + float(layer) * 70.0);
		if (d < 14.0 + float(layer) * 6.0 && bayer4(q + float(layer)) < 0.8 - float(layer) * 0.3) {
			col = mix(col, cloud.rgb, 0.55 + 0.25 * float(layer));
		}
	}
	COLOR = vec4(col, 1.0);
}
