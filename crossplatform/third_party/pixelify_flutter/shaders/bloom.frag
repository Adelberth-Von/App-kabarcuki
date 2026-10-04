// bloom.frag
precision highp float;

uniform sampler2D u_texture;
uniform float u_intensity;    // blur radius (sigma)
uniform float u_threshold;    // brightness threshold
uniform vec4 u_glowColor;     // tint color

varying vec2 v_texCoord;

// Simple Gaussian blur sampling offsets around center pixel
vec4 blur(in vec2 uv) {
  vec4 sum = vec4(0.0);
  float offsets[5] = float[](0.0, 1.3846, 3.2308, -1.3846, -3.2308);
  float weights[1] = float[](0.2270, 0.3162, 0.0703, 0.3162, 0.0703);

  for(int i = 0; i < 5; i++) {
    sum += texture2D(u_texture, uv + vec2(offsets[i] * u_intensity / 512.0, 0.0)) * weights[i];
    sum += texture2D(u_texture, uv + vec2(0.0, offsets[i] * u_intensity / 512.0)) * weights[i];
  }
  return sum / 2.0;
}

void main() {
  vec4 color = texture2D(u_texture, v_texCoord);

  // Calculate brightness as luminance
  float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));

  // Apply threshold: if below threshold, no glow
  if(brightness < u_threshold) {
    gl_FragColor = color;
    return;
  }
  
  // Get blurred glow color
  vec4 glow = blur(v_texCoord);
  
  // Tint and scale glow by intensity and glowColor
  glow.rgb *= u_glowColor.rgb * u_glowColor.a;

  // Additive blending: original color + glow
  gl_FragColor = color + glow * u_intensity;

  // Clamp to max 1.0
  gl_FragColor = clamp(gl_FragColor, 0.0, 1.0);
}
