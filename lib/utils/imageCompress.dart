import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart'; // compute()
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DartImagePreprocessor {
  static Future<File> processFile(
    File input, {
    int maxBytes = 30 * 1024,
    int maxDimension = 1080,
    bool flattenAlphaToWhite = false, // <-- tetap ada
  }) async {
    if (!await input.exists()) {
      throw Exception('File tidak ditemukan: ${input.path}');
    }
    final bytes = await input.readAsBytes();

    final result = await compute<_Payload, _Result>(
      _compressIsolate,
      _Payload(
        bytes: bytes,
        maxBytes: maxBytes,
        maxDimension: maxDimension,
        flattenAlphaToWhite: flattenAlphaToWhite,
      ),
    );

    if (result.bytes == null) return input; // fallback
    final tmp = await getTemporaryDirectory();
    final outPath = p.join(
      tmp.path,
      'upload_${DateTime.now().millisecondsSinceEpoch}${result.ext}',
    );
    final outFile = File(outPath);
    await outFile.writeAsBytes(result.bytes!, flush: true);
    return outFile;
  }
}

class _Payload {
  final Uint8List bytes;
  final int maxBytes;
  final int maxDimension;
  final bool flattenAlphaToWhite;
  _Payload({
    required this.bytes,
    required this.maxBytes,
    required this.maxDimension,
    required this.flattenAlphaToWhite,
  });
}

class _Result {
  final Uint8List? bytes;
  final String ext;
  _Result(this.bytes, this.ext);
}

_Result _compressIsolate(_Payload p) {
  final decoded = img.decodeImage(p.bytes);
  if (decoded == null) return _Result(null, '');

  img.Image working = decoded;

  // Resize awal jika perlu
  int currentMaxDim = p.maxDimension;
  working = _resizeIfTooLarge(working, currentMaxDim);

  final hasAlpha = working.hasAlpha;

  // >>>> GANTI BAGIAN INI: flatten alpha ke putih pakai composite
  final bool treatAsNonAlpha = hasAlpha && p.flattenAlphaToWhite;
  if (treatAsNonAlpha) {
    working = _flattenAlphaToWhite(working);
  }
  // <<<<

  // Encoder + ekstensi
  final bool usePng = hasAlpha && !treatAsNonAlpha;
  final String ext = usePng ? '.png' : '.jpg';

  int quality = 90;
  const int minQuality = 30;

  Uint8List out = _encode(working, ext, quality);

  for (int attempt = 0;
      attempt < 7 && out.lengthInBytes > p.maxBytes;
      attempt++) {
    if (usePng) {
      // PNG (lossless): kecilkan dimensi
      currentMaxDim = max(480, (currentMaxDim * 0.85).floor());
      working = _resizeIfTooLarge(working, currentMaxDim);
    } else {
      // JPEG: turunkan quality dulu, lalu dimensi
      if (quality > minQuality) {
        quality = max(minQuality, quality - 10);
      } else {
        currentMaxDim = max(480, (currentMaxDim * 0.85).floor());
        working = _resizeIfTooLarge(working, currentMaxDim);
      }
    }
    out = _encode(working, ext, quality);
  }

  return _Result(out, ext);
}

img.Image _resizeIfTooLarge(img.Image src, int maxDim) {
  final w = src.width, h = src.height;
  final longest = max(w, h);
  if (longest <= maxDim) return src;
  final scale = maxDim / longest;
  return img.copyResize(
    src,
    width: (w * scale).round(),
    height: (h * scale).round(),
    interpolation: img.Interpolation.average,
  );
}

Uint8List _encode(img.Image im, String ext, int quality) {
  if (ext == '.png') {
    // PNG: lossless (bisa tambah parameter level kalau perlu)
    return Uint8List.fromList(img.encodePng(im));
  }
  // JPEG
  return Uint8List.fromList(img.encodeJpg(im, quality: quality));
}

/// Flatten alpha → latar putih memakai compositeImage
img.Image _flattenAlphaToWhite(img.Image src) {
  // Buat kanvas RGB putih (tanpa alpha)
  final bg = img.Image(width: src.width, height: src.height);
  img.fill(bg, color: img.ColorRgb8(255, 255, 255));
  // Tumpuk gambar asli di atasnya (alpha dipakai otomatis)
  img.compositeImage(bg, src);
  return bg;
}
