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
    return _PanelCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work_outline, color: ColorsManger.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  opportunity.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (canDelete && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
            ],
          ),
          const SizedBox(height: 12),

          _InfoRow(icon: Icons.school, label: 'Qualification', value: opportunity.qualification),
          _InfoRow(icon: Icons.calendar_today, label: 'Graduation Year', value: opportunity.graduationYear),
          _InfoRow(icon: Icons.location_on, label: 'Address', value: opportunity.address),

          const Divider(height: 22),

          _InfoRow(icon: Icons.business, label: 'Branch', value: opportunity.branchName),
          _InfoRow(icon: Icons.person, label: 'Added By', value: opportunity.addedByEmployeeName),
          if (opportunity.createdAt != null)
            _InfoRow(
              icon: Icons.access_time,
              label: 'Added On',
              value: DateFormat('dd/MM/yyyy hh:mm a').format(opportunity.createdAt!),
            ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(opportunity.whatsappPhone),
              icon: const Icon(Icons.chat),
              label: Text(
                'WhatsApp: ${opportunity.whatsappPhone}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // keep logic unchanged; only UI
}

List<BoxShadow> _panelShadow() => [
      BoxShadow(
        color: ColorsManger.primary.withValues(alpha: 0.14),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];

class _PanelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const _PanelCard({
    required this.child,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.16)),
        boxShadow: _panelShadow(),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ColorsManger.primary),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha: 0.82),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

