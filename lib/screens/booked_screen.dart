import 'package:flutter/material.dart';

class BookedScreen extends StatelessWidget {
  const BookedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Booked Items Screen', style: TextStyle(fontSize: 22, color: Colors.grey)),
          Text('This page will show confirmed bookings.'),
        ],
      ),
    );
  }
}