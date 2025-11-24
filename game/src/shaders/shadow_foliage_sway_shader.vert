// Combined shadow and foliage sway shader vertex shader
// Passes world position to fragment shader for noise sampling variation

uniform vec2 WorldPosition;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    return transform_projection * vertex_position;
}

