import 'package:flutter/material.dart';

class VendorHomeScreen extends StatelessWidget {
  const VendorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.new_releases_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('New Jobs Screen', style: TextStyle(fontSize: 22, color: Colors.grey)),
          Text('This page will show new job assignments for the vendor.'),
        ],
      ),
    );
  }
}