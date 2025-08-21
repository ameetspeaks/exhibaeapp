import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _revenueData = {};
  String _selectedPeriod = 'month'; // month, quarter, year
  Map<String, dynamic>? _selectedTransaction;

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get revenue data for the organizer
      final revenueData = await _getRevenueData(userId);

      if (mounted) {
        setState(() {
          _revenueData = revenueData;
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

  Future<Map<String, dynamic>> _getRevenueData(String userId) async {
    // Get all exhibitions by this organizer
    final exhibitions = await _supabaseService.client
        .from('exhibitions')
        .select('id, title, status')
        .eq('organiser_id', userId);

    double totalRevenue = 0.0;
    double pendingRevenue = 0.0;
    double completedRevenue = 0.0;
    int totalStalls = 0;
    int bookedStalls = 0;
    int pendingStalls = 0;

    // Calculate revenue from stall applications
    for (final exhibition in exhibitions) {
      final stallApplications = await _supabaseService.client
          .from('stall_applications')
          .select('''
            id, status, created_at,
            stall:stalls(id, price),
            brand:profiles!stall_applications_brand_id_fkey(id, full_name, email),
            exhibition:exhibitions!stall_applications_exhibition_id_fkey(id, title)
          ''')
          .eq('exhibition_id', exhibition['id']);

      for (final application in stallApplications) {
        final price = (application['stall']?['price'] as num?)?.toDouble() ?? 0.0;
        final status = application['status'] as String? ?? 'pending';

        totalStalls++;
        
        switch (status) {
          case 'booked':
            totalRevenue += price;
            completedRevenue += price;
            bookedStalls++;
            break;
          case 'payment_review':
            totalRevenue += price;
            completedRevenue += price;
            bookedStalls++;
            break;
          case 'payment_pending':
            pendingRevenue += price;
            pendingStalls++;
            break;
          case 'pending':
            pendingStalls++;
            break;
          default:
            pendingStalls++;
            break;
        }
      }
    }

    // Build IN filter parameters
    final List<String> exhibitionIds =
        exhibitions.map<String>((e) => e['id'] as String).toList();
    final String exhibitionIn = '(${exhibitionIds.join(',')})';
    const String statusIn = '(payment_pending,payment_review,booked)';

    // Get recent applications with payment status from stall_applications table
    final recentApplications = await _supabaseService.client
        .from('stall_applications')
        .select('''
          id, status, created_at, message,
          brand:profiles!stall_applications_brand_id_fkey(id, full_name, email),
          exhibition:exhibitions!stall_applications_exhibition_id_fkey(id, title),
          stall:stalls(id, price)
        ''')
        .filter('exhibition_id', 'in', exhibitionIn)
        .filter('status', 'in', statusIn)
        .order('created_at', ascending: false)
        .limit(10);

    // Format applications for display
    final formattedTransactions = recentApplications.map((application) {
      final brand = application['brand'] as Map<String, dynamic>?;
      final exhibition = application['exhibition'] as Map<String, dynamic>?;
      final stall = application['stall'] as Map<String, dynamic>?;
      final price = (stall?['price'] as num?)?.toDouble() ?? 0.0;
      
      return {
        'id': application['id'],
        'brand': brand?['full_name'] ?? 'Unknown Brand',
        'exhibition': exhibition?['title'] ?? 'Unknown Exhibition',
        'amount': '₹${price.toStringAsFixed(0)}',
        'status': application['status'] ?? 'pending',
        'date': application['created_at'] ?? '',
        'payment_method': 'Stall Application',
        'transaction_id': application['id'],
        'message': application['message'] ?? '',
      };
    }).toList();

    return {
      'totalRevenue': totalRevenue,
      'pendingRevenue': pendingRevenue,
      'completedRevenue': completedRevenue,
      'totalStalls': totalStalls,
      'bookedStalls': bookedStalls,
      'pendingStalls': pendingStalls,
      'commission': totalRevenue * 0.10, // 10% commission
      'netRevenue': totalRevenue * 0.90, // 90% after commission
      'recentTransactions': formattedTransactions,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPeach,
        elevation: 0,
        title: const Text(
          'Revenue Analytics',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadRevenueData,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryMaroon.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.refresh,
                color: AppTheme.primaryMaroon,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(
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
                        'Error loading revenue data',
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
                        onPressed: _loadRevenueData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMaroon,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             // Period Selector
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           color: AppTheme.white,
                           borderRadius: BorderRadius.circular(16),
                           boxShadow: [
                             BoxShadow(
                               color: AppTheme.black.withOpacity(0.08),
                               blurRadius: 15,
                               offset: const Offset(0, 4),
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
                                     Icons.filter_list,
                                     color: AppTheme.primaryMaroon,
                                     size: 20,
                                   ),
                                 ),
                                 const SizedBox(width: 12),
                                 const Text(
                                   'Filter by Period',
                                   style: TextStyle(
                                     fontSize: 18,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.black,
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 16),
                             Wrap(
                               spacing: 12,
                               runSpacing: 12,
                               alignment: WrapAlignment.start,
                               children: [
                                 _buildPeriodChip('This Month', 'month'),
                                 _buildPeriodChip('This Quarter', 'quarter'),
                                 _buildPeriodChip('This Year', 'year'),
                               ],
                             ),
                           ],
                         ),
                       ),
                      const SizedBox(height: 20),

                      // Revenue Overview Cards
                      _buildRevenueOverview(),
                      const SizedBox(height: 20),

                      // Detailed Analytics
                      _buildDetailedAnalytics(),
                      const SizedBox(height: 20),

                      // Recent Transactions
                      _buildRecentTransactions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
          _loadRevenueData();
        },
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryMaroon : AppTheme.backgroundPeach,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? AppTheme.primaryMaroon : AppTheme.borderLightGray,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryMaroon.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
              if (isSelected) const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Use a single column layout for very small screens
            if (constraints.maxWidth < 400) {
              return Column(
                children: [
                  _buildRevenueCard(
                    'Total Revenue',
                    '₹${_revenueData['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildRevenueCard(
                    'Net Revenue',
                    '₹${_revenueData['netRevenue']?.toStringAsFixed(0) ?? '0'}',
                    Icons.account_balance_wallet,
                    AppTheme.primaryMaroon,
                  ),
                  const SizedBox(height: 12),
                  _buildRevenueCard(
                    'Completed',
                    '₹${_revenueData['completedRevenue']?.toStringAsFixed(0) ?? '0'}',
                    Icons.check_circle,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildRevenueCard(
                    'Pending',
                    '₹${_revenueData['pendingRevenue']?.toStringAsFixed(0) ?? '0'}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ],
              );
            }
            
            // Use 2x2 grid for larger screens
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildRevenueCard(
                        'Total Revenue',
                        '₹${_revenueData['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRevenueCard(
                        'Net Revenue',
                        '₹${_revenueData['netRevenue']?.toStringAsFixed(0) ?? '0'}',
                        Icons.account_balance_wallet,
                        AppTheme.primaryMaroon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildRevenueCard(
                        'Completed',
                        '₹${_revenueData['completedRevenue']?.toStringAsFixed(0) ?? '0'}',
                        Icons.check_circle,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRevenueCard(
                        'Pending',
                        '₹${_revenueData['pendingRevenue']?.toStringAsFixed(0) ?? '0'}',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRevenueCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
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
          const Text(
            'Stall Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsRow('Total Stalls', '${_revenueData['totalStalls'] ?? 0}'),
          _buildAnalyticsRow('Booked Stalls', '${_revenueData['bookedStalls'] ?? 0}'),
          _buildAnalyticsRow('Pending Stalls', '${_revenueData['pendingStalls'] ?? 0}'),
          const Divider(),
          _buildAnalyticsRow(
            'Commission (10%)',
            '₹${_revenueData['commission']?.toStringAsFixed(0) ?? '0'}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? AppTheme.primaryMaroon : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    // Get recent transactions from payment_transactions table
    final transactions = _revenueData['recentTransactions'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full transactions list
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppTheme.backgroundPeach,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderLightGray,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: AppTheme.primaryMaroon.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent transactions',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            ...transactions.map((transaction) => _buildTransactionCard(
                  transaction,
                  isSelected: identical(_selectedTransaction, transaction),
                  onTap: () {
                    setState(() {
                      _selectedTransaction = transaction;
                    });
                    _showTransactionDetailsPopup(transaction);
                  },
                )),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final status = transaction['status'] as String;
    Color getStatusColor() {
      switch (status) {
        case 'completed':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.white : AppTheme.backgroundPeach.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryMaroon : AppTheme.borderLightGray,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryMaroon.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
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
                  Icons.receipt,
                  color: getStatusColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['brand'] ?? 'Unknown Brand',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction['exhibition'] ?? 'Unknown Exhibition',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction['date'] ?? ''),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction['amount'] ?? '₹0',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.visibility, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetailsPopup(Map<String, dynamic> transaction) {
    final status = (transaction['status'] as String?) ?? 'pending';
    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transaction Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedTransaction = null;
                        });
                      },
                      icon: const Icon(Icons.close, size: 24, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                                 // Details Grid
                 _buildPopupDetailItem('Brand', transaction['brand'] ?? '-', Icons.business),
                 const SizedBox(height: 16),
                 _buildPopupDetailItem('Exhibition', transaction['exhibition'] ?? '-', Icons.event),
                 const SizedBox(height: 16),
                 _buildPopupDetailItem('Amount', transaction['amount'] ?? '₹0', Icons.attach_money, color: statusColor),
                 const SizedBox(height: 16),
                 _buildPopupDetailItem('Payment Method', transaction['payment_method'] ?? '-', Icons.payment),
                 const SizedBox(height: 16),
                 _buildPopupDetailItem('Transaction ID', transaction['transaction_id'] ?? '-', Icons.receipt_long),
                 const SizedBox(height: 16),
                 _buildPopupDetailItem('Date', _formatDate(transaction['date'] ?? ''), Icons.calendar_today),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupDetailItem(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPeach,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryMaroon,
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
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
