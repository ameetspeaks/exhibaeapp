import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class MediaStep extends StatefulWidget {
  const MediaStep({super.key});

  @override
  State<MediaStep> createState() => _MediaStepState();
}

class _MediaStepState extends State<MediaStep> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isUploading = false;
  String? _uploadError;

  Future<void> _pickAndUploadImages() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final formState = Provider.of<ExhibitionFormState>(context, listen: false);
        final List<String> uploadedUrls = [];

        for (final file in result.files) {
          if (file.bytes != null) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final path = 'exhibition-images/$fileName';
            
            try {
              await _supabaseService.client.storage
                  .from('exhibition-assets')
                  .uploadBinary(path, file.bytes!);

              final url = _supabaseService.getPublicUrl('exhibition-assets', path);
              uploadedUrls.add(url);
            } catch (uploadError) {
              print('Error uploading image $fileName: $uploadError');
              // Continue with other files even if one fails
            }
          }
        }

        if (mounted && uploadedUrls.isNotEmpty) {
          formState.updateMedia(
            images: [...formState.formData.images, ...uploadedUrls],
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadGalleryImages() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final formState = Provider.of<ExhibitionFormState>(context, listen: false);
        final List<Map<String, dynamic>> newGalleryImages = [];

        for (final file in result.files) {
          if (file.bytes != null) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final path = 'gallery-images/$fileName';
            
            try {
              await _supabaseService.client.storage
                  .from('exhibition-assets')
                  .uploadBinary(path, file.bytes!);

              final url = _supabaseService.getPublicUrl('exhibition-assets', path);
              
              // Add to gallery images with type 'gallery'
              newGalleryImages.add({
                'image_url': url,
                'image_type': 'gallery',
                'created_at': DateTime.now().toIso8601String(),
              });
            } catch (uploadError) {
              print('Error uploading gallery image $fileName: $uploadError');
              // Continue with other files even if one fails
            }
          }
        }

        if (mounted && newGalleryImages.isNotEmpty) {
          formState.updateGalleryImages([...formState.formData.galleryImages, ...newGalleryImages]);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadFloorPlan() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final path = 'floor-plans/$fileName';
          
          try {
            await _supabaseService.client.storage
                .from('exhibition-assets')
                .uploadBinary(path, file.bytes!);

            final url = _supabaseService.getPublicUrl('exhibition-assets', path);
            
            if (mounted) {
              Provider.of<ExhibitionFormState>(context, listen: false).updateMedia(
                floorPlan: url,
              );
            }
          } catch (uploadError) {
            print('Error uploading floor plan: $uploadError');
            if (mounted) {
              setState(() {
                _uploadError = 'Failed to upload floor plan: $uploadError';
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final updatedImages = List<String>.from(formState.formData.images);
    updatedImages.removeAt(index);
    
    formState.updateMedia(images: updatedImages);
  }

  void _removeGalleryImage(int index) {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final updatedGalleryImages = List<Map<String, dynamic>>.from(formState.formData.galleryImages);
    updatedGalleryImages.removeAt(index);
    
    formState.updateGalleryImages(updatedGalleryImages);
  }

  void _removeFloorPlan() {
    Provider.of<ExhibitionFormState>(context, listen: false).updateMedia(
      floorPlan: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload images and floor plan for your exhibition',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Exhibition Images Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exhibition Images',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload high-quality images of your exhibition venue',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<ExhibitionFormState>(
                  builder: (context, state, child) {
                    return Column(
                      children: [
                        if (state.formData.images.isNotEmpty) ...[
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.formData.images.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          state.formData.images[index],
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: AppTheme.white.withOpacity(0.1),
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: AppTheme.white.withOpacity(0.6),
                                                size: 32,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton(
                                          onPressed: () => _removeImage(index),
                                          icon: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.errorRed.withOpacity(0.8),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: AppTheme.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickAndUploadImages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.white.withOpacity(0.2),
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _isUploading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate),
                          label: Text(_isUploading ? 'Uploading...' : 'Add Images'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Gallery Images Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gallery Images',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload additional gallery images for your exhibition',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<ExhibitionFormState>(
                  builder: (context, state, child) {
                    return Column(
                      children: [
                        if (state.formData.galleryImages.isNotEmpty) ...[
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.formData.galleryImages.length,
                              itemBuilder: (context, index) {
                                final galleryImage = state.formData.galleryImages[index];
                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          galleryImage['image_url'] as String,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: AppTheme.white.withOpacity(0.1),
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: AppTheme.white.withOpacity(0.6),
                                                size: 32,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton(
                                          onPressed: () => _removeGalleryImage(index),
                                          icon: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.errorRed.withOpacity(0.8),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: AppTheme.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickAndUploadGalleryImages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.white.withOpacity(0.2),
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _isUploading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.photo_library),
                          label: Text(_isUploading ? 'Uploading...' : 'Add Gallery Images'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Floor Plan Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Floor Plan',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a floor plan showing stall layouts',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<ExhibitionFormState>(
                  builder: (context, state, child) {
                    if (state.formData.floorPlan != null) {
                      return Column(
                        children: [
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppTheme.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    state.formData.floorPlan!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: 200,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppTheme.white.withOpacity(0.1),
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: AppTheme.white.withOpacity(0.6),
                                          size: 48,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    onPressed: _removeFloorPlan,
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorRed.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: AppTheme.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    
                    return ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadFloorPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.white.withOpacity(0.2),
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isUploading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(_isUploading ? 'Uploading...' : 'Upload Floor Plan'),
                    );
                  },
                ),
              ],
            ),
          ),
          
          if (_uploadError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorRed.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload error: $_uploadError',
                      style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _uploadError = null;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.errorRed,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
