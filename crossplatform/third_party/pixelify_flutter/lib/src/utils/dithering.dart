import 'dart:typed_data';
import 'dart:ui';
import '../utils/palette.dart';

/// Floyd–Steinberg dithering helper. Expects RGBA buffer.
Uint8List floydSteinbergDither(Uint8List rgba, int width, int height, Palette palette) {
  final out = Uint8List.fromList(rgba);
  int idx(int x, int y, int c) => (y * width + x) * 4 + c;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final i = idx(x, y, 0);
      final oldR = out[i], oldG = out[i+1], oldB = out[i+2];
      final chosen = palette.nearest(Color.fromARGB(255, oldR, oldG, oldB));
      final newR = chosen.red, newG = chosen.green, newB = chosen.blue;
      out[i] = newR; out[i+1] = newG; out[i+2] = newB;
      final errR = oldR - newR, errG = oldG - newG, errB = oldB - newB;
      void add(int xx, int yy, double f) { if (xx<0||xx>=width||yy<0||yy>=height) return; final j=idx(xx,yy,0); out[j]=_clamp(out[j]+(errR*f).round()); out[j+1]=_clamp(out[j+1]+(errG*f).round()); out[j+2]=_clamp(out[j+2]+(errB*f).round()); }
      add(x+1,y,7/16); add(x-1,y+1,3/16); add(x,y+1,5/16); add(x+1,y+1,1/16);
    }
  }
  return out;
}
int _clamp(int v) => v<0?0:(v>255?255:v);
