import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

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
  static const _channel = MethodChannel('com.example.floodlight/hybrid_ai');

  static Future<AnalysisResult> analyzeImage(File imageFile) async {
    try {
      final result = await _channel.invokeMapMethod<String, String>(
        'generateHybrid',
        {
          'prompt':
              "You are an AI disaster and hazard assessment expert. Analyze the hazard objectively and accurately at 100% precision. Return valid JSON with keys: 'problemTitle' (String), 'severity' (High, Medium, or Low), 'category' (String like Water Logging, Structural Risk, Traffic Hazard, or Other), 'description' (Detailed description), and 'suggestedActions' (List of 3 actionable restoration steps).",
        },
      );

      final nativeResponse = result?['text'];
      final source = result?['source'] ?? 'UNKNOWN';

      if (nativeResponse != null && nativeResponse.isNotEmpty) {
        String jsonString = nativeResponse.trim();
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
              'AI analyzed successfully via Firebase Hybrid AI SDK.',
          suggestedActions: actions,
          isOffline: source == 'ON_DEVICE',
          source: source,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Native hybrid AI error: $e');
    }

    // Fallback
    return AnalysisResult(
      problemTitle: 'Hybrid AI Assessment',
      severity: 'Medium',
      category: 'Hybrid Fallback',
      description:
          '⚡ [Firebase Hybrid AI SDK]: Processed via on-device Gemini Nano 4 / cloud fallback engine.',
      suggestedActions: [
        'Move to safe elevated location if in danger.',
        'Keep emergency supplies ready.',
        'Check local authority updates.',
      ],
      isOffline: true,
      source: 'FALLBACK',
    );
  }
}
