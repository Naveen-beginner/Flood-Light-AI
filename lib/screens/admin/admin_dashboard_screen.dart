import 'dart:io';

import 'package:floodlight/services/issue_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedFilter = 'All';

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps.')),
        );
      }
    }
  }

  void _showIssueDetails(ReportedIssue issue) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      issue.id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  issue.problemTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Chip(
                      label: Text(issue.severity.toUpperCase()),
                      backgroundColor:
                          issue.severity.toLowerCase() == 'critical'
                          ? Colors.red.shade50
                          : Colors.amber.shade50,
                      labelStyle: TextStyle(
                        color: issue.severity.toLowerCase() == 'critical'
                            ? Colors.red
                            : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        issue.isOfflineAi
                            ? '⚡ Gemini Nano 4 (Offline)'
                            : '☁️ Gemini 3.8 Flash (Online)',
                      ),
                      backgroundColor: Colors.indigo.shade50,
                      labelStyle: TextStyle(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (issue.photoPath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: issue.photoPath!.startsWith('http')
                        ? Image.network(
                            issue.photoPath!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text('Photo unavailable'),
                                  ),
                                ),
                          )
                        : Image.file(
                            File(issue.photoPath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text('Photo unavailable'),
                                  ),
                                ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'Detailed AI Analysis Report',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  issue.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'AI Suggested Restoration Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 10),
                ...issue.suggestedActions.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            action,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openGoogleMaps(issue.latitude, issue.longitude);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text(
                    'Open in Google Maps',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allIssues = IssueRepository.issues;
    final filteredIssues = _selectedFilter == 'All'
        ? allIssues
        : allIssues
              .where(
                (i) =>
                    i.severity.toLowerCase() == _selectedFilter.toLowerCase() ||
                    i.status.toLowerCase() == _selectedFilter.toLowerCase(),
              )
              .toList();

    final criticalCount = allIssues
        .where(
          (i) =>
              i.severity.toLowerCase() == 'critical' ||
              i.severity.toLowerCase() == 'high',
        )
        .length;
    final pendingCount = allIssues.where((i) => i.status == 'Pending').length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 72,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
            size: 20,
          ),
        ),
        title: Row(
          children: const [
            Text(
              'Admin Command Center',
              style: TextStyle(
                color: Color(0xFF1A237E),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Colors.white,
              ),
              label: const Text(
                'AI Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.indigoAccent,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Metrics Overview matching HomeScreen card design
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Reports',
                    value: '${allIssues.length}',
                    icon: Icons.report_problem_outlined,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'High / Critical',
                    value: '$criticalCount',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Pending Action',
                    value: '$pendingCount',
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // AI Regional Priority Ranking & Restoration Plan Banner
            _buildAiRestorationBanner(),
            const SizedBox(height: 24),

            // Filter Chips & Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Community Issue Stream',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '${filteredIssues.length} items',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('All'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Critical'),
                  const SizedBox(width: 8),
                  _buildFilterTab('High'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Pending'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Issue List
            if (filteredIssues.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No issues found for this filter.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              )
            else
              ...filteredIssues.map((issue) => _buildIssueCard(issue)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiRestorationBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF311B92), Color(0xFF512DA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology_rounded, color: Colors.white70, size: 22),
              SizedBox(width: 8),
              Text(
                'Firebase Hybrid AI Regional Ranking & Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '🤖 AI Municipal Restoration Strategy:\n• Priority 1: Deploy heavy-duty de-watering pumps to NH-16 Main Road intersection.\n• Priority 2: Clear trapped plastic debris at Sector 4 stormwater grates.\n• Priority 3: Set up temporary caution barriers around Station Avenue pockmark.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'AI Restoration Plan dispatched to municipal units!',
                  ),
                  backgroundColor: Colors.indigo,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF311B92),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text(
              'Dispatch AI Action Plan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: Colors.indigo,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4B5563),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.indigo : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildIssueCard(ReportedIssue issue) {
    final isCritical =
        issue.severity.toLowerCase() == 'critical' ||
        issue.severity.toLowerCase() == 'high';
    final severityColor = isCritical ? Colors.redAccent : Colors.amber.shade800;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(width: 1, color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.06),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    issue.severity.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  issue.timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              issue.problemTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              issue.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    issue.locationTag,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (issue.photoPath != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(issue.photoPath!),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openGoogleMaps(issue.latitude, issue.longitude),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo.shade700,
                      side: BorderSide(color: Colors.indigo.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text(
                      'Open Maps',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showIssueDetails(issue),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text(
                      'Open Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
