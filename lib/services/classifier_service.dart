import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class CataractClassifier {
  late Interpreter _interpreter;
  late Tensor _inputTensor;
  late Tensor _outputTensor;

  final String modelAsset;
  final int inputSize;

  CataractClassifier({required this.modelAsset, this.inputSize = 224});

  Future<void> load({int threads = 2}) async {
    _interpreter = await Interpreter.fromAsset(
      modelAsset,
      options: InterpreterOptions()..threads = threads,
    );
    _inputTensor = _interpreter.getInputTensors().first;
    _outputTensor = _interpreter.getOutputTensors().first;

    print('Model loaded successfully');
    print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
    print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
  }

  void close() => _interpreter.close();

  /// Konversi image -> Float32 input [1, H, W, 3] (0..1)
  Float32List _imageToFloat32(img.Image src) {
    final resized = img.copyResize(src, width: inputSize, height: inputSize);
    final floats = Float32List(inputSize * inputSize * 3);
    int i = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        floats[i++] = p.r / 255.0;
        floats[i++] = p.g / 255.0;
        floats[i++] = p.b / 255.0;
      }
    }
    return floats;
  }

  /// Konversi image -> Uint8 input [1, H, W, 3] (0..255)
  Uint8List _imageToUint8(img.Image src) {
    final resized = img.copyResize(src, width: inputSize, height: inputSize);
    final bytes = Uint8List(inputSize * inputSize * 3);
    int i = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = resized.getPixel(x, y);
        bytes[i++] = p.r.toInt();
        bytes[i++] = p.g.toInt();
        bytes[i++] = p.b.toInt();
      }
    }
    return bytes;
  }

  /// Prediksi dari objek image (sudah ter-decode).
  /// Return: skor probabilitas katarak [0..1].
  double predict(img.Image inputImage) {
    final isFloatModel = _inputTensor.type == TfLiteType.kTfLiteFloat32;

    Object input;
    if (isFloatModel) {
      // FP16 weights -> input float32
      final data = _imageToFloat32(inputImage);
      input = data.reshape([1, inputSize, inputSize, 3]);
    } else {
      // INT8/UINT8 model -> input uint8
      final data = _imageToUint8(inputImage);
      input = data.reshape([1, inputSize, inputSize, 3]);
    }

    // Output shape [1,1] untuk binary sigmoid
    final output = List.filled(1, 0).reshape([1, 1]);
    _interpreter.run(input, output);

    // Ambil nilai mentah
    final raw = output[0][0];

    // Dequantize jika output bertipe uint8/int8
    if (_outputTensor.type == TfLiteType.kTfLiteUInt8 ||
        _outputTensor.type == TfLiteType.kTfLiteInt8) {
      final scale = _outputTensor.params.scale;
      final zero = _outputTensor.params.zeroPoint;
      final intVal = raw is int ? raw : (raw as num).toInt();
      final dequant = (intVal - zero) * scale; // ≈ 0..1
      return dequant.clamp(0.0, 1.0);
    }

    // Float32: langsung cast ke double (harapannya 0..1 dari sigmoid)
    print('Raw output: $raw');
    print('Clamped output: ${(raw as num).toDouble().clamp(0.0, 1.0)}');

    return (raw as num).toDouble().clamp(0.0, 1.0);
  }
}
