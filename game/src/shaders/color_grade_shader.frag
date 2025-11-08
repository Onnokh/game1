// Color grading shader
// Applies RGB multipliers for color correction

extern vec3 factors;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc)
{
  vec4 original = Texel(texture, tc);
  vec4 graded = vec4(factors, 1.0) * original;
  return graded * color;
}


