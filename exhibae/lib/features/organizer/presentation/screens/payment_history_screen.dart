import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/responsive_card.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final payments = await _supabaseService.getPaymentHistory(organizerId: currentUser.id);

      if (mounted) {
        setState(() {
          _payments = payments;
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

  List<Map<String, dynamic>> get _filteredPayments {
    if (_selectedFilter == 'all') return _payments;
    return _payments.where((payment) => payment['payment_status'] == _selectedFilter).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        title: Text(
          'Payment History',
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading payment history',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPaymentHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMaroon,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPaymentHistory,
                  color: AppTheme.primaryMaroon,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterSection(),
                        const SizedBox(height: 20),
                        _buildPaymentList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterSection() {
    return ResponsiveCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Payments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryMaroon,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('all', 'All'),
              _buildFilterChip('completed', 'Completed'),
              _buildFilterChip('pending', 'Pending'),
              _buildFilterChip('failed', 'Failed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryMaroon.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryMaroon,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryMaroon : Colors.black,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryMaroon : AppTheme.borderLightGray,
      ),
    );
  }

  Widget _buildPaymentList() {
    if (_filteredPayments.isEmpty) {
      return ResponsiveCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.payment_outlined,
              size: 48,
              color: AppTheme.primaryMaroon.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No payments found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Payment history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredPayments.map((payment) => _buildPaymentCard(payment)).toList(),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return ResponsiveCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: InkWell(
                 onTap: () {
           Navigator.pushNamed(
             context,
             '/payment-details',
             arguments: {'applicationId': payment['id']},
           );
         },
        borderRadius: BorderRadius.circular(12),
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
                    border: Border.all(
                      color: AppTheme.borderLightGray,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: AppTheme.primaryMaroon,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             Text(
                         payment['exhibition']?['title'] ?? 'Unknown Exhibition',
                         style: const TextStyle(
                           fontSize: 14,
                           fontWeight: FontWeight.w600,
                           color: Colors.black,
                         ),
                       ),
                       const SizedBox(height: 2),
                       Text(
                         payment['brand']?['company_name'] ?? 'Unknown Brand',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                                         Text(
                       '\$${(payment['payment_amount'] ?? 0.0).toStringAsFixed(2)}',
                       style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: AppTheme.primaryMaroon,
                       ),
                     ),
                     const SizedBox(height: 4),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(
                         color: _getStatusColor(payment['payment_status'] ?? 'pending').withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(
                           color: _getStatusColor(payment['payment_status'] ?? 'pending'),
                           width: 1,
                         ),
                       ),
                       child: Text(
                         (payment['payment_status'] ?? 'pending').toUpperCase(),
                         style: TextStyle(
                           fontSize: 10,
                           color: _getStatusColor(payment['payment_status'] ?? 'pending'),
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                                 Text(
                   'Date: ${payment['payment_date'] ?? 'N/A'}',
                   style: TextStyle(
                     fontSize: 12,
                     color: Colors.black.withOpacity(0.6),
                   ),
                 ),
                 Text(
                   _getPaymentMethodText(payment['payment_method'] ?? 'unknown'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
