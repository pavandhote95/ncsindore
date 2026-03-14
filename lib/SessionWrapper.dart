// session_wrapper.dart
import 'package:flutter/material.dart';
import 'SessionManager.dart';

class SessionWrapper extends StatefulWidget {
  final Widget child;

  const SessionWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  final sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    // sessionManager.startTimer();
  }

  @override
  void dispose() {
    // sessionManager.cancelTimer();
    super.dispose();
  }

  void _handleUserInteraction([_]) {
    // sessionManager.resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    // The Listener detects all user interactions
    return Listener(
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      // Prevents the listener from blocking other gestures
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
