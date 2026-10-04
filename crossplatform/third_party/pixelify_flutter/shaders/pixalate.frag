precision highp float;

uniform sampler2D u_texture;
uniform float u_width;
uniform float u_height;
uniform float u_pixelSize;
uniform float u_softEdges;
uniform vec4 u_pixelColor;
uniform vec4 u_region; // xy = top-left, zw = size (0 means full region)

varying vec2 v_texCoord;

void main() {
  // Calculate region in normalized coords:
  vec2 regionStart = u_region.xy;
  vec2 regionSize = u_region.zw;

  // If regionSize is zero, pixelate full image
  bool useRegion = (regionSize.x > 0.0 && regionSize.y > 0.0);

  // Coordinate in [0,1]
  vec2 uv = v_texCoord;

  // Check if current fragment is inside pixelate region
  if (useRegion) {
    if (uv.x < regionStart.x || uv.x > regionStart.x + regionSize.x ||
        uv.y < regionStart.y || uv.y > regionStart.y + regionSize.y) {
      // Outside region: output original color
      gl_FragColor = texture2D(u_texture, uv);
      return;
    }
    // Normalize within region for pixelation
    uv = (uv - regionStart) / regionSize;
  }

  // Calculate pixelated coordinates
  float px = u_pixelSize / u_width;
  float py = u_pixelSize / u_height;

  // Clamp pixelSize minimum
  if (px < 1.0 / u_width) px = 1.0 / u_width;
  if (py < 1.0 / u_height) py = 1.0 / u_height;

  // Find center of pixel block by flooring uv to nearest pixel block and offset by half block
  vec2 pixelatedUV = vec2(
    floor(uv.x / px) * px + px * 0.5,
    floor(uv.y / py) * py + py * 0.5
  );

  // Sample the texture color at pixelated position
  vec4 color = texture2D(u_texture, pixelatedUV);

  // Apply tint color to pixel
  color *= u_pixelColor;

  if (u_softEdges > 0.5) {
    // Soften edges by blending between current UV and center of pixel block near edges
    vec2 pixelPos = fract(uv / vec2(px, py)); // fractional part

    // Calculate smoothing factor close to edges (0 at center, 1 near edges)
    float edgeDistX = min(pixelPos.x, 1.0 - pixelPos.x);
    float edgeDistY = min(pixelPos.y, 1.0 - pixelPos.y);
    float smoothing = min(edgeDistX / 0.1, edgeDistY / 0.1); // smooth within 0.1 fractional width
    smoothing = clamp(smoothing, 0.0, 1.0);

    // Sample original texture at actual uv
    vec4 originalColor = texture2D(u_texture, v_texCoord);

    // Blend pixelated color with original based on smoothing to soften edges
    color = mix(color, originalColor, smoothing);
  }

  if (useRegion) {
    // If region used, map color back to full uv space (no change needed here)
  }

  gl_FragColor = color;
}
