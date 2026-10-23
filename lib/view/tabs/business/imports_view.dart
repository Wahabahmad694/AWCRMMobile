import 'package:flutter/material.dart';

import '../../widget/app_drawer.dart';
import '../../widget/app_header.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';

class ImportsView extends StatelessWidget {
  const ImportsView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppHeader(
      title: 'Imports',
      isSignedIn: sl<AuthRepository>().isSignedIn,
    ),
    drawer: const AppDrawer(currentRoute: '/imports'),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(
          Icons.upload_file_outlined,
          size: 52,
          color: Color(0xFF0878C9),
        ),
        const SizedBox(height: 20),
        const Text(
          'Bring your business with you',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Move existing customer and product records into your workspace.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        for (final item in [
          (
            Icons.people_outline,
            'Customers',
            'Names, contact details and addresses',
          ),
          (
            Icons.inventory_2_outlined,
            'Products',
            'Products, prices and stock references',
          ),
        ])
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: Icon(item.$1),
              title: Text(
                item.$2,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(item.$3),
            ),
          ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Imports are not available yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              SizedBox(height: 8),
              Text(
                'Your current service does not support imports from the app. You can add customers and products individually from their sections.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
