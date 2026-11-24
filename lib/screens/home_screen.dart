import 'package:floodlight/screens/admin/admin_dashboard_screen.dart';
import 'package:floodlight/screens/chat/chat_screen.dart';
import 'package:floodlight/screens/report/camera_screen.dart';
import 'package:floodlight/screens/support/emergency_support_screen.dart';
import 'package:floodlight/services/location_service.dart';
import 'package:material_ui/material_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Request precise location permission and pre-fetch location as soon as app opens at home screen
    LocationService.requestPermissionAndFetchLocation();
  }

  Future<void> _showDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('About Flood Light'),
          content: const Text(
            'Flood Light uses Firebase Cloud AI when connected and local emergency guidance when offline.',
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    side: BorderSide(width: 1, color: Colors.grey.shade300),
                    fixedSize: const Size.fromHeight(40),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 20,
            right: 15,
            left: 15,
            bottom: 0,
          ),
          child: Column(
            children: [
              _appBar(context),
              const SizedBox(height: 20.0),
              Text(
                'Report. Respond. Protect.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.05),
              _actionBanner(context),
              const SizedBox(height: 20.0),
              _additionalActionBanner(context),
              const SizedBox(height: 20.0),
              const Text(
                'Make a difference in your community with just one tap.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(width: 1, color: Colors.grey.shade200),
        color: Colors.white,
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
      child: Column(
        children: [
          _item(
            'Join as User',
            'Snap it. AI checks. You report.',
            'Create Issue',
            const Icon(Icons.report_gmailerrorred_sharp, color: Colors.white),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraScreen()),
            ),
          ),
          const SizedBox(height: 10.0),
          Divider(
            color: Colors.grey.shade300,
            indent: 14,
            endIndent: 14,
            thickness: 2.0,
            radius: BorderRadius.circular(20.0),
          ),
          const SizedBox(height: 10.0),
          _item(
            'Join as Admin',
            'Review issues and take action using AI.',
            'Open portal',
            const Icon(Icons.checklist_sharp, color: Colors.white),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            ),
          ),
          const SizedBox(height: 10.0),
          Divider(
            color: Colors.grey.shade300,
            indent: 14,
            endIndent: 14,
            thickness: 2.0,
            radius: BorderRadius.circular(20.0),
          ),
          const SizedBox(height: 10.0),
          _item(
            'Chat with AI',
            'Get immediate guidance online or offline.',
            'Chat now',
            const Icon(Icons.chat_bubble_outline, color: Colors.white),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FloodHybridChatScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _additionalActionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(width: 1, color: Colors.grey.shade200),
        color: Colors.white,
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
      child: _item(
        'Emergency Help',
        'Get flood safety guidance and emergency support.',
        'Get Help',
        const Icon(Icons.emergency_outlined, color: Colors.white),
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmergencySupportScreen()),
        ),
      ),
    );
  }

  Column _item(
    String title,
    String subtitle,
    String buttonTitle,
    Icon icon,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 15.0),
        Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                fixedSize: const Size(130, 48),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40.0),
                ),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      buttonTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  icon,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _appBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const Icon(Icons.flourescent_outlined),
            const SizedBox(width: 10),
            Text(
              'Flood Light',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => _showDialog(context),
          icon: const Icon(Icons.info_outline),
        ),
      ],
    );
  }
}
