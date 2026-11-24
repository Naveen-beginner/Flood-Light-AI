import 'package:material_ui/material_ui.dart';

import '../home_screen.dart';

class IssueCreatedSuccessScreen extends StatefulWidget {
  const IssueCreatedSuccessScreen({super.key});

  @override
  State<IssueCreatedSuccessScreen> createState() =>
      _IssueCreatedSuccessScreenState();
}

class _IssueCreatedSuccessScreenState extends State<IssueCreatedSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1A6750A4),
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1A32A852),
                ),
              ),
            ),
            Positioned(
              top: 15,
              right: 15,
              child: IconButton(
                tooltip: 'Close',
                onPressed: _goToHome,
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                icon: const Icon(Icons.close),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF72D59A), Color(0xFF32A852)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF32A852)
                                    .withValues(alpha: 0.28),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 78,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),
                      const Text(
                        'Issue reported!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF25235B),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.volunteer_activism_rounded,
                              color: Color(0xFF6750A4),
                              size: 28,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Thank you for making a difference. Your report will help local authorities take action.',
                                style: TextStyle(
                                  height: 1.5,
                                  fontSize: 15,
                                  color: Color(0xFF5F6475),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => HomeScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(20.0),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.0),
                            side: BorderSide(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          elevation: 4,
                          shadowColor: Colors.white10.withValues(alpha: 0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: .center,
                          crossAxisAlignment: .center,
                          children: [
                            Icon(Icons.home_outlined, color: Colors.blueGrey),
                            SizedBox(width: 10),
                            Text(
                              'Back to home',
                              style: TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                letterSpacing: 0.5,
                                wordSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
