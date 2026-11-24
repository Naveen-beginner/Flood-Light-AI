class SituationAnalysis {
  final String problemTitle;
  final String description;
  final List<String> suggestedActions;
  final String severity;
  final String category;
  final bool isOffline;

  SituationAnalysis({
    required this.problemTitle,
    required this.description,
    required this.suggestedActions,
    required this.severity,
    required this.category,
    this.isOffline = false,
  });

  Map<String, dynamic> toJson() => {
    'problemTitle': problemTitle,
    'description': description,
    'suggestedActions': suggestedActions,
    'severity': severity,
  };

  factory SituationAnalysis.fromJson(Map<String, dynamic> json) {
    return SituationAnalysis(
      problemTitle: json['problemTitle'] as String,
      description: json['description'] as String,
      suggestedActions: List<String>.from(json['suggestedActions'] as List),
      severity: json['severity'] as String,
      category: json['category'] as String,
      isOffline: false,
    );
  }
}
