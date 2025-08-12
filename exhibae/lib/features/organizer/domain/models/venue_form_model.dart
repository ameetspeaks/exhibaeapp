class VenueFormModel {
  String? id;
  String name = '';
  String description = '';
  String? venueTypeId;
  String address = '';
  String city = '';
  String state = '';
  String country = '';
  double? latitude;
  double? longitude;
  int capacity = 0;
  double area = 0;
  String? measurementUnitId;
  List<String> amenities = [];
  List<String> images = [];
  String? floorPlan;
  bool isAvailable = true;
  Map<String, dynamic>? additionalInfo;

  VenueFormModel();

  VenueFormModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'] ?? '';
    description = json['description'] ?? '';
    venueTypeId = json['venue_type_id'];
    address = json['address'] ?? '';
    city = json['city'] ?? '';
    state = json['state'] ?? '';
    country = json['country'] ?? '';
    latitude = json['latitude']?.toDouble();
    longitude = json['longitude']?.toDouble();
    capacity = json['capacity'] ?? 0;
    area = (json['area'] ?? 0).toDouble();
    measurementUnitId = json['measurement_unit_id'];
    amenities = List<String>.from(json['amenities'] ?? []);
    images = List<String>.from(json['images'] ?? []);
    floorPlan = json['floor_plan'];
    isAvailable = json['is_available'] ?? true;
    additionalInfo = json['additional_info'];
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      if (venueTypeId != null) 'venue_type_id': venueTypeId,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'capacity': capacity,
      'area': area,
      if (measurementUnitId != null) 'measurement_unit_id': measurementUnitId,
      'amenities': amenities,
      'images': images,
      if (floorPlan != null) 'floor_plan': floorPlan,
      'is_available': isAvailable,
      if (additionalInfo != null) 'additional_info': additionalInfo,
    };
  }

  bool get isValid {
    return name.isNotEmpty &&
           description.isNotEmpty &&
           venueTypeId != null &&
           address.isNotEmpty &&
           city.isNotEmpty &&
           state.isNotEmpty &&
           country.isNotEmpty &&
           capacity > 0 &&
           area > 0 &&
           measurementUnitId != null;
  }
}
