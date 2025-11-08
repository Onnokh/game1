// Vignette shader - darkens edges of screen

extern float radius = 0.8;
extern float softness = 0.5;
extern float opacity = 0.5;
extern vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

vec4 effect(vec4 c, Image tex, vec2 tc, vec2 _)
{
  float aspect = love_ScreenSize.x / love_ScreenSize.y;
  aspect = max(aspect, 1.0 / aspect); // use different aspect when in portrait mode
  float v = 1.0 - smoothstep(radius, radius - softness, length((tc - vec2(0.5)) * aspect));
  return mix(Texel(tex, tc), color, v * opacity);
}
