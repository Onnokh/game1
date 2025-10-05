// Damage number fragment shader: animate upward + shrink over lifetime
uniform float Progress;    // 0..1, where 0=fresh, 1=expired
uniform float MoveUp;      // pixels to move up at Progress=1
uniform float StartScale;  // initial scale multiplier
uniform float EndScale;    // final scale multiplier

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Compute animation parameters
    float yOffset = -MoveUp * Progress; // move up as progress increases
    float scale = mix(StartScale, EndScale, Progress);

    // Sample normally (we cannot directly scale here; scaling happens in draw via transforms)
    vec4 texel = Texel(texture, texture_coords) * color;
    return texel;
}


