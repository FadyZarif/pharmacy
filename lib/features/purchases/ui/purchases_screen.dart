import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/core/themes/colors.dart';
import 'package:pharmacy/features/purchases/data/models/branch_purchase_model.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _db = FirebaseFirestore.instance;
  final _egp = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 2);
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String? _selectedBranchId;
  String? _selectedBranchName;

  bool get _isSubManager => currentUser.role == Role.subManager;
  bool get _canEdit => _isSubManager;

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _selectedBranchId = currentUser.currentBranch.id;
    _selectedBranchName = currentUser.currentBranch.name;
  }

  Query<Map<String, dynamic>> _query() {
    return _db
        .collection('branch_purchases')
        .where('branchId', isEqualTo: _selectedBranchId)
        .where('monthKey', isEqualTo: _monthKey)
        .orderBy('purchaseDate', descending: true)
        .orderBy('createdAt', descending: true);
  }

  Future<double?> _loadMonthlyTarget() async {
    if (_selectedBranchId == null) return null;
    final doc = await _db
        .collection('branches')
        .doc(_selectedBranchId)
        .collection('monthly_target')
        .doc(_monthKey)
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['monthlyTarget'] as num?)?.toDouble();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
  }

  Future<void> _savePurchase({
    String? purchaseId,
    required double amount,
    required PurchaseSourceType sourceType,
    required String supplierName,
    required String notes,
    required DateTime purchaseDate,
    String? invoiceUrl,
  }) async {
    if (_selectedBranchId == null || _selectedBranchName == null) return;
    final ref = _db.collection('branch_purchases');
    final payload = <String, dynamic>{
      'branchId': _selectedBranchId,
      'branchName': _selectedBranchName,
      'monthKey':
          '${purchaseDate.year}-${purchaseDate.month.toString().padLeft(2, '0')}',
      'amount': amount,
      'sourceType': BranchPurchaseModel.sourceToString(sourceType),
      'supplierName': supplierName.trim(),
      'notes': notes.trim(),
      'invoiceUrl': invoiceUrl ?? '',
      'purchaseDate': Timestamp.fromDate(DateTime(
        purchaseDate.year,
        purchaseDate.month,
        purchaseDate.day,
      )),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (purchaseId == null) {
      await ref.add({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
        'createdByUid': currentUser.uid,
        'createdByName': currentUser.name,
        'createdByRole': currentUser.role.name,
      });
    } else {
      await ref.doc(purchaseId).update(payload);
    }
  }

  Future<String> _uploadInvoice(PlatformFile file) async {
    final branchId = _selectedBranchId ?? 'unknown';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = 'branch_purchases/$branchId/$fileName';
    final ref = FirebaseStorage.instance.ref().child(path);
    if (file.bytes != null) {
      await ref.putData(file.bytes!);
    } else {
      throw Exception('File data is missing');
    }
    return ref.getDownloadURL();
  }

  Future<void> _openAddEditDialog({BranchPurchaseModel? existing}) async {
    if (_selectedBranchId == null) return;
    final amountController = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    final supplierController = TextEditingController(text: existing?.supplierName ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    PurchaseSourceType source = existing?.sourceType ?? PurchaseSourceType.company;
    DateTime purchaseDate = existing?.purchaseDate ?? DateTime.now();
    PlatformFile? pickedFile;
    String invoiceUrl = existing?.invoiceUrl ?? '';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            title: Text(existing == null ? 'Add Purchase' : 'Edit Purchase'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final amount = double.tryParse((value ?? '').trim());
                        if (amount == null || amount <= 0) return 'Enter valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PurchaseSourceType>(
                      initialValue: source,
                      decoration: const InputDecoration(
                        labelText: 'Source *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: PurchaseSourceType.company,
                          child: Text('Company'),
                        ),
                        DropdownMenuItem(
                          value: PurchaseSourceType.warehouse,
                          child: Text('Warehouse'),
                        ),
                      ],
                      onChanged: (v) => setLocalState(() => source = v ?? source),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Purchase Date'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(purchaseDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: purchaseDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setLocalState(() => purchaseDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        pickedFile != null
                            ? 'Selected: ${pickedFile!.name}'
                            : invoiceUrl.isNotEmpty
                                ? 'Invoice attached'
                                : 'Attach invoice (optional)',
                      ),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          setLocalState(() {
                            pickedFile = result.files.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final amount = double.parse(amountController.text.trim());
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(
                        child: CircularProgressIndicator(color: ColorsManger.primary),
                      ),
                    );
                    if (pickedFile != null) {
                      invoiceUrl = await _uploadInvoice(pickedFile!);
                    }
                    await _savePurchase(
                      purchaseId: existing?.id,
                      amount: amount,
                      sourceType: source,
                      supplierName: supplierController.text,
                      notes: notesController.text,
                      purchaseDate: purchaseDate,
                      invoiceUrl: invoiceUrl,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    await defToast2(
                      context: context,
                      msg: existing == null
                          ? 'Purchase saved successfully'
                          : 'Purchase updated successfully',
                      dialogType: DialogType.success,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    await defToast2(
                      context: context,
                      msg: e.toString(),
                      dialogType: DialogType.error,
                      sec: 4,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: ColorsManger.primary),
                child: Text(existing == null ? 'Save' : 'Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openInvoice(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Branch Purchases'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: ColorsManger.primary,
      ),
      floatingActionButton: _isSubManager
          ? FloatingActionButton.extended(
              backgroundColor: ColorsManger.primary,
              onPressed: () => _openAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Purchase'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: ColorsManger.primary.withValues(alpha: 0.16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: ColorsManger.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ColorsManger.primary.withValues(alpha: 0.14)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store, size: 18, color: ColorsManger.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedBranchName ?? currentUser.currentBranch.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ColorsManger.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query().snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final entries = docs.map(BranchPurchaseModel.fromDoc).toList();
                final total = entries.fold<double>(0, (acc, e) => acc + e.amount);
                return FutureBuilder<double?>(
                  future: _loadMonthlyTarget(),
                  builder: (context, targetSnap) {
                    final target = targetSnap.data;
                    final pct = (target != null && target > 0) ? (total / target * 100) : null;
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: ColorsManger.primary.withValues(alpha: 0.12)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _kpiTile(
                                    'Monthly Target',
                                    target == null ? 'Not set' : _egp.format(target),
                                    Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _kpiTile(
                                    'Total Purchases',
                                    _egp.format(total),
                                    ColorsManger.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _kpiTile(
                                    'Coverage',
                                    pct == null ? 'N/A' : '${pct.toStringAsFixed(1)}%',
                                    Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                            if (pct != null) ...[
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: (pct / 100).clamp(0, 1),
                                minHeight: 8,
                                color: ColorsManger.primary,
                                backgroundColor: Colors.grey.shade300,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _query().snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: ColorsManger.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: ColorsManger.primary.withValues(alpha: 0.12)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text('No purchases in this month'),
                        ),
                      ),
                    );
                  }
                  final entries = docs.map(BranchPurchaseModel.fromDoc).toList();
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final canEditThis = _canEdit;
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: ColorsManger.primary.withValues(alpha: 0.12)),
                        ),
                        child: ListTile(
                          title: Text(
                            _egp.format(e.amount),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _chip(
                                    e.sourceType == PurchaseSourceType.company
                                        ? 'Company'
                                        : 'Warehouse',
                                    e.sourceType == PurchaseSourceType.company
                                        ? Colors.indigo
                                        : Colors.teal,
                                  ),
                                  _chip(
                                    DateFormat('yyyy-MM-dd').format(e.purchaseDate),
                                    Colors.blueGrey,
                                  ),
                                ],
                              ),
                              Text('Date: ${DateFormat('yyyy-MM-dd').format(e.purchaseDate)}'),
                              if (e.supplierName.isNotEmpty)
                                Text('Supplier: ${e.supplierName}'),
                              if (e.notes.isNotEmpty) Text('Notes: ${e.notes}'),
                              Text('By: ${e.createdByName}'),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              if (e.invoiceUrl.isNotEmpty)
                                IconButton(
                                  tooltip: 'Open invoice',
                                  icon: const Icon(Icons.attach_file),
                                  onPressed: () => _openInvoice(e.invoiceUrl),
                                ),
                              if (canEditThis)
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit, color: ColorsManger.primary),
                                  onPressed: () => _openAddEditDialog(existing: e),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}
