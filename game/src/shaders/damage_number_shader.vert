// Damage number vertex shader: apply horizontal jitter in object space
uniform float JitterX; // pixels to offset horizontally (can be negative)
uniform float JitterY; // pixels to offset vertically (can be negative)

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    vertex_position.x += JitterX;
    vertex_position.y += JitterY;
    return transform_projection * vertex_position;
}


