import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportedIssue {
  final String id;
  final String problemTitle;
  final String severity; // Critical, High, Medium, Low
  final String category;
  final String description;
  final List<String> suggestedActions;
  final String locationTag;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String status; // Pending, In Progress, Resolved
  final String? photoPath;
  final bool isOfflineAi;

  ReportedIssue({
    required this.id,
    required this.problemTitle,
    required this.severity,
    required this.category,
    required this.description,
    required this.suggestedActions,
    required this.locationTag,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    this.photoPath,
    required this.isOfflineAi,
  });

  Map<String, dynamic> toMap({String? photoUrl}) => {
    'problemTitle': problemTitle,
    'severity': severity,
    'category': category,
    'description': description,
    'suggestedActions': suggestedActions,
    'locationTag': locationTag,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp,
    'status': status,
    'photoUrl': photoUrl ?? photoPath,
    'isOfflineAi': isOfflineAi,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class IssueRepository {
  static final List<ReportedIssue> issues = [];

  static void addIssue(ReportedIssue issue) {
    issues.insert(0, issue);
  }

  static Future<void> submitIssue(ReportedIssue issue) async {
    String? photoUrl;

    if (issue.photoPath != null && issue.photoPath!.isNotEmpty) {
      final photoFile = File(issue.photoPath!);
      if (await photoFile.exists()) {
        final bytes = await photoFile.readAsBytes();
        final extension = issue.photoPath!.split('.').last.toLowerCase();
        final contentType = switch (extension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'heic' || 'heif' => 'image/heic',
          _ => 'image/jpeg',
        };

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('issue_photos')
            .child('${issue.id}.${extension.isEmpty ? 'jpg' : extension}');

        await storageRef.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        );
        photoUrl = await storageRef.getDownloadURL();
      }
    }

    await FirebaseFirestore.instance
        .collection('issues')
        .doc(issue.id)
        .set(issue.toMap(photoUrl: photoUrl));

    addIssue(
      ReportedIssue(
        id: issue.id,
        problemTitle: issue.problemTitle,
        severity: issue.severity,
        category: issue.category,
        description: issue.description,
        suggestedActions: issue.suggestedActions,
        locationTag: issue.locationTag,
        latitude: issue.latitude,
        longitude: issue.longitude,
        timestamp: issue.timestamp,
        status: issue.status,
        photoPath: photoUrl ?? issue.photoPath,
        isOfflineAi: issue.isOfflineAi,
      ),
    );
  }

  static Future<void> fetchIssues() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('issues')
        .orderBy('createdAt', descending: true)
        .get();

    issues
      ..clear()
      ..addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return ReportedIssue(
            id: doc.id,
            problemTitle: data['problemTitle'] as String? ?? 'Hazard Detected',
            severity: data['severity'] as String? ?? 'High',
            category: data['category'] as String? ?? 'Water Logging',
            description:
                data['description'] as String? ??
                'AI analyzed the captured image successfully.',
            suggestedActions:
                (data['suggestedActions'] as List<dynamic>? ?? const [])
                    .map((action) => action.toString())
                    .toList(),
            locationTag:
                data['locationTag'] as String? ?? 'GPS Location Recorded',
            latitude: (data['latitude'] as num?)?.toDouble() ?? 17.3850,
            longitude: (data['longitude'] as num?)?.toDouble() ?? 78.4867,
            timestamp: data['timestamp'] as String? ?? 'Just now',
            status: data['status'] as String? ?? 'Pending',
            photoPath: data['photoUrl'] as String?,
            isOfflineAi: data['isOfflineAi'] as bool? ?? false,
          );
        }),
      );
  }
}
