// Bloom shader - Pass 1: Extracts bright pixels
// Based on moonshine glow approach

extern float min_luma = 0.7; // Brightness threshold

vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
{
  vec4 c = Texel(tex, tc);
  float luma = dot(vec3(0.299, 0.587, 0.114), c.rgb);
  // Return bright pixels, discard dark ones
  return c * step(min_luma, luma) * colour;
}

