import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/exhibition_form_state.dart';
import '../widgets/exhibition_form/basic_info_step.dart';
import '../widgets/exhibition_form/location_step.dart';
import '../widgets/exhibition_form/media_step.dart';
import '../widgets/exhibition_form/amenities_step.dart';
import '../widgets/exhibition_form/pricing_step.dart';
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
      case ExhibitionFormStep.basicInfo:
        return const BasicInfoStep();
      case ExhibitionFormStep.location:
        return const LocationStep();
      case ExhibitionFormStep.media:
        return const MediaStep();
      case ExhibitionFormStep.amenities:
        return const AmenitiesStep();
      case ExhibitionFormStep.pricing:
        return const PricingStep();
      case ExhibitionFormStep.review:
        return const ReviewStep();
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
                    if (_formState.currentStep == ExhibitionFormStep.basicInfo) {
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
              body: Column(
                children: [
                  // Progress Indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    color: AppTheme.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppTheme.white.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.white),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
            
                  // Current Step Content
                  Expanded(
                    child: Consumer<ExhibitionFormState>(
                      builder: (context, state, child) {
                        if (state.isLoading) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                            ),
                          );
                        }

                        if (state.error != null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 18,
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
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    state.setError(null);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.white.withOpacity(0.2),
                                    foregroundColor: AppTheme.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildCurrentStep();
                      },
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: Consumer<ExhibitionFormState>(
                builder: (context, state, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.gradientBlack,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (state.currentStep != ExhibitionFormStep.basicInfo)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: state.previousStep,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.white,
                                side: BorderSide(
                                  color: AppTheme.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                        if (state.currentStep != ExhibitionFormStep.basicInfo)
                          const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: state.canProceed()
                                ? () async {
                                    if (state.currentStep == ExhibitionFormStep.review) {
                                      try {
                                        state.setLoading(true);
                                        state.setError(null);

                                        final supabaseService = SupabaseService.instance;
                                        final userId = supabaseService.currentUser?.id;
                                        if (userId == null) {
                                          throw Exception('User not authenticated');
                                        }

                                        final formData = state.formData;
                                        final data = {
                                          ...formData.toJson(),
                                          'organiser_id': userId,
                                          'status': formData.isPublished ? 'published' : 'draft',
                                        };

                                        if (formData.id != null) {
                                          // Update existing exhibition
                                          await supabaseService.client
                                              .from('exhibitions')
                                              .update(data)
                                              .eq('id', formData.id ?? '');
                                        } else {
                                          // Create new exhibition
                                          await supabaseService.client
                                              .from('exhibitions')
                                              .insert(data);
                                        }

                                        if (mounted) {
                                          Navigator.pop(context, true);
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          state.setError(e.toString());
                                        }
                                      } finally {
                                        if (mounted) {
                                          state.setLoading(false);
                                        }
                                      }
                                    } else {
                                      state.nextStep();
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: state.canProceed()
                                  ? AppTheme.white
                                  : AppTheme.white.withOpacity(0.3),
                              foregroundColor: AppTheme.gradientBlack,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              state.currentStep == ExhibitionFormStep.review
                                  ? state.isEditing ? 'Save Changes' : 'Create Exhibition'
                                  : 'Continue',
                            ),
                          ),
                        ),
                      ],
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