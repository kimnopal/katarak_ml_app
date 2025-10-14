import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class CataractTFLiteTester {
  final String modelPath;
  final int inputSize;
  final double threshold;

  late Interpreter _interpreter;
  late Tensor _inputTensor;
  late Tensor _outputTensor;

  CataractTFLiteTester({
    this.modelPath = 'assets/model_float32_ori.tflite',
    this.inputSize = 224,
    this.threshold = 0.5,
  });

  /// Load model
  Future<void> loadModel({int threads = 2}) async {
    _interpreter = await Interpreter.fromAsset(
      modelPath,
      options: InterpreterOptions()..threads = threads,
    );
    _inputTensor = _interpreter.getInputTensors().first;
    _outputTensor = _interpreter.getOutputTensors().first;

    print('✅ Model loaded successfully');
    print('Input tensor shape: ${_inputTensor.shape}');
    print('Output tensor shape: ${_outputTensor.shape}');
    print('Input type: ${_inputTensor.type}');
    print('Output type: ${_outputTensor.type}');
  }

  /// Preprocess image: resize → normalize (0–1) → flatten
  Float32List _preprocessImage(img.Image image) {
    // Resize image
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    // Prepare float buffer
    final buffer = Float32List(inputSize * inputSize * 3);
    int index = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[index++] = pixel.r / 255.0;
        buffer[index++] = pixel.g / 255.0;
        buffer[index++] = pixel.b / 255.0;
      }
    }

    return buffer;
  }

  /// Predict single image file
  Future<void> predict(File imageFile) async {
    if (!await imageFile.exists()) {
      print('❌ Image file not found: ${imageFile.path}');
      return;
    }

    // Decode image
    final raw = imageFile.readAsBytesSync();
    final image = img.decodeImage(raw);
    if (image == null) {
      print('❌ Failed to decode image.');
      return;
    }

    // Preprocess image
    final inputBuffer = _preprocessImage(image);
    final input = inputBuffer.reshape([1, inputSize, inputSize, 3]);

    // Allocate output
    final output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    // Run inference
    _interpreter.run(input, output);

    // Read result
    final double score = output[0][0];
    final bool isNormal = score >= threshold;
    final double confidence = isNormal ? score * 100 : (1.0 - score) * 100;

    final label = isNormal ? 'Normal' : 'Cataract';

    print(
      '🔍 Prediction Tester: $label (confidence = ${confidence.toStringAsFixed(2)}%)',
    );
    print('Raw Score Tester: ${score.toStringAsFixed(4)}');
    print('Threshold used Tester: $threshold');
  }

  void close() {
    _interpreter.close();
  }
}
