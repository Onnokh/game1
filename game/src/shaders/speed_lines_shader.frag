// Radial speed lines shader - ported from Godot
// Creates animated radial lines emanating from screen center

// Using procedural noise instead of texture
uniform vec4 line_color;
uniform float line_count;
uniform float line_density;
uniform float line_falloff;
uniform float mask_size;
uniform float mask_edge;
uniform float animation_speed;
uniform float time;
uniform vec2 resolution;
uniform float opacity;

// Inverse lerp function
float inv_lerp(float from, float to, float value) {
    return (value - from) / (to - from);
}

// Simple pseudo-random function for procedural noise
float random(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// Convert UV to polar coordinates
vec2 polar_coordinates(vec2 uv, vec2 center, float zoom, float repeat) {
    vec2 dir = uv - center;
    float radius = length(dir) * 2.0;
    float angle = atan(dir.y, dir.x) * 1.0/(3.14159265359 * 2.0);
    return mod(vec2(radius * zoom, angle * repeat), 1.0);
}

// Rotate UV around pivot
vec2 rotate_uv(vec2 uv, vec2 pivot, float rotation) {
    float cosa = cos(rotation);
    float sina = sin(rotation);
    uv -= pivot;
    return vec2(
        cosa * uv.x - sina * uv.y,
        cosa * uv.y + sina * uv.x
    ) + pivot;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Convert screen coords to UV (0-1)
    vec2 uv = screen_coords / resolution;

    // Rotate UV over time for animation
    vec2 rotated_uv = rotate_uv(uv, vec2(0.5), floor(fract(time) * animation_speed));

    // Convert to polar coordinates for radial lines
    vec2 polar_uv = polar_coordinates(rotated_uv, vec2(0.5), 0.01, line_count);

    // Create crisp radial lines using the angle component
    float angle = polar_uv.y * 2.0 * 3.14159265359;
    float lines_per_revolution = 24.0; // Number of lines radiating from center

    // Create clean radial lines without noise
    float line_pattern = sin(angle * lines_per_revolution);

    // Make lines very sharp and crisp
    float line_thickness = 0.12; // How thick each line is
    float lines = 1.0 - smoothstep(-line_thickness, line_thickness, abs(line_pattern));

    // Calculate radial mask from center - only show lines near edges
    float mask_value = length(uv - vec2(0.5));
    float mask = inv_lerp(mask_size, mask_edge, mask_value);

    // Apply mask - lines only visible near screen edges
    float result = lines * mask;

    // Apply opacity and line color
    float final_alpha = min(line_color.a, result) * opacity;

    return vec4(line_color.rgb, final_alpha);
}
