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

// A amostragem de texturas sRGB neste shader entrega valores lineares
// sem recodificação na saída, o que escurecia as imagens (medição:
// exibido = decode(original), com pretos 40 -> 5). A curva abaixo é a
// inversa exata e devolve os tons originais.
vec3 linear_to_srgb(vec3 c) {
	vec3 lo = c * 12.92;
	vec3 hi = 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055;
	return mix(lo, hi, step(vec3(0.0031308), c));
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	if (sd_round_box(p, vec2(0.5), radius) > 0.0) {
		discard;
	}
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(linear_to_srgb(tex.rgb), tex.a);
}
