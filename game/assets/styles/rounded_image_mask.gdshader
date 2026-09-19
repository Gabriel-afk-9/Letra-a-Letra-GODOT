shader_type canvas_item;

// Recorta a textura em um retângulo arredondado no espaço UV, de modo
// que a imagem preencha o card sem vazar para fora do contorno.
// O raio é propositalmente generoso: a borda arredondada desenhada por
// cima define o limite visível e cobre a transição da máscara.
uniform float radius : hint_range(0.0, 0.5) = 0.2;

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	if (sd_round_box(p, vec2(0.5), radius) > 0.0) {
		discard;
	}
	COLOR = texture(TEXTURE, UV) * COLOR;
}
