import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/responsive_card.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String applicationId;

  const PaymentDetailsScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  Map<String, dynamic>? _paymentData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paymentData = await _supabaseService.getPaymentDetails(widget.applicationId);
      
      if (mounted) {
        setState(() {
          _paymentData = paymentData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'credit_card':
        return 'Credit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'paypal':
        return 'PayPal';
      default:
        return 'Unknown';
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'credit_card':
        return Icons.credit_card;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'paypal':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundPeach,
        appBar: AppBar(
          title: Text(
            'Payment Details',
            style: TextStyle(
              color: AppTheme.primaryMaroon,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.primaryMaroon),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
          ),
        ),
      );
    }

    if (_error != null || _paymentData == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundPeach,
        appBar: AppBar(
          title: Text(
            'Payment Details',
            style: TextStyle(
              color: AppTheme.primaryMaroon,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.primaryMaroon),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading payment details',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Payment not found',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPaymentDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        title: Text(
          'Payment Details',
          style: TextStyle(
            color: AppTheme.primaryMaroon,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryMaroon),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: AppTheme.primaryMaroon),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentHeader(),
            const SizedBox(height: 20),
            _buildPaymentDetails(),
            const SizedBox(height: 20),
            _buildTransactionDetails(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHeader() {
    return ResponsiveCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
                                      decoration: BoxDecoration(
               color: _getStatusColor(_paymentData!['payment_status'] ?? 'pending').withOpacity(0.1),
               borderRadius: BorderRadius.circular(40),
               border: Border.all(
                 color: _getStatusColor(_paymentData!['payment_status'] ?? 'pending'),
                 width: 2,
               ),
             ),
             child: Icon(
               Icons.payment,
               color: _getStatusColor(_paymentData!['payment_status'] ?? 'pending'),
               size: 40,
             ),
           ),
           const SizedBox(height: 16),
           Text(
             '\$${(_paymentData!['payment_amount'] ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryMaroon,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
               color: _getStatusColor(_paymentData!['payment_status'] ?? 'pending').withOpacity(0.1),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(
                 color: _getStatusColor(_paymentData!['payment_status'] ?? 'pending'),
                 width: 1,
               ),
             ),
             child: Text(
               (_paymentData!['payment_status'] ?? 'pending').toUpperCase(),
               style: TextStyle(
                 fontSize: 12,
                 color: _getStatusColor(_paymentData!['payment_status'] ?? 'pending'),
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
           const SizedBox(height: 16),
                      Text(
             _paymentData!['exhibition']?['title'] ?? 'Unknown Exhibition',
             style: const TextStyle(
               fontSize: 18,
               fontWeight: FontWeight.w600,
               color: Colors.black,
             ),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 4),
           Text(
             _paymentData!['brand']?['company_name'] ?? 'Unknown Brand',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return ResponsiveCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryMaroon,
            ),
          ),
          const SizedBox(height: 16),
                     _buildDetailRow('Payment Method', _getPaymentMethodText(_paymentData!['payment_method'] ?? 'unknown'), _getPaymentMethodIcon(_paymentData!['payment_method'] ?? 'unknown')),
           const SizedBox(height: 12),
           _buildDetailRow('Payment Date', _paymentData!['payment_date'] ?? 'N/A', Icons.calendar_today),
           const SizedBox(height: 12),
           _buildDetailRow('Transaction ID', _paymentData!['transaction_id'] ?? 'N/A', Icons.receipt),
           const SizedBox(height: 12),
           _buildDetailRow('Amount', '\$${(_paymentData!['payment_amount'] ?? 0.0).toStringAsFixed(2)}', Icons.attach_money),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.borderLightGray,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryMaroon,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails() {
    return ResponsiveCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryMaroon,
            ),
          ),
          const SizedBox(height: 16),
                     _buildTransactionRow('Base Amount', '\$${((_paymentData!['payment_amount'] ?? 0.0) * 0.9).toStringAsFixed(2)}'),
           _buildTransactionRow('Service Fee (10%)', '\$${((_paymentData!['payment_amount'] ?? 0.0) * 0.1).toStringAsFixed(2)}'),
           const Divider(),
           _buildTransactionRow('Total Amount', '\$${(_paymentData!['payment_amount'] ?? 0.0).toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryMaroon : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement download receipt functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download receipt functionality coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download),
            label: const Text('Download Receipt'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement contact support functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact support functionality coming soon!')),
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
            icon: const Icon(Icons.support_agent),
            label: const Text('Contact Support'),
          ),
        ),
      ],
    );
  }
}
