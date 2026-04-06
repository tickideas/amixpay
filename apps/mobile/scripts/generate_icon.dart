/// Run with: dart scripts/generate_icon.dart
/// Generates a 1024x1024 AmixPAY icon PNG at assets/icon/icon.png
/// and a 432x432 foreground layer at assets/icon/icon_foreground.png
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

void main() {
  _writeIcon('assets/icon/icon.png', 1024, withBackground: true);
  _writeIcon('assets/icon/icon_foreground.png', 432, withBackground: false);
  print('Icons written to assets/icon/');
}

void _writeIcon(String path, int size, {required bool withBackground}) {
  final pixels = Uint8List(size * size * 4); // RGBA

  // Background fill — teal #0D6B5E
  if (withBackground) {
    for (int i = 0; i < size * size; i++) {
      final x = i % size;
      final y = i ~/ size;
      final cx = size / 2, cy = size / 2, r = size / 2;
      // Rounded square: only fill if within squircle radius
      final dx = (x - cx).abs(), dy = (y - cy).abs();
      if (_insideSquircle(dx, dy, r * 0.88)) {
        pixels[i * 4]     = 0x0D; // R
        pixels[i * 4 + 1] = 0x6B; // G
        pixels[i * 4 + 2] = 0x5E; // B
        pixels[i * 4 + 3] = 0xFF; // A
      }
    }
  }

  // Draw white "A" letter centered
  _drawLetter(pixels, size, withBackground: withBackground);

  // Write PNG
  _writePng(path, pixels, size, size);
}

bool _insideSquircle(double dx, double dy, double r) {
  const n = 4.0;
  return math.pow(dx / r, n) + math.pow(dy / r, n) <= 1.0;
}

void _drawLetter(Uint8List pixels, int size, {required bool withBackground}) {
  // Draw the letter "A" as a thick stroke using filled rects
  final scale = size / 1024.0;

  void setPixel(int x, int y) {
    if (x < 0 || x >= size || y < 0 || y >= size) return;
    final i = (y * size + x) * 4;
    pixels[i]     = 0xFF;
    pixels[i + 1] = 0xFF;
    pixels[i + 2] = 0xFF;
    pixels[i + 3] = 0xFF;
  }

  void fillRect(double x, double y, double w, double h) {
    final ix = (x * scale).round(), iy = (y * scale).round();
    final iw = (w * scale).round(), ih = (h * scale).round();
    for (int dy = 0; dy < ih; dy++) {
      for (int dx = 0; dx < iw; dx++) {
        setPixel(ix + dx, iy + dy);
      }
    }
  }

  // "A" built from rectangles (coordinates in 1024 space)
  // Left leg
  fillRect(230, 250, 120, 540);
  // Right leg
  fillRect(670, 250, 120, 540);
  // Peak triangle left
  fillRect(350, 170, 120, 180);
  fillRect(470, 100, 84, 120);
  // Peak triangle right
  fillRect(554, 100, 84, 120);
  fillRect(554, 170, 120, 180);
  // Crossbar
  fillRect(350, 530, 324, 110);
  // Diagonal left leg
  _drawDiagonal(pixels, size, 350, 250, 470, 100, 120);
  // Diagonal right leg
  _drawDiagonal(pixels, size, 554, 100, 674, 250, 120);
}

void _drawDiagonal(Uint8List pixels, int size, double x0, double y0, double x1, double y1, double thickness) {
  final scale = size / 1024.0;
  final steps = 200;
  for (int s = 0; s <= steps; s++) {
    final t = s / steps;
    final cx = (x0 + (x1 - x0) * t) * scale;
    final cy = (y0 + (y1 - y0) * t) * scale;
    final half = (thickness * scale / 2).round();
    for (int dy = -half; dy <= half; dy++) {
      for (int dx = -half; dx <= half; dx++) {
        final px = (cx + dx).round(), py = (cy + dy).round();
        if (px >= 0 && px < size && py >= 0 && py < size) {
          final i = (py * size + px) * 4;
          pixels[i]     = 0xFF;
          pixels[i + 1] = 0xFF;
          pixels[i + 2] = 0xFF;
          pixels[i + 3] = 0xFF;
        }
      }
    }
  }
}

// ── Minimal PNG writer ────────────────────────────────────────────────────────

void _writePng(String path, Uint8List rgba, int width, int height) {
  final out = <int>[];
  // PNG signature
  out.addAll([137, 80, 78, 71, 13, 10, 26, 10]);
  // IHDR
  _addChunk(out, 'IHDR', [
    ..._int32(width), ..._int32(height),
    8, 6, 0, 0, 0, // 8-bit RGBA
  ]);
  // IDAT — raw deflate using zlib (uncompressed blocks)
  final raw = <int>[];
  for (int y = 0; y < height; y++) {
    raw.add(0); // filter type None
    for (int x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw.addAll([rgba[i], rgba[i+1], rgba[i+2], rgba[i+3]]);
    }
  }
  _addChunk(out, 'IDAT', _zlibUncompressed(raw));
  // IEND
  _addChunk(out, 'IEND', []);
  File(path).writeAsBytesSync(Uint8List.fromList(out));
}

List<int> _int32(int v) => [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

void _addChunk(List<int> out, String type, List<int> data) {
  out.addAll(_int32(data.length));
  final typeBytes = type.codeUnits;
  out.addAll(typeBytes);
  out.addAll(data);
  int crc = _crc32(typeBytes + data);
  out.addAll(_int32(crc));
}

List<int> _zlibUncompressed(List<int> data) {
  // zlib header (no compression)
  final out = [0x78, 0x01];
  const blockSize = 65535;
  int pos = 0;
  while (pos < data.length) {
    final end = math.min(pos + blockSize, data.length);
    final last = end == data.length ? 1 : 0;
    final len = end - pos;
    out.add(last);
    out.addAll([len & 0xFF, (len >> 8) & 0xFF, (~len) & 0xFF, ((~len) >> 8) & 0xFF]);
    out.addAll(data.sublist(pos, end));
    pos = end;
  }
  // Adler-32 checksum
  int a = 1, b = 0;
  for (final byte in data) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  out.addAll([(b >> 8) & 0xFF, b & 0xFF, (a >> 8) & 0xFF, a & 0xFF]);
  return out;
}

int _crc32(List<int> data) {
  int crc = 0xFFFFFFFF;
  for (final b in data) {
    crc ^= b;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
