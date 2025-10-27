// Bloom blur shader - Gaussian blur with configurable direction and strength
// Based on moonshine approach

extern vec2 direction; // Blur direction (e.g., (1,0) for horizontal, (0,1) for vertical)
extern float strength = 5.0; // Blur strength/radius multiplier

vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
{
  vec4 c = vec4(0.0);

  // Calculate scaled direction based on strength
  vec2 scaledDir = direction * (strength / 5.0);

  // Simplified 5-tap Gaussian blur with scaled direction
  const float weights[5] = float[5](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

  c += Texel(tex, tc) * weights[0];
  c += Texel(tex, tc + vec2(scaledDir * 1.0)) * weights[1];
  c += Texel(tex, tc - vec2(scaledDir * 1.0)) * weights[1];
  c += Texel(tex, tc + vec2(scaledDir * 2.0)) * weights[2];
  c += Texel(tex, tc - vec2(scaledDir * 2.0)) * weights[2];
  c += Texel(tex, tc + vec2(scaledDir * 3.0)) * weights[3];
  c += Texel(tex, tc - vec2(scaledDir * 3.0)) * weights[3];
  c += Texel(tex, tc + vec2(scaledDir * 4.0)) * weights[4];
  c += Texel(tex, tc - vec2(scaledDir * 4.0)) * weights[4];

  return c * colour;
}

