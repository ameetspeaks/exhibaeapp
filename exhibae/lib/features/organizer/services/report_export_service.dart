import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  static Future<void> exportExhibitionsReport(List<Map<String, dynamic>> exhibitions) async {
    try {
      // Prepare CSV data
      final List<List<dynamic>> csvData = [
        // Header row
        [
          'Title',
          'Status',
          'Start Date',
          'End Date',
          'Location',
          'City',
          'State',
          'Country',
          'Applications',
          'Stalls',
          'Created At',
        ],
        // Data rows
        ...exhibitions.map((exhibition) => [
          exhibition['title'] ?? '',
          exhibition['status'] ?? '',
          exhibition['start_date'] ?? '',
          exhibition['end_date'] ?? '',
          exhibition['location'] ?? '',
          exhibition['city'] ?? '',
          exhibition['state'] ?? '',
          exhibition['country'] ?? '',
          exhibition['application_count'] ?? 0,
          exhibition['stall_count'] ?? 0,
          exhibition['created_at'] ?? '',
        ]),
      ];

      await _exportToCsv(csvData, 'exhibitions_report');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> exportApplicationsReport(List<Map<String, dynamic>> applications) async {
    try {
      // Prepare CSV data
      final List<List<dynamic>> csvData = [
        // Header row
        [
          'Brand',
          'Exhibition',
          'Status',
          'Stall Name',
          'Stall Size',
          'Price',
          'Created At',
        ],
        // Data rows
        ...applications.map((application) {
          final brand = application['brand'] ?? {};
          final exhibition = application['exhibition'] ?? {};
          final stall = application['stall'] ?? {};
          final unit = stall['unit'] ?? {};
          
          return [
            brand['company_name'] ?? '',
            exhibition['title'] ?? '',
            application['status'] ?? '',
            stall['name'] ?? '',
            '${stall['length'] ?? ''}x${stall['width'] ?? ''}${unit['symbol'] ?? ''}',
            stall['price'] ?? '',
            application['created_at'] ?? '',
          ];
        }),
      ];

      await _exportToCsv(csvData, 'applications_report');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _exportToCsv(List<List<dynamic>> rows, String fileName) async {
    try {
      // Convert to CSV
      final csv = const ListToCsvConverter().convert(rows);
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$fileName.csv';
      
      // Write to file
      final file = File(path);
      await file.writeAsString(csv);
      
      // Share file
      await Share.shareXFiles(
        [XFile(path)],
        subject: fileName,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> exportReportAsJson(Map<String, dynamic> data, String fileName) async {
    try {
      // Convert to JSON
      final jsonString = jsonEncode(data);
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$fileName.json';
      
      // Write to file
      final file = File(path);
      await file.writeAsString(jsonString);
      
      // Share file
      await Share.shareXFiles(
        [XFile(path)],
        subject: fileName,
      );
    } catch (e) {
      rethrow;
    }
  }
}
