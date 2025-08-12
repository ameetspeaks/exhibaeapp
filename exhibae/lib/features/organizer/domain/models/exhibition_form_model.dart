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
  String? floorPlan;
  List<String> images = [];
  List<String> amenities = [];
  bool isPublished = false;
  double? latitude;
  double? longitude;
  int? expectedVisitors;
  double? stallStartingPrice;
  String? status;
  Map<String, dynamic>? additionalInfo;

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
    floorPlan = json['floor_plan'];
    images = List<String>.from(json['images'] ?? []);
    amenities = List<String>.from(json['amenities'] ?? []);
    isPublished = json['is_published'] ?? false;
    latitude = json['latitude']?.toDouble();
    longitude = json['longitude']?.toDouble();
    expectedVisitors = json['expected_visitors'];
    stallStartingPrice = json['stall_starting_price']?.toDouble();
    status = json['status'];
    additionalInfo = json['additional_info'];
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
      if (floorPlan != null) 'floor_plan': floorPlan,
      'images': images,
      'amenities': amenities,
      'is_published': isPublished,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (expectedVisitors != null) 'expected_visitors': expectedVisitors,
      if (stallStartingPrice != null) 'stall_starting_price': stallStartingPrice,
      if (status != null) 'status': status,
      if (additionalInfo != null) 'additional_info': additionalInfo,
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
