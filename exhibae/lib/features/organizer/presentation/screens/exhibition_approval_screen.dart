import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';

class ExhibitionApprovalScreen extends StatefulWidget {
  const ExhibitionApprovalScreen({super.key});

  @override
  State<ExhibitionApprovalScreen> createState() => _ExhibitionApprovalScreenState();
}

class _ExhibitionApprovalScreenState extends State<ExhibitionApprovalScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _pendingExhibitions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingExhibitions();
  }

  Future<void> _loadPendingExhibitions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _supabaseService.client
          .from('exhibitions')
          .select('''
            *,
            profiles!exhibitions_organiser_id_fkey (
              full_name,
              email
            )
          ''')
          .eq('status', 'pending_approval')
          .order('submitted_for_approval_at', ascending: true);

      setState(() {
        _pendingExhibitions = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveExhibition(String exhibitionId) async {
    try {
      final result = await _supabaseService.client
          .rpc('approve_exhibition', params: {
            'exhibition_id': exhibitionId,
            'is_approved': true,
          });

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exhibition approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingExhibitions(); // Reload the list
      } else {
        throw Exception('Failed to approve exhibition');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve exhibition: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectExhibition(String exhibitionId, String reason) async {
    try {
      final result = await _supabaseService.client
          .rpc('approve_exhibition', params: {
            'exhibition_id': exhibitionId,
            'is_approved': false,
            'rejection_reason': reason,
          });

      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exhibition rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingExhibitions(); // Reload the list
      } else {
        throw Exception('Failed to reject exhibition');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject exhibition: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(String exhibitionId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Exhibition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _rejectExhibition(exhibitionId, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gradientBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Exhibition Approvals',
          style: TextStyle(color: AppTheme.white),
        ),
        iconTheme: const IconThemeData(color: AppTheme.white),
        actions: [
          IconButton(
            onPressed: _loadPendingExhibitions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: AppTheme.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingExhibitions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingExhibitions.isEmpty
                  ? const Center(
                      child: Text(
                        'No exhibitions pending approval',
                        style: TextStyle(color: AppTheme.white, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingExhibitions.length,
                      itemBuilder: (context, index) {
                        final exhibition = _pendingExhibitions[index];
                        final organiser = exhibition['profiles'] as Map<String, dynamic>?;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.white.withOpacity(0.2),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        exhibition['title'] ?? 'Untitled Exhibition',
                                        style: const TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.5),
                                        ),
                                      ),
                                      child: const Text(
                                        'Pending Approval',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  exhibition['description'] ?? 'No description',
                                  style: TextStyle(
                                    color: AppTheme.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                if (organiser != null) ...[
                                  Text(
                                    'Organizer: ${organiser['full_name'] ?? organiser['email'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: AppTheme.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  'Submitted: ${_formatDate(DateTime.parse(exhibition['submitted_for_approval_at']))}',
                                  style: TextStyle(
                                    color: AppTheme.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _approveExhibition(exhibition['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: AppTheme.white,
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _showRejectDialog(exhibition['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: AppTheme.white,
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
