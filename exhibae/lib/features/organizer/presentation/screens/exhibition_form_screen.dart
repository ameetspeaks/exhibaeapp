import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/exhibition_form_state.dart';
import '../widgets/exhibition_form/basic_details_step.dart';
import '../widgets/exhibition_form/stalls_step.dart';
import '../widgets/exhibition_form/gallery_step.dart';
import '../widgets/exhibition_form/review_step.dart';

class ExhibitionFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingExhibition;

  const ExhibitionFormScreen({
    super.key,
    this.existingExhibition,
  });

  @override
  State<ExhibitionFormScreen> createState() => _ExhibitionFormScreenState();
}

class _ExhibitionFormScreenState extends State<ExhibitionFormScreen> {
  late final ExhibitionFormState _formState;

  @override
  void initState() {
    super.initState();
    _formState = ExhibitionFormState();
    _formState.init(existingData: widget.existingExhibition);
  }

  @override
  void dispose() {
    _formState.dispose();
    super.dispose();
  }

  Widget _buildCurrentStep() {
    switch (_formState.currentStep) {
      case ExhibitionFormStep.basicDetails:
        return const BasicDetailsStep();
      case ExhibitionFormStep.stallLayout:
        return const StallsStep();
      case ExhibitionFormStep.gallery:
        return const GalleryStep();
      case ExhibitionFormStep.review:
        return const ReviewStep();
    }
  }

  String _getStepTitle(ExhibitionFormStep step) {
    switch (step) {
      case ExhibitionFormStep.basicDetails:
        return 'Basic Details';
      case ExhibitionFormStep.stallLayout:
        return 'Stall Layout';
      case ExhibitionFormStep.gallery:
        return 'Gallery';
      case ExhibitionFormStep.review:
        return 'Review & Submit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gradientBlack,
            AppTheme.gradientPink,
          ],
        ),
      ),
      child: ChangeNotifierProvider<ExhibitionFormState>.value(
        value: _formState,
        child: Consumer<ExhibitionFormState>(
          builder: (context, formState, _) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  widget.existingExhibition != null
                      ? 'Edit Exhibition'
                      : 'Create Exhibition',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: IconButton(
                  onPressed: () {
                    if (_formState.currentStep == ExhibitionFormStep.basicDetails) {
                      Navigator.pop(context);
                    } else {
                      _formState.previousStep();
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.white,
                    ),
                  ),
                ),
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.gradientBlack,
                      AppTheme.gradientBlack.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Progress Indicator
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.white.withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Consumer<ExhibitionFormState>(
                        builder: (context, state, child) {
                          final currentIndex = ExhibitionFormStep.values.indexOf(state.currentStep);
                          final progress = (currentIndex + 1) / ExhibitionFormStep.values.length;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Step ${currentIndex + 1} of ${ExhibitionFormStep.values.length}',
                                    style: TextStyle(
                                      color: AppTheme.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${(progress * 100).round()}%',
                                      style: const TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppTheme.white.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.white),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getStepTitle(state.currentStep),
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            
                    // Current Step Content
                    Expanded(
                      child: Consumer<ExhibitionFormState>(
                        builder: (context, state, child) {
                          if (state.isLoading) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: AppTheme.white.withOpacity(0.8),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (state.error != null) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.errorRed.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: AppTheme.errorRed,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Error',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        state.error!,
                                        style: TextStyle(
                                          color: AppTheme.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () {
                                          state.setError(null);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.white.withOpacity(0.2),
                                          foregroundColor: AppTheme.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Try Again'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return _buildCurrentStep();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: Consumer<ExhibitionFormState>(
                builder: (context, state, child) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          if (state.currentStep != ExhibitionFormStep.basicDetails) ...[
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: OutlinedButton(
                                  onPressed: state.previousStep,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.white,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.arrow_back, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Back',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            flex: state.currentStep == ExhibitionFormStep.basicDetails ? 1 : 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: state.canProceed()
                                      ? [AppTheme.white, AppTheme.white.withOpacity(0.9)]
                                      : [AppTheme.white.withOpacity(0.3), AppTheme.white.withOpacity(0.2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: state.canProceed()
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.white.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ElevatedButton(
                                onPressed: state.canProceed()
                                    ? () async {
                                        // Save current step to database
                                        final success = await state.saveCurrentStep();
                                        if (!success) {
                                          return; // Error is already set in state
                                        }
                                        
                                        if (state.currentStep == ExhibitionFormStep.basicDetails) {
                                          // Move to stall layout step instead of skipping it
                                          state.nextStep();
                                        } else if (state.currentStep == ExhibitionFormStep.stallLayout) {
                                          // Move to gallery step
                                          state.nextStep();
                                        } else if (state.currentStep == ExhibitionFormStep.gallery) {
                                          // Move to review step
                                          state.nextStep();
                                        } else if (state.currentStep == ExhibitionFormStep.review) {
                                          // Submit for approval
                                          final success = await state.submitForApproval();
                                          if (success && mounted) {
                                            Navigator.pop(context, true);
                                          }
                                        } else {
                                          // Move to next step
                                          state.nextStep();
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: state.canProceed()
                                      ? AppTheme.gradientBlack
                                      : AppTheme.white.withOpacity(0.5),
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      state.currentStep == ExhibitionFormStep.gallery
                                          ? 'Review & Submit'
                                          : state.currentStep == ExhibitionFormStep.review
                                              ? 'Submit for Approval'
                                              : 'Save & Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (state.currentStep != ExhibitionFormStep.review) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            );
          },
        ),
      ),
    );
  }
}