import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nomor Telepon Darurat')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: AppConstants.emergencyContacts.length,
        itemBuilder: (context, index) {
          final contact = AppConstants.emergencyContacts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SigumiTheme.statusAwas.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: SigumiTheme.statusAwas),
              ),
              title: Text(
                contact['name']!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['desc']!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact['phone']!,
                    style: const TextStyle(
                      color: SigumiTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: SigumiTheme.statusNormal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: Colors.white),
                  onPressed: () => _makeCall(contact['phone']!),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
