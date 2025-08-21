import 'package:flutter/material.dart';
import 'stall_form_model.dart';

enum StallFormStep {
  basicInfo,
  dimensions,
  amenities,
  layout,
  review,
}

class StallFormState extends ChangeNotifier {
  late StallFormModel _formData;
  StallFormStep _currentStep = StallFormStep.basicInfo;
  bool _isLoading = false;
  String? _error;
  bool _isEditing = false;

  StallFormModel get formData => _formData;
  StallFormStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEditing => _isEditing;

  void init({required String exhibitionId, Map<String, dynamic>? existingData}) {
    if (existingData != null) {
      _formData = StallFormModel.fromJson(existingData);
      _isEditing = true;
    } else {
      _formData = StallFormModel(exhibitionId: exhibitionId);
      _isEditing = false;
    }
    _currentStep = StallFormStep.basicInfo;
    _error = null;
    notifyListeners();
  }

  void setStep(StallFormStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    final values = StallFormStep.values;
    final currentIndex = values.indexOf(_currentStep);
    if (currentIndex < values.length - 1) {
      _currentStep = values[currentIndex + 1];
      notifyListeners();
    }
  }

  void previousStep() {
    final values = StallFormStep.values;
    final currentIndex = values.indexOf(_currentStep);
    if (currentIndex > 0) {
      _currentStep = values[currentIndex - 1];
      notifyListeners();
    }
  }

  void updateBasicInfo({
    String? name,
    double? price,
  }) {
    if (name != null) _formData.name = name;
    if (price != null) _formData.price = price;
    notifyListeners();
  }

  void updateDimensions({
    double? length,
    double? width,
    double? height,
    String? measurementUnitId,
  }) {
    if (length != null) _formData.length = length;
    if (width != null) _formData.width = width;
    if (height != null) _formData.height = height;
    if (measurementUnitId != null) _formData.measurementUnitId = measurementUnitId;
    notifyListeners();
  }

  void updateAmenities(List<String> amenities) {
    _formData.amenities = amenities;
    notifyListeners();
  }

  void addStallInstance({
    required int instanceNumber,
    required double positionX,
    required double positionY,
    double rotationAngle = 0,
    String status = 'available',
  }) {
    _formData.addInstance(
      instanceNumber: instanceNumber,
      positionX: positionX,
      positionY: positionY,
      rotationAngle: rotationAngle,
      status: status,
    );
    notifyListeners();
  }

  void removeStallInstance(int instanceNumber) {
    _formData.removeInstance(instanceNumber);
    notifyListeners();
  }

  void updateInstancePosition(int instanceNumber, double x, double y) {
    _formData.updateInstancePosition(instanceNumber, x, y);
    notifyListeners();
  }

  void updateInstanceRotation(int instanceNumber, double angle) {
    _formData.updateInstanceRotation(instanceNumber, angle);
    notifyListeners();
  }

  void updateInstancePrice(int instanceNumber, double newPrice) {
    _formData.updateInstancePrice(instanceNumber, newPrice);
    notifyListeners();
  }

  void updateInstanceStatus(int instanceNumber, String status) {
    _formData.updateInstanceStatus(instanceNumber, status);
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
      case StallFormStep.basicInfo:
        return _formData.name.isNotEmpty &&
               _formData.description.isNotEmpty &&
               _formData.price > 0;
      case StallFormStep.dimensions:
        return _formData.length > 0 &&
               _formData.width > 0 &&
               _formData.height > 0 &&
               _formData.measurementUnitId != null;
      case StallFormStep.amenities:
        return true; // Amenities are optional
      case StallFormStep.layout:
        return _formData.instances.isNotEmpty;
      case StallFormStep.review:
        return _formData.isValid;
    }
  }

  void reset() {
    _formData = StallFormModel(exhibitionId: _formData.exhibitionId);
    _currentStep = StallFormStep.basicInfo;
    _isLoading = false;
    _error = null;
    _isEditing = false;
    notifyListeners();
  }
}
