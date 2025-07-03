import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('History Screen', style: TextStyle(fontSize: 22, color: Colors.grey)),
          Text('This page will show past activities.'),
        ],
      ),
    );
  }
}