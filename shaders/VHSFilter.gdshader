shader_type canvas_item;

// ✅ Godot 4 fix — must declare this for screen effects
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// VHS settings
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.1;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.05;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.02;
uniform float chroma_offset : hint_range(0.0, 5.0) = 1.5;

void fragment() {
    vec2 uv = SCREEN_UV; // ✅ use SCREEN_UV instead of UV for screen-space shaders

    // Chromatic aberration (RGB split)
    float r = texture(SCREEN_TEXTURE, uv + vec2(chroma_offset / 1000.0, 0.0)).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - vec2(chroma_offset / 1000.0, 0.0)).b;
    vec3 color = vec3(r, g, b);

    // Scanlines
    float scanline = sin(uv.y * 800.0) * scanline_strength;
    color -= scanline;

    // Static noise
    float noise = (fract(sin(dot(uv * TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * noise_strength;
    color += noise;

    COLOR = vec4(color, 1.0);
}
