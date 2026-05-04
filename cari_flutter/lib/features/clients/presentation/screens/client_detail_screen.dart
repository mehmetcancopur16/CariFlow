import 'package:flutter/material.dart';

class ClientDetailScreen extends StatelessWidget {
  const ClientDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Musteri Detayi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Secilen Musteri ID: $id'),
            const SizedBox(height: 12),
            const Text('Buraya islem gecmisi gelecek'),
          ],
        ),
      ),
    );
  }
}
