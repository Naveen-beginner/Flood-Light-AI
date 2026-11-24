import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_ai/firebase_ai.dart';

class AnalysisResult {
  final String problemTitle;
  final String severity;
  final String category;
  final String description;
  final List<String> suggestedActions;
  final bool isOffline;
  final String source; // ON_DEVICE or CLOUD

  AnalysisResult({
    required this.problemTitle,
    required this.severity,
    required this.category,
    required this.description,
    required this.suggestedActions,
    required this.isOffline,
    required this.source,
  });
}

class HybridAiService {
  static Future<AnalysisResult> analyzeOfflineImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('The selected image could not be found.');
    }

    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final imageWidth = image.width;
    final imageHeight = image.height;
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    image.dispose();

    int redSum = 0;
    int greenSum = 0;
    int blueSum = 0;
    int darkPixels = 0;
    int sampleCount = 0;

    if (byteData != null) {
      const step = 64;
      final rgba = byteData.buffer.asUint8List();
      for (var i = 0; i < rgba.length; i += step * 4) {
        redSum += rgba[i];
        greenSum += rgba[i + 1];
        blueSum += rgba[i + 2];
        if ((rgba[i] + rgba[i + 1] + rgba[i + 2]) / 3 < 90) {
          darkPixels++;
        }
        sampleCount++;
      }
    }

    final averageBlue = sampleCount == 0 ? 0 : blueSum ~/ sampleCount;
    final averageGreen = sampleCount == 0 ? 0 : greenSum ~/ sampleCount;
    final averageRed = sampleCount == 0 ? 0 : redSum ~/ sampleCount;
    final brightness = (averageRed + averageGreen + averageBlue) ~/ 3;
    final darkRatio = sampleCount == 0 ? 0 : darkPixels / sampleCount;
    final blueDominant = averageBlue > averageGreen && averageBlue > averageRed;

    final isLikelyFlood = blueDominant ||
        (averageBlue >= 105 && brightness >= 90 && brightness <= 180);
    final severity = isLikelyFlood
        ? (darkRatio > 0.35 ? 'High' : 'Medium')
        : 'Medium';

    return AnalysisResult(
      problemTitle: isLikelyFlood
          ? 'Possible Flood or Waterlogging Detected'
          : 'Possible Flood Hazard Requires Verification',
      severity: severity,
      category: 'Water Logging',
      description:
          'Offline image analysis detected ${isLikelyFlood ? 'blue-dominant or water-like visual patterns' : 'a hazard scene that could not be classified with confidence'} using local image statistics. This is an on-device preliminary assessment, not a definitive Gemini analysis. $imageWidth x $imageHeight image data was inspected.',
      suggestedActions: const [
        'Move to higher ground and avoid entering standing or moving water.',
        'Do not touch electrical equipment or downed power lines near water.',
        'Contact 112 or the local disaster control room when internet service returns.',
      ],
      isOffline: true,
      source: 'ON_DEVICE',
    );
  }

  static Future<AnalysisResult> analyzeImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('The selected image could not be found.');
      }

      final imageBytes = await imageFile.readAsBytes();
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' || 'heif' => 'image/heic',
        _ => 'image/jpeg',
      };

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
      );

      const prompt =
          "You are an AI disaster and hazard assessment expert. Analyze this flood or disaster image objectively. Return valid JSON only with keys: 'problemTitle' (String), 'severity' (High, Medium, or Low), 'category' (String like Water Logging, Structural Risk, Traffic Hazard, or Other), 'description' (Detailed description), and 'suggestedActions' (List of 3 actionable restoration steps).";

      final response = await model.generateContent([
        Content.multi([
          InlineDataPart(mimeType, imageBytes),
          TextPart(prompt),
        ]),
      ]);

      final aiResponse = response.text;
      if (aiResponse != null && aiResponse.isNotEmpty) {
        String jsonString = aiResponse.trim();
        if (jsonString.startsWith('```json')) {
          jsonString = jsonString.replaceFirst('```json', '');
        }
        if (jsonString.startsWith('```')) {
          jsonString = jsonString.replaceFirst('```', '');
        }
        if (jsonString.endsWith('```')) {
          jsonString = jsonString.substring(0, jsonString.length - 3);
        }

        final data = jsonDecode(jsonString.trim()) as Map<String, dynamic>;
        final actions =
            (data['suggestedActions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [
              'Inspect the area for safety hazards.',
              'Clear any visible blockages.',
              'Contact local authorities if assistance is needed.',
            ];

        return AnalysisResult(
          problemTitle: data['problemTitle'] ?? 'Hazard Detected',
          severity: data['severity'] ?? 'Medium',
          category: data['category'] ?? 'General Hazard',
          description:
              data['description'] ??
              'AI analyzed the captured image via Gemini.',
          suggestedActions: actions,
          isOffline: false,
          source: 'CLOUD',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Firebase image analysis error: $e');
    }

    throw Exception(
      'Firebase Hybrid AI analysis could not complete. Check your connection and try again.',
    );
  }
}
