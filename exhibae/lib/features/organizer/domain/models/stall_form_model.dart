class StallFormModel {
  String? id;
  String exhibitionId;
  String name = '';
  String description = '';
  double length = 0;
  double width = 0;
  double height = 0;
  double price = 0;
  String? measurementUnitId;
  List<String> amenities = [];
  List<Map<String, dynamic>> instances = [];

  StallFormModel({required this.exhibitionId});

  StallFormModel.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        exhibitionId = json['exhibition_id'],
        name = json['name'] ?? '',
        description = json['description'] ?? '',
        length = (json['length'] ?? 0).toDouble(),
        width = (json['width'] ?? 0).toDouble(),
        height = (json['height'] ?? 0).toDouble(),
        price = (json['price'] ?? 0).toDouble(),
        measurementUnitId = json['measurement_unit_id'],
        amenities = List<String>.from(json['amenities'] ?? []),
        instances = List<Map<String, dynamic>>.from(json['instances'] ?? []);

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'exhibition_id': exhibitionId,
      'name': name,
      'description': description,
      'length': length,
      'width': width,
      'height': height,
      'price': price,
      if (measurementUnitId != null) 'measurement_unit_id': measurementUnitId,
      'amenities': amenities,
      'instances': instances,
    };
  }

  bool get isValid {
    return name.isNotEmpty &&
           description.isNotEmpty &&
           length > 0 &&
           width > 0 &&
           height > 0 &&
           price > 0 &&
           measurementUnitId != null;
  }

  void addInstance({
    required int instanceNumber,
    required double positionX,
    required double positionY,
    double rotationAngle = 0,
    String status = 'available',
  }) {
    instances.add({
      'instance_number': instanceNumber,
      'position_x': positionX,
      'position_y': positionY,
      'rotation_angle': rotationAngle,
      'status': status,
      'price': price,
      'original_price': price,
    });
  }

  void removeInstance(int instanceNumber) {
    instances.removeWhere((instance) => instance['instance_number'] == instanceNumber);
  }

  void updateInstancePosition(int instanceNumber, double x, double y) {
    final index = instances.indexWhere((instance) => instance['instance_number'] == instanceNumber);
    if (index != -1) {
      instances[index]['position_x'] = x;
      instances[index]['position_y'] = y;
    }
  }

  void updateInstanceRotation(int instanceNumber, double angle) {
    final index = instances.indexWhere((instance) => instance['instance_number'] == instanceNumber);
    if (index != -1) {
      instances[index]['rotation_angle'] = angle;
    }
  }

  void updateInstancePrice(int instanceNumber, double newPrice) {
    final index = instances.indexWhere((instance) => instance['instance_number'] == instanceNumber);
    if (index != -1) {
      instances[index]['price'] = newPrice;
    }
  }

  void updateInstanceStatus(int instanceNumber, String status) {
    final index = instances.indexWhere((instance) => instance['instance_number'] == instanceNumber);
    if (index != -1) {
      instances[index]['status'] = status;
    }
  }
}
