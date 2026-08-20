import 'package:flutter/material.dart';

class DialogScaffold extends StatelessWidget {
  final Widget child;

  const DialogScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) => child,
        ),
      ),
    );
  }
}
