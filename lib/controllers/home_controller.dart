import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:katarak_ml_app/services/classifier_service.dart';
import 'package:katarak_ml_app/services/classifier_test_service.dart';
import 'package:katarak_ml_app/services/image_loader_service.dart';

class HomeController extends GetxController {
  final CataractClassifier _clf = CataractClassifier(
    modelAsset: 'assets/cataract_model_v2.tflite',
  );
  final ImagePicker _picker = ImagePicker();

  // Reactive state
  var isLoading = true.obs;
  var selectedFile = Rx<File?>(null);
  var confidence = 0.0.obs;
  var resultLabel = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _clf.load(threads: 2);
    isLoading.value = false;
  }

  Future<void> pickImage({bool fromCamera = false}) async {
    final XFile? xfile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1200,
    );
    if (xfile != null) {
      selectedFile.value = File(xfile.path);
      resultLabel.value = '';
      confidence.value = 0.0;
    }
  }

  Future<void> analyzeImage() async {
    final file = selectedFile.value;
    if (file == null) return;
    final img.Image? decoded = await decodeImageFile(file);
    if (decoded == null) {
      resultLabel.value = 'Gagal membaca gambar';
      return;
    }

    final prob = _clf.predict(decoded);

    final isNormal = prob >= 0.5; // 0.5 adalah threshold
    confidence.value = isNormal ? prob * 100 : (1.0 - prob) * 100;
    print('confidence: ${confidence.value}');
    resultLabel.value = isNormal ? 'Normal' : 'Katarak';
  }

  @override
  void onClose() {
    _clf.close();
    super.onClose();
  }
}
