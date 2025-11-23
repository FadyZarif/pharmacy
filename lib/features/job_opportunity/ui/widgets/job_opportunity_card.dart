import 'package:flutter/material.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/job_opportunity/data/models/job_opportunity_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class JobOpportunityCard extends StatelessWidget {
  final JobOpportunityModel opportunity;
  final bool canDelete;
  final VoidCallback? onDelete;

  const JobOpportunityCard({
    super.key,
    required this.opportunity,
    this.canDelete = false,
    this.onDelete,
  });

  Future<void> _openWhatsApp(String phoneNumber) async {
    final url = 'https://wa.me/$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    opportunity.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canDelete && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            _buildInfoRow(Icons.school, 'Qualification', opportunity.qualification),
            _buildInfoRow(Icons.calendar_today, 'Graduation Year', opportunity.graduationYear),
            _buildInfoRow(Icons.location_on, 'Address', opportunity.address),

            const Divider(height: 20),

            _buildInfoRow(Icons.business, 'Branch', opportunity.branchName),
            _buildInfoRow(Icons.person, 'Added By', opportunity.addedByEmployeeName),

            if (opportunity.createdAt != null)
              _buildInfoRow(
                Icons.access_time,
                'Added On',
                DateFormat('dd/MM/yyyy hh:mm a').format(opportunity.createdAt!),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsApp(opportunity.whatsappPhone),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: Text(
                  'WhatsApp: ${opportunity.whatsappPhone}',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ColorsManger.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

