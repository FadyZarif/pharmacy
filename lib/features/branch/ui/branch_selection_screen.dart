import 'package:flutter/material.dart';
import 'package:pharmacy/core/helpers/constants.dart';
import 'package:pharmacy/features/user/data/models/user_model.dart';
import '../../../core/themes/colors.dart';
import '../../employee/ui/employee_layout.dart';

class BranchSelectionScreen extends StatelessWidget {

  const BranchSelectionScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManger.primaryBackground,
      appBar: AppBar(
        title: const Text('Select Branch',style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: ColorsManger.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Welcome, ${currentUser.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a branch to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // Branch List
            Expanded(
              child: currentUser.branches.isEmpty
                  ? Center(
                      child: Text(
                        'No branches available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: currentUser.branches.length,
                      itemBuilder: (context, index) {
                        final branch = currentUser.branches[index];
                        return _buildBranchCard(context, branch);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, Branch branch) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Set current branch
          currentUser.currentBranch = branch;
          // Callback
          navigateTo(context, EmployeeLayout());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorsManger.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store,
                  color: ColorsManger.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Branch Name
              Expanded(
                child: Text(
                  branch.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

