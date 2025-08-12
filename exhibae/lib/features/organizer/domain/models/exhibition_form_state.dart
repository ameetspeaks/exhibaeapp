import 'package:flutter/material.dart';
import 'exhibition_form_model.dart';

enum ExhibitionFormStep {
  basicInfo,
  location,
  media,
  amenities,
  pricing,
  review,
}

class ExhibitionFormState extends ChangeNotifier {
  ExhibitionFormModel _formData = ExhibitionFormModel();
  ExhibitionFormStep _currentStep = ExhibitionFormStep.basicInfo;
  bool _isLoading = false;
  String? _error;
  bool _isEditing = false;

  ExhibitionFormModel get formData => _formData;
  ExhibitionFormStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEditing => _isEditing;

  void init({Map<String, dynamic>? existingData}) {
    if (existingData != null) {
      _formData = ExhibitionFormModel.fromJson(existingData);
      _isEditing = true;
    } else {
      _formData = ExhibitionFormModel();
      _isEditing = false;
    }
    _currentStep = ExhibitionFormStep.basicInfo;
    _error = null;
    notifyListeners();
  }

  void setStep(ExhibitionFormStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    final values = ExhibitionFormStep.values;
    final currentIndex = values.indexOf(_currentStep);
    if (currentIndex < values.length - 1) {
      _currentStep = values[currentIndex + 1];
      notifyListeners();
    }
  }

  void previousStep() {
    final values = ExhibitionFormStep.values;
    final currentIndex = values.indexOf(_currentStep);
    if (currentIndex > 0) {
      _currentStep = values[currentIndex - 1];
      notifyListeners();
    }
  }

  void updateBasicInfo({
    String? title,
    String? description,
    String? categoryId,
    String? eventTypeId,
    DateTime? startDate,
    DateTime? endDate,
    int? expectedVisitors,
  }) {
    if (title != null) _formData.title = title;
    if (description != null) _formData.description = description;
    if (categoryId != null) _formData.categoryId = categoryId;
    if (eventTypeId != null) _formData.eventTypeId = eventTypeId;
    if (startDate != null) _formData.startDate = startDate;
    if (endDate != null) _formData.endDate = endDate;
    if (expectedVisitors != null) _formData.expectedVisitors = expectedVisitors;
    notifyListeners();
  }

  void updateLocation({
    String? address,
    String? city,
    String? state,
    String? country,
    String? venueTypeId,
    double? latitude,
    double? longitude,
  }) {
    if (address != null) _formData.address = address;
    if (city != null) _formData.city = city;
    if (state != null) _formData.state = state;
    if (country != null) _formData.country = country;
    if (venueTypeId != null) _formData.venueTypeId = venueTypeId;
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

  void updatePricing({
    double? stallStartingPrice,
    String? measurementUnitId,
  }) {
    if (stallStartingPrice != null) _formData.stallStartingPrice = stallStartingPrice;
    if (measurementUnitId != null) _formData.measurementUnitId = measurementUnitId;
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
      case ExhibitionFormStep.basicInfo:
        return _formData.title.isNotEmpty &&
               _formData.description.isNotEmpty &&
               _formData.startDate != null &&
               _formData.endDate != null;
      case ExhibitionFormStep.location:
        return _formData.address.isNotEmpty &&
               _formData.city.isNotEmpty &&
               _formData.state.isNotEmpty &&
               _formData.country.isNotEmpty;
      case ExhibitionFormStep.media:
        return true; // Media is optional
      case ExhibitionFormStep.amenities:
        return true; // Amenities are optional
      case ExhibitionFormStep.pricing:
        return _formData.stallStartingPrice != null &&
               _formData.measurementUnitId != null;
      case ExhibitionFormStep.review:
        return _formData.isValid;
    }
  }

  void reset() {
    _formData = ExhibitionFormModel();
    _currentStep = ExhibitionFormStep.basicInfo;
    _isLoading = false;
    _error = null;
    _isEditing = false;
    notifyListeners();
  }
}
