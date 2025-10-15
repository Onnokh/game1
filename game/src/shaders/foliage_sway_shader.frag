// Foliage sway shader fragment shader
// Creates wind sway effect using Perlin noise

uniform float Time;
uniform Image NoiseTexture;
uniform vec2 TextureSize;
uniform vec2 WorldPosition;

// Sway parameters (subtle wind effect)
const float amplitude = 0.08;
const float time_scale = 0.05;
const float noise_scale = 0.001;
const float rotation_strength = 1.0;
const vec2 rotation_pivot = vec2(0.5, 1.0);
const float distance_cutoff = 0.3;

vec2 get_sample_pos(vec2 pos, float scale, float offset) {
    pos *= scale;
    pos += offset;
    return pos;
}

vec2 rotate_vec(vec2 vec, vec2 pivot, float rotation) {
    float cosa = cos(rotation);
    float sina = sin(rotation);
    vec -= pivot;
    return vec2(
        cosa * vec.x - sina * vec.y,
        cosa * vec.y + sina * vec.x
    ) + pivot;
}

vec2 get_pixelated_uvs(vec2 uv, vec2 texture_pixel_size) {
    vec2 texture_dimensions = 1.0 / texture_pixel_size;
    vec2 pixel_coords = uv * texture_dimensions;
    vec2 snapped_pixel_coords = vec2(floor(pixel_coords.x + 0.5), floor(pixel_coords.y + 0.5));
    vec2 pixelated_uv = snapped_pixel_coords / texture_dimensions;
    return pixelated_uv;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv = texture_coords;

    // Combine world position with UV for per-entity variation
    vec2 world_uv = (WorldPosition + uv * TextureSize) * noise_scale;

    // Get noise from texture with proper wrapping to avoid seams
    vec2 noise_sample_pos = get_sample_pos(world_uv, 1.0, Time * time_scale);
    // Ensure coordinates wrap properly for seamless tiling (fallback for older GLSL)
    noise_sample_pos = noise_sample_pos - floor(noise_sample_pos);
    float noise_amount = Texel(NoiseTexture, noise_sample_pos).r - 0.5;

    // Get rotation position around a pivot
    float rotation = amplitude * noise_amount;
    vec2 rotated_uvs = rotate_vec(uv, rotation_pivot, rotation);

    // Blend original uvs and rotated uvs based on distance to pivot (smooth falloff)
    float d = distance(uv, rotation_pivot);
    // Smooth transition from trunk (no sway) to foliage (full sway)
    float t = smoothstep(distance_cutoff, 1.0, d) * rotation_strength;
    vec2 result_uvs = mix(uv, rotated_uvs, t);

    // Output color (no pixelation to avoid seams)
    return Texel(texture, result_uvs) * color;
}
