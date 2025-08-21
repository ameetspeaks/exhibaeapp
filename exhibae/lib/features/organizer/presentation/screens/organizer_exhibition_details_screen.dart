import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class OrganizerExhibitionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> exhibition;
  
  const OrganizerExhibitionDetailsScreen({
    super.key,
    required this.exhibition,
  });

  @override
  State<OrganizerExhibitionDetailsScreen> createState() => _OrganizerExhibitionDetailsScreenState();
}

class _OrganizerExhibitionDetailsScreenState extends State<OrganizerExhibitionDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final exhibition = widget.exhibition;
    final status = exhibition['status'] ?? 'draft';
    
    Color getStatusColor() {
      switch (status) {
        case 'published':
          return const Color(0xFF22C55E); // Green for "live/active"
        case 'live':
          return const Color(0xFF22C55E); // Green for "live/active"
        case 'completed':
          return const Color(0xFF3B82F6); // Blue for "done/closed properly"
        case 'draft':
          return const Color(0xFFFACC15); // Amber/Yellow for "work in progress"
        case 'cancelled':
          return const Color(0xFFEF4444); // Red for "stopped/terminated"
        default:
          return Colors.grey;
      }
    }

    String getStatusDisplayText() {
      switch (status) {
        case 'draft':
          return 'PENDING FOR APPROVAL';
        default:
          return status.toUpperCase();
      }
    }

    Color getCardBackgroundColor() {
      switch (status) {
        case 'published':
          return const Color(0xFFF0FDF4); // Light green background for published status
        case 'draft':
          return const Color(0xFFFEFCE8); // Light amber background for draft status
        case 'completed':
          return const Color(0xFFEFF6FF); // Light blue background for completed status
        case 'cancelled':
          return const Color(0xFFFEF2F2); // Light red background for cancelled status
        default:
          return AppTheme.white;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPeach,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Exhibition Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_canEditExhibition(exhibition))
            IconButton(
              onPressed: _isLoading ? null : _editExhibition,
              icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                    ),
                  )
                : Icon(Icons.edit, color: AppTheme.primaryMaroon),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exhibition Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: getCardBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: status == 'draft' ? const Color(0xFFFACC15) : AppTheme.borderLightGray,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: getStatusColor(),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exhibition['title'] ?? 'Untitled Exhibition',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: getStatusColor(),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          getStatusDisplayText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  if (exhibition['description'] != null && exhibition['description'].toString().isNotEmpty)
                    Text(
                      exhibition['description'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Details Section
            _buildDetailsSection(exhibition),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            if (_canEditExhibition(exhibition))
              _buildActionButtons(exhibition)
            else
              _buildReadOnlyMessage(status),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(Map<String, dynamic> exhibition) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exhibition Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryMaroon,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow('Location', _getLocation(exhibition)),
          _buildDetailRow('Start Date', _formatDate(exhibition['start_date'])),
          _buildDetailRow('End Date', _formatDate(exhibition['end_date'])),
          _buildDetailRow('Category', _getCategoryName(exhibition['category'])),
          _buildDetailRow('Venue Type', _getVenueTypeName(exhibition['venue_type'])),
          _buildDetailRow('Event Type', _getEventTypeName(exhibition['event_type'])),
          _buildDetailRow('Application Deadline', _formatDate(exhibition['application_deadline'])),
          _buildDetailRow('Start Time', _formatTime(exhibition['start_time'])),
          _buildDetailRow('End Time', _formatTime(exhibition['end_time'])),
          _buildDetailRow('Created', _formatDateTime(exhibition['created_at'])),
          _buildDetailRow('Last Updated', _formatDateTime(exhibition['updated_at'])),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryMaroon,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> exhibition) {
    return Column(
      children: [
        // Edit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _editExhibition,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isLoading 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.edit),
            label: Text(
              _isLoading ? 'Loading...' : 'Edit Exhibition',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Applications Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/applications',
                arguments: {
                  'exhibitionId': exhibition['id'],
                  'exhibitionTitle': exhibition['title'] ?? 'Unknown Exhibition',
                },
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryMaroon,
              side: BorderSide(color: AppTheme.primaryMaroon),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.assignment),
            label: const Text(
              'View Applications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyMessage(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.primaryMaroon,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This exhibition is $status and cannot be edited.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryMaroon,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editExhibition() {
    setState(() {
      _isLoading = true;
    });

    // Navigate to exhibition form with existing data
    Navigator.pushNamed(
      context,
      '/exhibition-form',
      arguments: {
        'exhibition': widget.exhibition,
      },
    ).then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  bool _canEditExhibition(Map<String, dynamic> exhibition) {
    final status = exhibition['status']?.toString().toLowerCase() ?? 'draft';
    // Only allow editing for draft, published, and live statuses
    return status == 'draft' || status == 'published' || status == 'live';
  }

  // Helper methods for formatting data
  String _getLocation(Map<String, dynamic> exhibition) {
    final address = exhibition['address'];
    final city = exhibition['city'];
    final state = exhibition['state'];
    final country = exhibition['country'];
    
    final parts = [address, city, state, country].where((part) => part != null && part.toString().isNotEmpty).toList();
    return parts.isEmpty ? 'Location not specified' : parts.join(', ');
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Not set';
    try {
      if (dateValue is String) {
        final date = DateTime.parse(dateValue);
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Invalid date';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatTime(dynamic timeValue) {
    if (timeValue == null) return 'Not set';
    try {
      if (timeValue is String) {
        return timeValue;
      }
      return 'Invalid time';
    } catch (e) {
      return 'Invalid time';
    }
  }

  String _formatDateTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) return 'Not set';
    try {
      if (dateTimeValue is String) {
        final dateTime = DateTime.parse(dateTimeValue);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return 'Invalid date/time';
    } catch (e) {
      return 'Invalid date/time';
    }
  }

  String _getCategoryName(dynamic categoryValue) {
    if (categoryValue == null) return 'Not specified';
    
    if (categoryValue is Map) {
      return categoryValue['name']?.toString() ?? 'Unknown Category';
    }
    
    if (categoryValue is String) {
      return categoryValue.split('_').map((word) => 
        word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : ''
      ).join(' ');
    }
    
    return 'Unknown Category';
  }

  String _getVenueTypeName(dynamic venueTypeValue) {
    if (venueTypeValue == null) return 'Not specified';
    
    if (venueTypeValue is Map) {
      return venueTypeValue['name']?.toString() ?? 'Unknown Venue Type';
    }
    
    if (venueTypeValue is String) {
      return venueTypeValue.split('_').map((word) => 
        word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : ''
      ).join(' ');
    }
    
    return 'Unknown Venue Type';
  }

  String _getEventTypeName(dynamic eventTypeValue) {
    if (eventTypeValue == null) return 'Not specified';
    
    if (eventTypeValue is Map) {
      return eventTypeValue['name']?.toString() ?? 'Unknown Event Type';
    }
    
    if (eventTypeValue is String) {
      return eventTypeValue.split('_').map((word) => 
        word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : ''
      ).join(' ');
    }
    
    return 'Unknown Event Type';
  }
}
