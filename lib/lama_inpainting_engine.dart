import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

/// Local-only prototype for the pinned LaMa ONNX export.
///
/// The model is deliberately loaded from an explicit local path, not a network
/// URL or a bundled asset. Callers must obtain and verify the artifact first.
/// Output is composited only within [removedMask]; all other source pixels are
/// copied byte-for-byte from [base].
class LamaInpaintingEngine {
  LamaInpaintingEngine({OnnxRuntime? runtime}) : _runtime = runtime;

  OnnxRuntime? _runtime;

  OnnxRuntime get _runtimeOrCreate => _runtime ??= OnnxRuntime();

  static const int modelWidth = 512;
  static const int modelHeight = 512;
  static const String imageInputName = 'image';
  static const String maskInputName = 'mask';
  static const String outputName = 'output';

  OrtSession? _session;

  bool get isLoaded => _session != null;

  Future<void> loadFromVerifiedFile(String modelPath) async {
    if (modelPath.trim().isEmpty) {
      throw ArgumentError.value(modelPath, 'modelPath', 'Must be a local verified model path.');
    }
    final next = await _runtimeOrCreate.createSession(
      modelPath,
      options: OrtSessionOptions(
        intraOpNumThreads: 2,
        interOpNumThreads: 1,
        providers: [OrtProvider.CPU],
        useArena: true,
      ),
    );

    final inputNames = next.inputNames.toSet();
    final outputNames = next.outputNames.toSet();
    if (!inputNames.containsAll({imageInputName, maskInputName}) ||
        !outputNames.contains(outputName)) {
      await next.close();
      throw StateError(
        'LaMa ONNX contract mismatch: inputs=$inputNames outputs=$outputNames',
      );
    }

    final old = _session;
    _session = next;
    if (old != null) await old.close();
  }

  /// Reconstructs only pixels marked true in [removedMask].
  ///
  /// [removedMask] must have exactly base.width * base.height entries.
  /// The source image is never mutated. The current prototype targets the
  /// pinned 512x512, NCHW RGB float32 export and CPU provider only.
  Future<img.Image> inpaint({
    required img.Image base,
    required List<bool> removedMask,
  }) async {
    final expected = base.width * base.height;
    if (removedMask.length != expected) {
      throw ArgumentError('Mask has ${removedMask.length} entries; expected $expected.');
    }
    if (!removedMask.any((value) => value)) return img.Image.from(base);
    final session = _session;
    if (session == null) throw StateError('LaMa model is not loaded.');

    final resized = img.copyResize(
      base,
      width: modelWidth,
      height: modelHeight,
      interpolation: img.Interpolation.linear,
    );
    final imageTensorData = Float32List(3 * modelWidth * modelHeight);
    final maskTensorData = Float32List(modelWidth * modelHeight);

    for (var y = 0; y < modelHeight; y++) {
      final sourceY = math.min(base.height - 1, (y * base.height / modelHeight).floor());
      for (var x = 0; x < modelWidth; x++) {
        final sourceX = math.min(base.width - 1, (x * base.width / modelWidth).floor());
        final sourceIndex = sourceY * base.width + sourceX;
        final modelIndex = y * modelWidth + x;
        final isHole = removedMask[sourceIndex];
        final p = resized.getPixel(x, y);
        final r = isHole || p.a == 0 ? 0.0 : p.r.toDouble() / 255.0;
        final g = isHole || p.a == 0 ? 0.0 : p.g.toDouble() / 255.0;
        final b = isHole || p.a == 0 ? 0.0 : p.b.toDouble() / 255.0;
        imageTensorData[modelIndex] = r;
        imageTensorData[modelWidth * modelHeight + modelIndex] = g;
        imageTensorData[2 * modelWidth * modelHeight + modelIndex] = b;
        maskTensorData[modelIndex] = isHole ? 1.0 : 0.0;
      }
    }

    final imageTensor = await OrtValue.fromList(
      imageTensorData,
      [1, 3, modelHeight, modelWidth],
    );
    final maskTensor = await OrtValue.fromList(
      maskTensorData,
      [1, 1, modelHeight, modelWidth],
    );
    Map<String, OrtValue>? outputs;
    try {
      outputs = await session.run({
        imageInputName: imageTensor,
        maskInputName: maskTensor,
      });
      final output = outputs[outputName];
      if (output == null) throw StateError('LaMa did not return "$outputName".');
      final shape = output.shape;
      if (shape.length != 4 ||
          shape[0] != 1 ||
          shape[1] != 3 ||
          shape[2] != modelHeight ||
          shape[3] != modelWidth) {
        throw StateError('Unexpected LaMa output shape: $shape');
      }
      final values = await output.asFlattenedList();
      if (values.length != imageTensorData.length) {
        throw StateError('Unexpected LaMa output element count: ${values.length}.');
      }

      final result = img.Image.from(base);
      for (var y = 0; y < base.height; y++) {
        for (var x = 0; x < base.width; x++) {
          final index = y * base.width + x;
          if (!removedMask[index]) continue;
          final mx = math.min(modelWidth - 1, (x * modelWidth / base.width).floor());
          final my = math.min(modelHeight - 1, (y * modelHeight / base.height).floor());
          final mi = my * modelWidth + mx;
          final r = _toByte(values[mi]);
          final g = _toByte(values[modelWidth * modelHeight + mi]);
          final b = _toByte(values[2 * modelWidth * modelHeight + mi]);
          result.setPixelRgba(x, y, r, g, b, 255);
        }
      }
      return result;
    } finally {
      await imageTensor.dispose();
      await maskTensor.dispose();
      if (outputs != null) {
        for (final tensor in outputs.values) {
          await tensor.dispose();
        }
      }
    }
  }

  static int _toByte(Object? value) {
    final number = value is num ? value.toDouble() : double.nan;
    if (!number.isFinite) throw StateError('LaMa output contains a non-finite value.');
    // This ONNX export's published contract says output RGB is in [0,255].
    // Reject a likely normalization mismatch instead of silently producing dark pixels.
    if (number < -1 || number > 256) {
      throw StateError('LaMa output is outside the expected [0,255] range.');
    }
    return number.round().clamp(0, 255);
  }

  Future<void> dispose() async {
    final session = _session;
    _session = null;
    if (session != null) await session.close();
  }
}
