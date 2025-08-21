import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/supabase_service.dart';

class StallDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> stall;

  const StallDetailsScreen({
    super.key,
    required this.stall,
  });

  @override
  State<StallDetailsScreen> createState() => _StallDetailsScreenState();
}

class _StallDetailsScreenState extends State<StallDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  Map<String, dynamic>? _paymentDetails;
  bool _isLoadingPaymentDetails = false;

  @override
  void initState() {
    super.initState();
    _loadOrganizerPaymentDetails();
  }

  Future<void> _loadOrganizerPaymentDetails() async {
    try {
      setState(() {
        _isLoadingPaymentDetails = true;
      });

      final exhibition = widget.stall['exhibition'] ?? {};
      final organizerId = exhibition['organiser_id'];
      
      if (organizerId != null) {
        final paymentDetails = await _supabaseService.getOrganizerPaymentDetails(organizerId);
        setState(() {
          _paymentDetails = paymentDetails;
          _isLoadingPaymentDetails = false;
        });
      } else {
        setState(() {
          _isLoadingPaymentDetails = false;
        });
      }
    } catch (e) {
      print('Error loading organizer payment details: $e');
      setState(() {
        _isLoadingPaymentDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exhibition = widget.stall['exhibition'] ?? {};
    final stallDetails = widget.stall['stall'] ?? {};
    final stallInstance = widget.stall['stall_instance'] ?? {};
    final status = widget.stall['status'] ?? 'pending';
    final message = widget.stall['message'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPeach,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: Text(
          'Stall Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              _getStatusDisplayText(status),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exhibition Info Card
            _buildInfoCard(
              'Exhibition Information',
              Icons.event,
              [
                exhibition['title'] ?? 'Unknown Exhibition',
                '${exhibition['city'] ?? ''}, ${exhibition['state'] ?? ''}',
                '${exhibition['start_date'] != null ? _formatDate(exhibition['start_date']) : ''} - ${exhibition['end_date'] != null ? _formatDate(exhibition['end_date']) : ''}',
              ],
            ),
            const SizedBox(height: 16),
            
            // Stall Info Card
            _buildInfoCard(
              'Stall Details',
              Icons.grid_on,
              [
                'Stall ${stallDetails['name'] ?? 'Unknown'}',
                'Dimensions: ${stallDetails['length'] ?? '0'} x ${stallDetails['width'] ?? '0'} ${stallDetails['unit']?['symbol'] ?? 'm'}',
                'Price: ₹${stallInstance['price'] ?? stallDetails['price'] ?? '0'}',
              ],
            ),
            
            if (message.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                'Message',
                Icons.message,
                [message],
              ),
            ],

            // Organizer Payment Details Card
            if (status.toLowerCase() == 'payment_pending') ...[
              const SizedBox(height: 16),
              _buildPaymentDetailsCard(),
            ],
            
            const SizedBox(height: 24),
            
            // Action Button
            _buildActionButton(status),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<String> details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryMaroon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.3),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  color: AppTheme.primaryMaroon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Organizer Payment Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingPaymentDetails)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_paymentDetails == null || 
                   (_paymentDetails!['bank_details'].isEmpty && _paymentDetails!['upi_details'].isEmpty))
            _buildNoPaymentDetailsMessage()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Details
                if (_paymentDetails!['bank_details'].isNotEmpty) ...[
                  _buildPaymentSectionHeader('Bank Transfer Details'),
                  const SizedBox(height: 8),
                  ..._paymentDetails!['bank_details'].map<Widget>((bankDetail) => 
                    _buildBankDetailItem(bankDetail)
                  ),
                  const SizedBox(height: 16),
                ],
                
                // UPI Details
                if (_paymentDetails!['upi_details'].isNotEmpty) ...[
                  _buildPaymentSectionHeader('UPI Payment Details'),
                  const SizedBox(height: 8),
                  ..._paymentDetails!['upi_details'].map<Widget>((upiDetail) => 
                    _buildUPIDetailItem(upiDetail)
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryMaroon,
      ),
    );
  }

  Widget _buildBankDetailItem(Map<String, dynamic> bankDetail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Bank Name', bankDetail['bank_name'] ?? 'N/A'),
          _buildDetailRow('Account Holder', bankDetail['account_holder_name'] ?? 'N/A'),
          _buildDetailRow('Account Number', bankDetail['account_number'] ?? 'N/A'),
          _buildDetailRow('IFSC Code', bankDetail['ifsc_code'] ?? 'N/A'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(bankDetail['account_number'] ?? ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Account Number'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(bankDetail['ifsc_code'] ?? ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy IFSC'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUPIDetailItem(Map<String, dynamic> upiDetail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('UPI ID', upiDetail['upi_id'] ?? 'N/A'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(upiDetail['upi_id'] ?? ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy UPI ID'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMediumGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPaymentDetailsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.payment_outlined,
            size: 32,
            color: AppTheme.textMediumGray,
          ),
          const SizedBox(height: 8),
          Text(
            'Payment details not available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMediumGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The organizer has not provided payment information yet. Please contact the organizer or wait for them to add payment details.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.warningOrange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.warningOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment button will be enabled once organizer adds payment details',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.warningOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty || text == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No data to copy'),
          backgroundColor: AppTheme.warningOrange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $text'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      print('Error copying to clipboard: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy: $error'),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  Widget _buildActionButton(String status) {
    switch (status.toLowerCase()) {
      case 'payment_pending':
        // Check if payment details are available
        final hasPaymentDetails = _paymentDetails != null && 
          (_paymentDetails!['bank_details'].isNotEmpty || _paymentDetails!['upi_details'].isNotEmpty);
        
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: hasPaymentDetails ? () => _navigateToPaymentSubmission() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPaymentDetails ? AppTheme.primaryMaroon : AppTheme.textMediumGray,
              foregroundColor: AppTheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              hasPaymentDetails ? 'Make Payment' : 'Payment Details Required',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      case 'pending':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.warningOrange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Application Pending',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.warningOrange,
              ),
            ),
          ),
        );
      case 'approved':
      case 'booked':
      case 'completed':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Application ${status.toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        );
      case 'rejected':
      case 'cancelled':
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.errorRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Application ${status.toUpperCase()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorRed,
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _navigateToPaymentSubmission() {
    Navigator.pushNamed(
      context,
      AppRouter.paymentSubmission,
      arguments: {'application': widget.stall},
    );
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue;
      case 'booked':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return AppTheme.errorRed;
      case 'pending':
        return Colors.orange;
      case 'payment_pending':
        return AppTheme.primaryMaroon;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.white;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'COMPLETED';
      case 'booked':
        return 'BOOKED';
      case 'completed':
        return 'COMPLETED';
      case 'rejected':
        return 'REJECTED';
      case 'pending':
        return 'PENDING';
      case 'payment_pending':
        return 'PAYMENT PENDING';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }
}
