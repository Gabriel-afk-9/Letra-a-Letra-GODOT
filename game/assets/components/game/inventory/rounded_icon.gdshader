shader_type canvas_item;
uniform float radius = 12.0;
uniform float desaturation : hint_range(0.0,1.0) = 0.0;
void fragment() {
	vec2 size = vec2(52.0, 52.0);
	vec2 uv = UV;
	vec2 pos = uv * size;
	float r = radius;
	if (pos.x < r && pos.y < r) {
		if (distance(pos, vec2(r, r)) > r) discard;
	} else if (pos.x > size.x - r && pos.y < r) {
		if (distance(pos, vec2(size.x - r, r)) > r) discard;
	} else if (pos.x < r && pos.y > size.y - r) {
		if (distance(pos, vec2(r, size.y - r)) > r) discard;
	} else if (pos.x > size.x - r && pos.y > size.y - r) {
		if (distance(pos, vec2(size.x - r, size.y - r)) > r) discard;
	}
	vec4 c = texture(TEXTURE, uv);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(lum), desaturation);
	COLOR = c;
}
