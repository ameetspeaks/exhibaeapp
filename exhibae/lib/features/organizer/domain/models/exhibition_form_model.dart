import 'package:flutter/material.dart';

class ExhibitionFormModel {
  String? id;
  String title = '';
  String description = '';
  String? categoryId;
  String? venueTypeId;
  String? eventTypeId;
  String? measurementUnitId;
  DateTime? startDate;
  DateTime? endDate;
  String address = '';
  String city = '';
  String state = '';
  String country = '';
  String? postalCode;
  double? latitude;
  double? longitude;
  String? organiserId;
  String status = 'draft';
  DateTime? approvedAt;
  String? approvedBy;
  String? rejectionReason;
  DateTime? submittedForApprovalAt;
  Map<String, dynamic>? layoutConfig;
  DateTime? applicationDeadline;
  TimeOfDay startTime = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
  
  // Gallery Images (from gallery_images table)
  List<Map<String, dynamic>> galleryImages = [];
  
  // Stalls (will be created in stalls table)
  List<Map<String, dynamic>> stalls = [];
  
  // Amenities (will be stored in stall_amenities table)
  List<String> selectedAmenities = [];
  
  // Media properties
  List<String> images = [];
  String? floorPlan;
  
  // Pricing properties
  double? stallStartingPrice;

  ExhibitionFormModel();

  ExhibitionFormModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'] ?? '';
    description = json['description'] ?? '';
    categoryId = json['category_id'];
    venueTypeId = json['venue_type_id'];
    eventTypeId = json['event_type_id'];
    measurementUnitId = json['measurement_unit_id'];
    startDate = json['start_date'] != null ? DateTime.parse(json['start_date']) : null;
    endDate = json['end_date'] != null ? DateTime.parse(json['end_date']) : null;
    address = json['address'] ?? '';
    city = json['city'] ?? '';
    state = json['state'] ?? '';
    country = json['country'] ?? '';
    postalCode = json['postal_code'];
    latitude = json['latitude']?.toDouble();
    longitude = json['longitude']?.toDouble();
    organiserId = json['organiser_id'];
    status = json['status'] ?? 'draft';
    approvedAt = json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null;
    approvedBy = json['approved_by'];
    rejectionReason = json['rejection_reason'];
    submittedForApprovalAt = json['submitted_for_approval_at'] != null ? DateTime.parse(json['submitted_for_approval_at']) : null;
    layoutConfig = json['layout_config'];
    applicationDeadline = json['application_deadline'] != null ? DateTime.parse(json['application_deadline']) : null;
    
    // Parse time strings to TimeOfDay
    if (json['start_time'] != null) {
      final timeParts = json['start_time'].split(':');
      startTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }
    if (json['end_time'] != null) {
      final timeParts = json['end_time'].split(':');
      endTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }
    
    galleryImages = List<Map<String, dynamic>>.from(json['gallery_images'] ?? []);
    stalls = List<Map<String, dynamic>>.from(json['stalls'] ?? []);
    selectedAmenities = List<String>.from(json['selected_amenities'] ?? []);
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (venueTypeId != null) 'venue_type_id': venueTypeId,
      if (eventTypeId != null) 'event_type_id': eventTypeId,
      if (measurementUnitId != null) 'measurement_unit_id': measurementUnitId,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      if (postalCode != null) 'postal_code': postalCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (organiserId != null) 'organiser_id': organiserId,
      'status': status,
      if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
      if (approvedBy != null) 'approved_by': approvedBy,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (submittedForApprovalAt != null) 'submitted_for_approval_at': submittedForApprovalAt!.toIso8601String(),
      if (layoutConfig != null) 'layout_config': layoutConfig,
      if (applicationDeadline != null) 'application_deadline': applicationDeadline!.toIso8601String(),
      'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'gallery_images': galleryImages,
      'stalls': stalls,
      'selected_amenities': selectedAmenities,
    };
  }

  bool get isValid {
    return title.isNotEmpty &&
           description.isNotEmpty &&
           startDate != null &&
           endDate != null &&
           address.isNotEmpty &&
           city.isNotEmpty &&
           state.isNotEmpty &&
           country.isNotEmpty;
  }
}
