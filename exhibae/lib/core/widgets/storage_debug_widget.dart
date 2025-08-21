import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class StorageDebugWidget extends StatefulWidget {
  const StorageDebugWidget({super.key});

  @override
  State<StorageDebugWidget> createState() => _StorageDebugWidgetState();
}

class _StorageDebugWidgetState extends State<StorageDebugWidget> {
  final _supabaseService = SupabaseService.instance;
  Map<String, dynamic>? _debugInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final debugInfo = await _supabaseService.debugProfileAvatarsStorage();
      setState(() {
        _debugInfo = debugInfo;
      });
    } catch (e) {
      setState(() {
        _debugInfo = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBucket() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _supabaseService.ensureProfileAvatarsBucket();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Profile-avatars bucket created successfully!' 
              : 'Failed to create profile-avatars bucket'),
            backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
          ),
        );
      }
      
      // Reload debug info
      await _loadDebugInfo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bucket: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Debug'),
        backgroundColor: AppTheme.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile-Avatars Storage Debug',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Create Bucket Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createBucket,
                icon: const Icon(Icons.storage),
                label: const Text('Create Profile-Avatars Bucket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _loadDebugInfo,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Debug Info'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Debug Info Display
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_debugInfo != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDebugSection('Bucket Status', {
                        'Bucket Exists': _debugInfo!['bucket_exists']?.toString() ?? 'Unknown',
                        'Current User': _debugInfo!['current_user']?.toString() ?? 'Unknown',
                      }),
                      
                      const SizedBox(height: 16),
                      
                      _buildDebugSection('All Available Buckets', {
                        'Buckets': _debugInfo!['all_buckets']?.join(', ') ?? 'None',
                      }),
                      
                      if (_debugInfo!['bucket_details'] != null) ...[
                        const SizedBox(height: 16),
                        _buildDebugSection('Bucket Details', _debugInfo!['bucket_details']),
                      ],
                      
                      if (_debugInfo!['error'] != null) ...[
                        const SizedBox(height: 16),
                        _buildDebugSection('Error', {
                          'Error': _debugInfo!['error']?.toString() ?? 'Unknown',
                        }),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection(String title, Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${entry.key}:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value?.toString() ?? 'null',
                    style: TextStyle(
                      color: entry.value == null ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
