import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:htr/utils/app_logger.dart';

class TextRecognitionService {
  static final _textRecognizer = TextRecognizer();

  static Future<String> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return recognizedText.text; // full block of text
    } catch (e) {
      AppLogger.error("Text recognition failed: $e");
      return "Error recognizing text.";
    }
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
