import 'dart:io';

import 'package:camera/camera.dart';
import 'package:floodlight/screens/report/issue_created_success.dart';
import 'package:floodlight/services/hybrid_ai_service.dart';
import 'package:floodlight/services/issue_repository.dart';
import 'package:floodlight/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:material_ui/material_ui.dart';

class AnalysisSubmitScreen extends StatefulWidget {
  const AnalysisSubmitScreen({super.key, required this.photo});

  final XFile photo;

  @override
  State<StatefulWidget> createState() => _AnalysisSubmitScreenState();
}

class _AnalysisSubmitScreenState extends State<AnalysisSubmitScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _submissionError;
  AnalysisResult? _analysisResult;
  Position? _location;

  @override
  void initState() {
    super.initState();
    _runHybridAnalysis();
  }

  Future<void> _runHybridAnalysis() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Fetch precise location and run Hybrid AI analysis in parallel
    final locationFuture = LocationService.fetchPreciseLocation();
    final analysisFuture = HybridAiService.analyzeImage(
      File(widget.photo.path),
    );

    final results = await Future.wait<Object?>([
      locationFuture,
      analysisFuture,
    ]);

    if (!mounted) return;
    setState(() {
      _location = results[0] as Position?;
      _analysisResult = results[1] as AnalysisResult;
      _isLoading = false;
    });
  }

  Future<void> _submitIssue() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    final newIssue = ReportedIssue(
      id: 'ISSUE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      problemTitle: _analysisResult?.problemTitle ?? 'Hazard Detected',
      severity: _analysisResult?.severity ?? 'High',
      category: _analysisResult?.category ?? 'Water Logging',
      description: _analysisResult?.description ?? 'AI analyzed image.',
      suggestedActions: _analysisResult?.suggestedActions ?? [],
      locationTag: _location != null
          ? 'Lat: ${_location!.latitude.toStringAsFixed(4)}, Lng: ${_location!.longitude.toStringAsFixed(4)}'
          : 'GPS Location Recorded',
      latitude: _location?.latitude ?? 17.3850,
      longitude: _location?.longitude ?? 78.4867,
      timestamp: 'Just now',
      status: 'Pending',
      photoPath: widget.photo.path,
      isOfflineAi: _analysisResult?.isOffline ?? false,
    );

    try {
      await IssueRepository.submitIssue(newIssue);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const IssueCreatedSuccessScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submissionError =
            'Unable to submit report. Check connection and try again.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10, right: 15, left: 15),
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingAnimationWidget.halfTriangleDot(
                        color: Colors.indigoAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Running Firebase Hybrid AI Analysis...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Checking connection & running automatic hybrid routing...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Text(
                            'Analysis Report',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 48, height: 48),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildAiModeChip(
                            _analysisResult?.isOffline == true
                                ? '⚡ Gemini Nano (Offline)'
                                : '☁️ Gemini 3.8 Flash (Online)',
                            _analysisResult?.isOffline == true
                                ? Colors.green.shade700
                                : Colors.indigo.shade700,
                          ),
                          if (_location != null)
                            _buildLocationChip(
                              'GPS: ${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}',
                            ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 30,
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                'Problem',
                                style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.black45,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            _analysisResult?.problemTitle ?? 'Hazard Detected',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        children: [
                          _buildFilterChips(
                            _analysisResult?.severity ?? 'High',
                            bgcolor: Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          _buildFilterChips(
                            _analysisResult?.category ?? 'Water Logging',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(
                          File(widget.photo.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        _analysisResult?.description ??
                            'AI analyzed the captured image successfully.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4B5563),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      const Text(
                        'Suggested Actions',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      ...(_analysisResult?.suggestedActions ?? []).map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 5.0),
                              const Icon(
                                Icons.check_circle_outline_outlined,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  action,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      if (_submissionError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _submissionError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      Column(
                        children: [
                          _customActionButton(
                            _isSubmitting ? 'Submitting...' : 'Create Issue',
                            Colors.deepPurpleAccent,
                            Colors.white,
                            Icons.arrow_forward,
                            _isSubmitting ? null : _submitIssue,
                          ),
                          const SizedBox(height: 10.0),
                          _customActionButton(
                            'Retry Analysis',
                            Colors.white,
                            Colors.grey.shade700,
                            Icons.threesixty_sharp,
                            _runHybridAnalysis,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAiModeChip(String label, Color color) {
    return ActionChip(
      onPressed: () {},
      avatar: const Icon(
        Icons.auto_awesome_rounded,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildLocationChip(String label) {
    return ActionChip(
      onPressed: () {},
      avatar: const Icon(
        Icons.location_on_rounded,
        size: 16,
        color: Colors.indigo,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.indigo,
        ),
      ),
      backgroundColor: const Color(0xFFEEF2FF),
      side: const BorderSide(color: Color(0xFFC7D2FE)),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }

  Widget _buildFilterChips(
    String label, {
    IconData? icon,
    Color? bgcolor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(
        icon ?? Icons.report_gmailerrorred_sharp,
        size: 16,
        color: iconColor ?? const Color(0xFFB45309),
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF292524),
        ),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      visualDensity: VisualDensity.compact,
      backgroundColor: bgcolor ?? const Color(0xFFFFF7ED),
      side: const BorderSide(color: Color(0xFFFED7AA)),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }

  Widget _customActionButton(
    String label,
    Color bgcolor,
    Color textColor,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: bgcolor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
          side: BorderSide(width: 1, color: Colors.grey.shade300),
        ),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: textColor),
        ],
      ),
    );
  }
}
