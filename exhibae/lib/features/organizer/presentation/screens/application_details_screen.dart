import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> application;

  const ApplicationDetailsScreen({
    super.key,
    required this.application,
  });

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = false;
  String? _error;

  Future<void> _handleApproval() async {
    await _updateApplicationStatus('approved');
  }

  Future<void> _handleRejection() async {
    await _updateApplicationStatus('rejected');
  }

  Future<void> _updateApplicationStatus(String status) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await _supabaseService.client
          .from('stall_applications')
          .update({'status': status})
          .eq('id', widget.application['id']);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.application['brand'] ?? {};
    final exhibition = widget.application['exhibition'] ?? {};
    final stall = widget.application['stall'] ?? {};
    final status = widget.application['status'] ?? 'pending';
    final stallInstance = widget.application['stall_instance'] ?? {};
    
    Color getStatusColor() {
      switch (status) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return AppTheme.errorRed;
        default:
          return AppTheme.white;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Application Details',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getStatusColor().withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          status == 'approved'
                              ? Icons.check_circle
                              : status == 'rejected'
                                  ? Icons.cancel
                                  : Icons.pending,
                          color: getStatusColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Application Status',
                              style: TextStyle(
                                fontSize: 14,
                                color: getStatusColor().withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Brand Information
                _buildSection(
                  'Brand Information',
                  Icons.business,
                  [
                    _buildInfoItem('Company Name', brand['company_name'] ?? 'Not specified'),
                    _buildInfoItem('Contact Person', brand['full_name'] ?? 'Not specified'),
                    _buildInfoItem('Email', brand['email'] ?? 'Not specified'),
                    _buildInfoItem('Phone', brand['phone'] ?? 'Not specified'),
                  ],
                ),
                const SizedBox(height: 24),

                // Exhibition Information
                _buildSection(
                  'Exhibition Information',
                  Icons.event,
                  [
                    _buildInfoItem('Exhibition', exhibition['title'] ?? 'Not specified'),
                    _buildInfoItem(
                      'Dates',
                      exhibition['start_date'] != null && exhibition['end_date'] != null
                          ? '${_formatDate(DateTime.parse(exhibition['start_date']))} - ${_formatDate(DateTime.parse(exhibition['end_date']))}'
                          : 'Not specified',
                    ),
                    _buildInfoItem('Location', exhibition['location'] ?? 'Not specified'),
                  ],
                ),
                const SizedBox(height: 24),

                // Stall Information
                _buildSection(
                  'Stall Information',
                  Icons.grid_on,
                  [
                    _buildInfoItem('Stall Name', stall['name'] ?? 'Not specified'),
                    _buildInfoItem(
                      'Dimensions',
                      '${stall['length']}x${stall['width']}${stall['unit']?['symbol'] ?? 'm'}',
                    ),
                    _buildInfoItem('Price', '₹${stall['price'] ?? '0'}'),
                    if (stallInstance['instance_number'] != null)
                      _buildInfoItem('Stall Number', '#${stallInstance['instance_number']}'),
                  ],
                ),
                const SizedBox(height: 24),

                // Application Details
                _buildSection(
                  'Application Details',
                  Icons.description,
                  [
                    _buildInfoItem(
                      'Submitted On',
                      _formatDate(DateTime.parse(widget.application['created_at'])),
                    ),
                    if (widget.application['message'] != null)
                      _buildInfoItem('Message', widget.application['message']),
                  ],
                ),
                
                // Space for bottom buttons
                if (status == 'pending')
                  const SizedBox(height: 100),
              ],
            ),
          ),
          
          if (status == 'pending')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
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
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleRejection,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: BorderSide(
                            color: AppTheme.errorRed.withOpacity(0.5),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.errorRed),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleApproval,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: status == 'pending' ? 100 : 16,
              child: Container(
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
                        'Error: $_error',
                        style: const TextStyle(
                          color: AppTheme.errorRed,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
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
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
