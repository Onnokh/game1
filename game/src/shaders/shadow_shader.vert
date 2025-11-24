// Shadow shader vertex shader
// Pass through - transformations handled by Love2D

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // Just pass through - Love2D handles all transformations
    return transform_projection * vertex_position;
}

