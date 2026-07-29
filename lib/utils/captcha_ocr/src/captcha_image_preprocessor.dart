import 'dart:typed_data';

import 'package:image/image.dart' as image;

class CaptchaImageVariant {
  const CaptchaImageVariant({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class CaptchaImagePreprocessor {
  const CaptchaImagePreprocessor();

  static const int _scale = 8;

  List<CaptchaImageVariant> createVariants(Uint8List sourceBytes) {
    image.Image? source;
    try {
      source = image.decodeImage(sourceBytes);
    } catch (_) {
      source = null;
    }
    if (source == null) {
      return <CaptchaImageVariant>[
        CaptchaImageVariant(name: 'original', bytes: sourceBytes),
      ];
    }

    final List<bool> mask = _createInkMask(source);
    final List<bool> cleanedMask = _removeSmallComponents(
      mask,
      source.width,
      source.height,
    );
    final List<bool> cleanedThickMask = _dilate(
      cleanedMask,
      source.width,
      source.height,
    );

    return <CaptchaImageVariant>[
      CaptchaImageVariant(
        name: 'segmented',
        bytes: _encodeSegmentedMask(cleanedMask, source.width, source.height),
      ),
      CaptchaImageVariant(
        name: 'segmented-thick',
        bytes: _encodeSegmentedMask(
          cleanedThickMask,
          source.width,
          source.height,
        ),
      ),
      CaptchaImageVariant(
        name: 'color-upscaled',
        bytes: _encodeUpscaled(source, image.Interpolation.linear),
      ),
    ];
  }

  List<bool> _createInkMask(image.Image source) {
    final List<bool> mask = List<bool>.filled(
      source.width * source.height,
      false,
    );
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final image.Pixel pixel = source.getPixel(x, y);
        final double yellowStrength =
            ((pixel.r.toDouble() + pixel.g.toDouble()) / 2) -
            pixel.b.toDouble();
        final bool isBrightEnough =
            pixel.r.toDouble() > 120 && pixel.g.toDouble() > 120;
        mask[_index(x, y, source.width)] =
            isBrightEnough && yellowStrength > 20;
      }
    }
    return mask;
  }

  List<bool> _dilate(List<bool> mask, int width, int height) {
    final List<bool> result = List<bool>.from(mask);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!mask[_index(x, y, width)]) {
          continue;
        }
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final int targetX = x + dx;
            final int targetY = y + dy;
            if (_isInside(targetX, targetY, width, height)) {
              result[_index(targetX, targetY, width)] = true;
            }
          }
        }
      }
    }
    return result;
  }

  List<bool> _removeSmallComponents(List<bool> mask, int width, int height) {
    final List<bool> result = List<bool>.filled(mask.length, false);
    final List<bool> visited = List<bool>.filled(mask.length, false);
    const int minimumComponentSize = 3;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int startIndex = _index(x, y, width);
        if (!mask[startIndex] || visited[startIndex]) {
          continue;
        }

        final List<int> component = <int>[];
        final List<int> pending = <int>[startIndex];
        visited[startIndex] = true;

        while (pending.isNotEmpty) {
          final int current = pending.removeLast();
          component.add(current);
          final int currentX = current % width;
          final int currentY = current ~/ width;

          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) {
                continue;
              }
              final int neighborX = currentX + dx;
              final int neighborY = currentY + dy;
              if (!_isInside(neighborX, neighborY, width, height)) {
                continue;
              }
              final int neighborIndex = _index(neighborX, neighborY, width);
              if (mask[neighborIndex] && !visited[neighborIndex]) {
                visited[neighborIndex] = true;
                pending.add(neighborIndex);
              }
            }
          }
        }

        if (component.length >= minimumComponentSize) {
          for (final int index in component) {
            result[index] = true;
          }
        }
      }
    }
    return result;
  }

  Uint8List _encodeSegmentedMask(List<bool> mask, int width, int height) {
    const int characterCount = 4;
    const int horizontalPadding = 4;
    const int verticalPadding = 4;
    const int gap = 6;
    final int outputWidth =
        width + horizontalPadding * 2 + gap * (characterCount - 1);
    final int outputHeight = height + verticalPadding * 2;
    final image.Image output = image.Image(
      width: outputWidth,
      height: outputHeight,
    );
    image.fill(output, color: image.ColorRgb8(255, 255, 255));

    for (int character = 0; character < characterCount; character++) {
      final int startX = character * width ~/ characterCount;
      final int endX = (character + 1) * width ~/ characterCount;
      for (int y = 0; y < height; y++) {
        for (int x = startX; x < endX; x++) {
          if (mask[_index(x, y, width)]) {
            output.setPixelRgba(
              horizontalPadding + x + character * gap,
              verticalPadding + y,
              0,
              0,
              0,
              255,
            );
          }
        }
      }
    }
    return _encodeUpscaled(output, image.Interpolation.nearest);
  }

  Uint8List _encodeUpscaled(
    image.Image source,
    image.Interpolation interpolation,
  ) {
    final image.Image resized = image.copyResize(
      source,
      width: source.width * _scale,
      height: source.height * _scale,
      interpolation: interpolation,
    );
    return Uint8List.fromList(image.encodePng(resized, level: 1));
  }

  int _index(int x, int y, int width) => y * width + x;

  bool _isInside(int x, int y, int width, int height) =>
      x >= 0 && y >= 0 && x < width && y < height;
}
