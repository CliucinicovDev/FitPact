import 'package:flutter/material.dart';

/// Three-step onboarding flow: welcome, how it works, permissions,
/// with a page indicator, a next button and a skip shortcut.
class OnboardingScreen extends StatefulWidget {
 /// Callback invoked when onboarding completes (via next on the last
 /// page or skip).
 final VoidCallback? onFinish;

 /// Callback invoked at the permissions step to request camera access.
 final Future<bool> Function()? onRequestPermissions;

 /// Creates the onboarding screen.
 const OnboardingScreen({super.key, this.onFinish, this.onRequestPermissions});

 @override
 State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
 final PageController _pageController = PageController();
 int _currentPage = 0;
 bool _permissionsGranted = false;
 String? _permissionMessage;

 static const _pages = 3;

 static const List<({IconData icon, String title, String body})> _content = [
 (
 icon: Icons.fitness_center,
 title: 'Welcome to FitPact',
 body:
 'Train with your squad and let your phone count every rep automatically.',
 ),
 (
 icon: Icons.center_focus_strong,
 title: 'How it works',
 body:
 'Point the camera at yourself. Our pose engine counts reps and checks your form in real time.',
 ),
 (
 icon: Icons.camera_alt,
 title: 'Camera permission',
 body:
 'FitPact needs camera access for rep counting. You can also switch to manual mode anytime.',
 ),
 ];

 @override
 void dispose() {
 _pageController.dispose();
 super.dispose();
 }

 Future<void> _requestPermissions() async {
 final request = widget.onRequestPermissions;
 if (request == null) {
 setState(() => _permissionsGranted = true);
 return;
 }
 final granted = await request();
 setState(() {
 _permissionsGranted = granted;
 _permissionMessage =
 granted ? 'Permission granted' : 'Permission denied - manual mode available';
 });
 }

 Future<void> _next() async {
 if (_currentPage == 2 && !_permissionsGranted) {
 await _requestPermissions();
 }
 if (_currentPage < _pages - 1) {
   setState(() => _currentPage = _currentPage + 1);
   } else {
   widget.onFinish?.call();
  }
  }

 void _skip() => widget.onFinish?.call();

 @override
 Widget build(BuildContext context) {
 final item = _content[_currentPage];
 return Scaffold(
 body: SafeArea(
 child: Column(
 children: [
 Align(
 alignment: Alignment.centerRight,
 child: TextButton(onPressed: _skip, child: const Text('Skip')),
 ),
 Expanded(
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 32),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(item.icon, size: 96,
 color: Theme.of(context).colorScheme.primary),
 const SizedBox(height: 24),
 Text(item.title,
 textAlign: TextAlign.center,
 style: Theme.of(context)
 .textTheme
 .headlineSmall
 ?.copyWith(fontWeight: FontWeight.bold)),
 const SizedBox(height: 16),
 Text(item.body,
 textAlign: TextAlign.center,
 style: Theme.of(context).textTheme.bodyLarge),
 if (_currentPage == 2 && _permissionMessage != null) ...[
 const SizedBox(height: 16),
 Text(_permissionMessage!,
 textAlign: TextAlign.center,
 style: TextStyle(
 color: _permissionsGranted ? Colors.green : Colors.orange,
 )),
 ],
 ],
 ),
 ),
 ),
 Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 for (var i = 0; i < _pages; i++)
 Container(
 margin: const EdgeInsets.symmetric(horizontal: 4),
 width: i == _currentPage ? 24 : 8,
 height: 8,
 decoration: BoxDecoration(
 color: i == _currentPage
 ? Theme.of(context).colorScheme.primary
 : Colors.grey.shade300,
 borderRadius: BorderRadius.circular(4),
 ),
 ),
 ],
 ),
 Padding(
 padding: const EdgeInsets.all(24),
 child: SizedBox(
 width: double.infinity,
 height: 48,
 child: FilledButton(
 onPressed: _next,
 child: Text(
 _currentPage == _pages - 1 ? 'Get started' : 'Next',
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