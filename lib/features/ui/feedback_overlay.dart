import 'package:fitpact/features/exercise/pushup_form_validator.dart';
import 'package:flutter/material.dart';

/// Overlay showing the latest [FormFeedback] with an icon, a text and a
/// fade-in animation. Color reflects the score:
/// green (>= 0.8), yellow (>= 0.5), red (< 0.5).
class FeedbackOverlay extends StatefulWidget {
 /// The feedback to display; null hides the overlay.
 final FormFeedback? feedback;

 /// Creates the overlay.
 const FeedbackOverlay({super.key, required this.feedback});

 Color _colorFor(double score) {
 if (score >= 0.8) return Colors.green;
 if (score >= 0.5) return Colors.yellow;
 return Colors.red;
 }

 IconData _iconFor(double score) {
 if (score >= 0.8) return Icons.check_circle;
 if (score >= 0.5) return Icons.info;
 return Icons.warning;
 }

 @override
 State<FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<FeedbackOverlay>
 with SingleTickerProviderStateMixin {
 late final AnimationController _controller;
 late final Animation<double> _fade;

 @override
 void initState() {
 super.initState();
 _controller = AnimationController(
 vsync: this,
 duration: const Duration(milliseconds: 400),
 );
 _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
 if (widget.feedback != null) _controller.forward();
 }

 @override
 void didUpdateWidget(covariant FeedbackOverlay oldWidget) {
 super.didUpdateWidget(oldWidget);
 if (widget.feedback != oldWidget.feedback) {
 _controller.forward(from: 0);
 }
 }

 @override
 void dispose() {
 _controller.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 final fb = widget.feedback;
 if (fb == null) return const SizedBox.shrink();
 final score = fb.incomplete ? 0.5 : fb.score;
 final color = widget._colorFor(score);
 return FadeTransition(
 opacity: _fade,
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
 decoration: BoxDecoration(
 color: Colors.black54,
 borderRadius: BorderRadius.circular(16),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(widget._iconFor(score), color: color, size: 28),
 const SizedBox(width: 8),
 Flexible(
 child: Text(
 fb.message,
 style: const TextStyle(color: Colors.white, fontSize: 16),
 overflow: TextOverflow.ellipsis,
 ),
 ),
 ],
 ),
 ),
 );
 }
}