import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class GalleryStep extends StatefulWidget {
  const GalleryStep({super.key});

  @override
  State<GalleryStep> createState() => _GalleryStepState();
}

class _GalleryStepState extends State<GalleryStep> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isUploading = false;
  String? _uploadError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingImages();
  }

  Future<void> _loadExistingImages() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

         try {
       final formState = Provider.of<ExhibitionFormState>(context, listen: false);
       await formState.loadGalleryImages(_supabaseService);
     } catch (e) {
       // Handle error silently
     } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImages(String imageType) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // This ensures file bytes are loaded
      );

      if (result != null && result.files.isNotEmpty) {
        final formState = Provider.of<ExhibitionFormState>(context, listen: false);
        final List<Map<String, dynamic>> newImages = [];

                 for (final file in result.files) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            
            // Get exhibition ID from form state
            final formState = Provider.of<ExhibitionFormState>(context, listen: false);
            final exhibitionId = formState.formData.id;
            
            if (exhibitionId == null) {
              throw Exception('Exhibition ID not found. Please save basic details first.');
            }
            
            // Create path based on image type and exhibition ID
            // The RLS policies expect user-specific folders, so we need to include the user ID
            final currentUser = _supabaseService.currentUser;
            if (currentUser?.id == null) {
              throw Exception('User not authenticated. Please log in again.');
            }
            
            String subfolder;
            switch (imageType) {
              case 'cover':
              case 'exhibition':
                subfolder = 'venue';
                break;
              case 'layout':
                subfolder = 'layout';
                break;
              case 'banner':
                subfolder = 'banner';
                break;
              default:
                subfolder = 'gallery';
            }
            
            // Create path that matches RLS policies: {user_id}/{exhibition_id}/{subfolder}/{filename}
            final path = '${currentUser!.id}/$exhibitionId/$subfolder/$fileName';
           
            try {
              // Use the gallery bucket directly since you confirmed it exists
              const String bucketName = 'gallery';
              
              // Upload the file directly to the gallery bucket
              if (file.bytes != null) {
                await _supabaseService.client.storage
                    .from(bucketName)
                    .uploadBinary(path, file.bytes!);
              } else if (file.path != null) {
                await _supabaseService.client.storage
                    .from(bucketName)
                    .upload(path, File(file.path!));
              } else {
                throw Exception('No file data available (bytes or path)');
              }

              final url = _supabaseService.getPublicUrl(bucketName, path);
              
              // Add to gallery images with specified type
              newImages.add({
                'image_url': url,
                'image_type': imageType,
                'created_at': DateTime.now().toIso8601String(),
              });
            } catch (uploadError) {
              setState(() {
                _uploadError = 'Failed to upload $fileName: $uploadError';
              });
              // Continue with other files even if one fails
            }
          }

          if (mounted && newImages.isNotEmpty) {
            final updatedGalleryImages = List<Map<String, dynamic>>.from(formState.formData.galleryImages);
            updatedGalleryImages.addAll(newImages);
            formState.updateGallery(updatedGalleryImages);
            
            // Clear any previous errors if upload was successful
            setState(() {
              _uploadError = null;
            });
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

  Future<void> _removeImage(int index) async {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final imageToRemove = formState.formData.galleryImages[index];
    
    try {
      // Remove from database if it exists there
      if (formState.formData.id != null) {
        await _supabaseService.client
            .from('gallery_images')
            .delete()
            .eq('exhibition_id', formState.formData.id!)
            .eq('image_url', imageToRemove['image_url'])
            .eq('image_type', imageToRemove['image_type']);
      }
      
             // Remove from form state
       final updatedGalleryImages = List<Map<String, dynamic>>.from(formState.formData.galleryImages);
       updatedGalleryImages.removeAt(index);
       formState.updateGallery(updatedGalleryImages);
     } catch (e) {
       // Still remove from form state even if database removal fails
       final updatedGalleryImages = List<Map<String, dynamic>>.from(formState.formData.galleryImages);
       updatedGalleryImages.removeAt(index);
       formState.updateGallery(updatedGalleryImages);
     }
  }

  List<Map<String, dynamic>> _getImagesByType(String imageType) {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    return formState.formData.galleryImages
        .where((image) => image['image_type'] == imageType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gallery & Images',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload images for your exhibition gallery',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Cover Images Section
          _buildImageSection(
            title: 'Cover Images',
            description: 'Main exhibition cover images',
            imageType: 'cover',
            icon: Icons.photo,
          ),
          const SizedBox(height: 24),
          
          // Exhibition Images Section
          _buildImageSection(
            title: 'Exhibition Images',
            description: 'Images showcasing the exhibition venue',
            imageType: 'exhibition',
            icon: Icons.business,
          ),
          const SizedBox(height: 24),
          
                     // Layout Images Section
           _buildImageSection(
             title: 'Layout Images',
             description: 'Floor plans and layout diagrams',
             imageType: 'layout',
             icon: Icons.map,
           ),
           const SizedBox(height: 24),
           
                       // Banner Images Section
            _buildImageSection(
              title: 'Banner Images',
              description: 'Promotional banners and headers',
              imageType: 'banner',
              icon: Icons.image,
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

  Widget _buildImageSection({
    required String title,
    required String description,
    required String imageType,
    required IconData icon,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppTheme.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
                     Consumer<ExhibitionFormState>(
             builder: (context, state, child) {
               final images = _getImagesByType(imageType);
               return Column(
                children: [
                  if (images.isNotEmpty) ...[
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final image = images[index];
                          final globalIndex = state.formData.galleryImages.indexOf(image);
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
                                    image['image_url'] as String,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: AppTheme.white.withOpacity(0.1),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                                                         errorBuilder: (context, error, stackTrace) {
                                       return Container(
                                        color: AppTheme.white.withOpacity(0.1),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_not_supported,
                                              color: AppTheme.white.withOpacity(0.6),
                                              size: 24,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Failed to load',
                                              style: TextStyle(
                                                color: AppTheme.white.withOpacity(0.6),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    onPressed: () async => await _removeImage(globalIndex),
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
                                     Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Main upload button
                       SizedBox(
                         width: double.infinity,
                         child: ElevatedButton.icon(
                           onPressed: _isUploading ? null : () => _pickAndUploadImages(imageType),
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
                           label: Text(_isUploading ? 'Uploading...' : 'Add $title'),
                         ),
                       ),
                       
                     ],
                   ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
