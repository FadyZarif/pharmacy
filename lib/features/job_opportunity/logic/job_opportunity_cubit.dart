import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/job_opportunity/data/models/job_opportunity_model.dart';

import '../../../core/helpers/constants.dart';

part 'job_opportunity_state.dart';

class JobOpportunityCubit extends Cubit<JobOpportunityState> {
  JobOpportunityCubit() : super(JobOpportunityInitial());

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add new job opportunity
  Future<void> addJobOpportunity({
    required String fullName,
    required String whatsappPhone,
    required String qualification,
    required String graduationYear,
    required String address,
  }) async {
    emit(JobOpportunityAdding());
    try {
      final docRef = _db.collection('job_opportunities').doc();

      final jobOpportunity = JobOpportunityModel(
        id: docRef.id,
        fullName: fullName,
        whatsappPhone: whatsappPhone,
        qualification: qualification,
        graduationYear: graduationYear,
        address: address,
        addedByEmployeeId: currentUser.uid,
        addedByEmployeeName: currentUser.name,
        branchId: currentUser.currentBranch.id,
        branchName: currentUser.currentBranch.name,
        createdAt: null,
      );

      await docRef.set(jobOpportunity.toJson());
      emit(JobOpportunityAdded('Job opportunity added successfully'));
    } catch (e) {
      emit(JobOpportunityAddingError(e.toString()));
    }
  }

  // Fetch job opportunities based on user role
  Future<void> fetchJobOpportunities() async {
    emit(JobOpportunityLoading());
    try {
      Query query = _db.collection('job_opportunities');

      // If staff or subManager, filter by their branch
      if (!currentUser.isManagement) {
        query = query.where('branchId', isEqualTo: currentUser.currentBranch.id);
      } else {
        // For management (admin/manager), filter by branches they have access to
        final branchIds = currentUser.branches.map((branch) => branch.id).toList();
        if (branchIds.isNotEmpty) {
          query = query.where('branchId', whereIn: branchIds);
        }
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      final opportunities = snapshot.docs
          .map((doc) => JobOpportunityModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      emit(JobOpportunityLoaded(opportunities));
    } catch (e) {
      emit(JobOpportunityError(e.toString()));
    }
  }

  // Delete job opportunity (optional - for admin/manager)
  Future<void> deleteJobOpportunity(String id) async {
    emit(JobOpportunityLoading());
    try {
      await _db.collection('job_opportunities').doc(id).delete();
      emit(JobOpportunityAdded('Job opportunity deleted successfully'));
    } catch (e) {
      emit(JobOpportunityError(e.toString()));
    }
  }
}

