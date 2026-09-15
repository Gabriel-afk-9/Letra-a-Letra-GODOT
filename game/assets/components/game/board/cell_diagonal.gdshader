shader_type canvas_item;
uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform float radius = 5.0;
void fragment() {
	vec2 size = vec2(30.0, 30.0);
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
	vec4 col = (uv.y > uv.x) ? color_a : color_b;
	COLOR = col;
}
