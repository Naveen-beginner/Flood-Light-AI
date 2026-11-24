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
  static String _shortText(
    String text, {
    required int maxChars,
  }) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= maxChars) return normalized;
    final shortened = normalized.substring(0, maxChars);
    final lastSpace = shortened.lastIndexOf(' ');
    return '${shortened.substring(0, lastSpace > 20 ? lastSpace : maxChars).trim()}...';
  }

  static String _titleText(String text) {
    final shortened = _shortText(text, maxChars: 58);
    return shortened.endsWith('...')
        ? shortened
        : shortened.replaceAll(RegExp(r'[.!?]+$'), '');
  }

  static String _descriptionText(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final sentences = normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((sentence) => sentence.trim().isNotEmpty)
        .take(2)
        .toList();
    return _shortText(
      sentences.isEmpty ? normalized : sentences.join(' '),
      maxChars: 210,
    );
  }

  static List<String> _actionText(List<dynamic>? actions) {
    final source = actions ?? const [];
    final normalized = source
        .map((action) => _shortText(action.toString(), maxChars: 90))
        .where((action) => action.isNotEmpty)
        .take(3)
        .toList();

    return normalized.isEmpty
        ? const [
            'Move to higher ground and avoid flood water.',
            'Keep away from electrical hazards.',
            'Contact local emergency services immediately.',
          ]
        : normalized;
  }

  static Future<AnalysisResult> analyzeOfflineImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('The selected image could not be found.');
    }

    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
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
          ? 'Flood or Waterlogging Likely'
          : 'Flood Hazard Needs Verification',
      severity: severity,
      category: 'Water Logging',
      description:
          isLikelyFlood
          ? 'The image shows possible water or flood patterns. This is a preliminary offline estimate and not a definitive hazard assessment.'
          : 'The image is inconclusive for flood classification. Verify conditions visually and stay clear of unsafe areas.',
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
          "Analyze this flood or disaster image. Be concise and practical. Return valid JSON only with: 'problemTitle' (catchy, one-line title of at most 8 words), 'severity' (High, Medium, or Low), 'category' (Water Logging, Structural Risk, Traffic Hazard, or Other), 'description' (maximum 2 short lines or 210 characters), and 'suggestedActions' (3 short, actionable safety or restoration steps).";

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
          problemTitle: _titleText(
            data['problemTitle']?.toString() ?? 'Flood Hazard Detected',
          ),
          severity: data['severity'] ?? 'Medium',
          category: data['category'] ?? 'General Hazard',
          description: _descriptionText(
            data['description']?.toString() ??
                'A flood hazard was identified for local review.',
          ),
          suggestedActions: _actionText(actions),
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
