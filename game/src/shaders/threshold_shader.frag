// Threshold shader - converts image to black or white based on luminance
// Standard luminance formula: 0.299*r + 0.587*g + 0.114*b

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Sample the original color
    vec4 originalColor = Texel(tex, texture_coords);

    // Calculate luminance using standard formula
    float luminance = 0.299 * originalColor.r + 0.587 * originalColor.g + 0.114 * originalColor.b;

    // Convert to pure black or white based on threshold (0.5)
    float threshold = 0.5;
    float result = step(threshold, luminance);

    // Return pure black (0,0,0) or white (1,1,1)
    return vec4(result, result, result, originalColor.a);
}


