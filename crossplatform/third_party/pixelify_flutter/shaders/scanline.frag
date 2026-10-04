precision highp float;

uniform sampler2D u_texture;
uniform float u_width;
uniform float u_height;
uniform float u_intensity;      // Scanline opacity (0-1)
uniform float u_thickness;      // Scanline thickness in pixels
uniform float u_spacing;        // Spacing between scanlines in pixels
uniform float u_scanlineColorR; // Scanline color red channel (0-1)
uniform float u_scanlineColorG; // Scanline color green channel (0-1)
uniform float u_scanlineColorB; // Scanline color blue channel (0-1)
uniform float u_scanlineColorA; // Scanline color alpha channel (0-1)
uniform float u_animationValue; // Animation phase (0-1)
uniform float u_curvatureAmount;   // Screen curvature 0-1
uniform float u_glowIntensity;     // Glow intensity 0-1
uniform float u_colorBleedAmount;  // Color bleed amount 0-1
uniform float u_noiseAmount;       // Noise opacity 0-1
uniform float u_contrast;          // Contrast multiplier
uniform float u_brightness;        // Brightness multiplier

varying vec2 v_texCoord;

// Simple function to create scanline pattern based on Y coordinate
float scanlinePattern(float y, float thicknessPixels, float spacingPixels, float time) {
    float totalHeight = thicknessPixels + spacingPixels;
    // Animate vertical shift of scanlines with time
    float shift = mod(time * totalHeight, totalHeight);
    float pos = mod(y * u_height + shift, totalHeight);
    float line = smoothstep(0.0, thicknessPixels, pos) * (1.0 - smoothstep(thicknessPixels, thicknessPixels + 1.0, pos));
    return line;
}

// Barrel distortion for curvature (approximates CRT curved screen)
vec2 barrelDistortion(vec2 coord, float amount) {
    vec2 cc = coord - 0.5;
    float dist = dot(cc, cc);
    return coord + cc * dist * amount;
}

// Simple noise function
float rand(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = v_texCoord;

    // Apply barrel distortion for curvature
    if (u_curvatureAmount > 0.0) {
        uv = barrelDistortion(uv, u_curvatureAmount * 0.1);
    }

    // Sample base color
    vec4 baseColor = texture2D(u_texture, uv);

    // Apply glow - simple additive bloom effect on bright areas
    vec4 glowColor = vec4(0.0);
    if (u_glowIntensity > 0.0) {
        vec2 glowOffset = vec2(1.0 / u_width, 0.0);
        glowColor += texture2D(u_texture, uv + glowOffset) * 0.5;
        glowColor += texture2D(u_texture, uv - glowOffset) * 0.5;
        glowColor = glowColor * u_glowIntensity;
    }

    vec4 color = baseColor + glowColor;

    // Apply color bleed - RGB channel offsets
    if (u_colorBleedAmount > 0.0) {
        float offset = u_colorBleedAmount * 0.005;
        float r = texture2D(u_texture, uv + vec2(offset, 0.0)).r;
        float g = texture2D(u_texture, uv).g;
        float b = texture2D(u_texture, uv - vec2(offset, 0.0)).b;
        color = vec4(r, g, b, color.a);
    }

    // Compute scanline pattern alpha
    float scanlineAlpha = scanlinePattern(uv.y, u_thickness, u_spacing, u_animationValue) * u_intensity;

    // Mix scanline color and base color by alpha
    vec3 scanlineCol = vec3(u_scanlineColorR, u_scanlineColorG, u_scanlineColorB);
    vec3 finalColor = mix(color.rgb, scanlineCol, scanlineAlpha * u_scanlineColorA);

    // Apply noise
    if (u_noiseAmount > 0.0) {
        float noise = (rand(uv * u_width) - 0.5) * u_noiseAmount;
        finalColor += noise;
    }

    // Apply contrast and brightness adjustments
    finalColor = (finalColor - 0.5) * u_contrast + 0.5; // Contrast
    finalColor += vec3(u_brightness); // Brightness

    // Clamp colors
    finalColor = clamp(finalColor, 0.0, 1.0);

    gl_FragColor = vec4(finalColor, color.a);
}
