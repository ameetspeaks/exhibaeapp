import 'package:flutter/material.dart';
import 'venue_form_model.dart';

enum VenueFormStep {
  basicInfo,
  location,
  media,
  amenities,
  review,
}

class VenueFormState extends ChangeNotifier {
  VenueFormModel _formData = VenueFormModel();
  VenueFormStep _currentStep = VenueFormStep.basicInfo;
  bool _isLoading = false;
  String? _error;
  bool _isEditing = false;

  VenueFormModel get formData => _formData;
  VenueFormStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEditing => _isEditing;

  void init({Map<String, dynamic>? existingData}) {
    if (existingData != null) {
      _formData = VenueFormModel.fromJson(existingData);
      _isEditing = true;
    } else {
      _formData = VenueFormModel();
      _isEditing = false;
    }
    _currentStep = VenueFormStep.basicInfo;
    _error = null;
    notifyListeners();
  }

  void setStep(VenueFormStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    final values = VenueFormStep.values;
    final currentIndex = values.indexOf(_currentStep);
    if (currentIndex < values.length - 1) {
      _currentStep = values[currentIndex + 1];
      notifyListeners();
    }
  }

  void previousStep() {
    final values = VenueFormStep.values;
    final currentIndex = values.indexOf(_currentStep);
    if (currentIndex > 0) {
      _currentStep = values[currentIndex - 1];
      notifyListeners();
    }
  }

  void updateBasicInfo({
    String? name,
    String? description,
    String? venueTypeId,
    int? capacity,
    double? area,
    String? measurementUnitId,
    bool? isAvailable,
  }) {
    if (name != null) _formData.name = name;
    if (description != null) _formData.description = description;
    if (venueTypeId != null) _formData.venueTypeId = venueTypeId;
    if (capacity != null) _formData.capacity = capacity;
    if (area != null) _formData.area = area;
    if (measurementUnitId != null) _formData.measurementUnitId = measurementUnitId;
    if (isAvailable != null) _formData.isAvailable = isAvailable;
    notifyListeners();
  }

  void updateLocation({
    String? address,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
  }) {
    if (address != null) _formData.address = address;
    if (city != null) _formData.city = city;
    if (state != null) _formData.state = state;
    if (country != null) _formData.country = country;
    if (latitude != null) _formData.latitude = latitude;
    if (longitude != null) _formData.longitude = longitude;
    notifyListeners();
  }

  void updateMedia({
    String? floorPlan,
    List<String>? images,
  }) {
    if (floorPlan != null) _formData.floorPlan = floorPlan;
    if (images != null) _formData.images = images;
    notifyListeners();
  }

  void updateAmenities(List<String> amenities) {
    _formData.amenities = amenities;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  bool canProceed() {
    switch (_currentStep) {
      case VenueFormStep.basicInfo:
        return _formData.name.isNotEmpty &&
               _formData.description.isNotEmpty &&
               _formData.venueTypeId != null &&
               _formData.capacity > 0 &&
               _formData.area > 0 &&
               _formData.measurementUnitId != null;
      case VenueFormStep.location:
        return _formData.address.isNotEmpty &&
               _formData.city.isNotEmpty &&
               _formData.state.isNotEmpty &&
               _formData.country.isNotEmpty;
      case VenueFormStep.media:
        return true; // Media is optional
      case VenueFormStep.amenities:
        return true; // Amenities are optional
      case VenueFormStep.review:
        return _formData.isValid;
    }
  }

  void reset() {
    _formData = VenueFormModel();
    _currentStep = VenueFormStep.basicInfo;
    _isLoading = false;
    _error = null;
    _isEditing = false;
    notifyListeners();
  }
}
