import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import 'dart:convert';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../shared/presentation/widgets/app_feedback.dart';
import '../../../../core/network/app_error_formatter.dart';

import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../auth/data/models/location_models.dart';
import '../../../auth/providers/location_provider.dart';
import '../../../auth/data/repositories/location_repository.dart';

class _RegTok {
  static const Color primary = Color(0xFFFF6600);
  static const Color primaryLight = Color(0xFFFFF0E6);
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9F8F6);
  static const Color border = Color(0xFFEAE8E3);
  static const Color textHigh = Color(0xFF1A1918);
  static const Color textMedium = Color(0xFF5F5C58);
  static const Color textLow = Color(0xFF9F9B96);
}

class BusinessRegistrationScreen extends ConsumerStatefulWidget {
  final BusinessDto? businessToEdit;
  const BusinessRegistrationScreen({super.key, this.businessToEdit});

  @override
  ConsumerState<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends ConsumerState<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 1;

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;

  // Contact Controllers (Step 4)
  String _selectedPhoneCode = '91';
  final List<Map<String, String>> _customPhoneCountries = [];
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Location Controllers (Step 2)
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  Country? _selectedCountry;
  StateModel? _selectedState;
  CityModel? _selectedCity;

  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;

  // Autocomplete Recommendations
  final TextEditingController _locationSearchController = TextEditingController();
  List<dynamic> _locationSuggestions = [];

  // MapLibre
  MapLibreMapController? _mapController;
  Symbol? _marker;
  double? _latitude;
  double? _longitude;
  bool _manuallySelectedCoordinates = false;
  bool _mapInitialized = false;
  bool _userInteractedWithMap = false;

  // Step 3 Photo
  String? _photoBase64;
  String _selectedPhotoLabel = 'No Photo Selected';

  // Step 4 Operations Timings
  List<DayHoursDto> _businessHours = [
    DayHoursDto(day: 'Monday', mode: 'Open', slots: [SlotDto(open: '09:00', close: '18:00')]),
    DayHoursDto(day: 'Tuesday', mode: 'Open', slots: [SlotDto(open: '09:00', close: '18:00')]),
    DayHoursDto(day: 'Wednesday', mode: 'Open', slots: [SlotDto(open: '09:00', close: '18:00')]),
    DayHoursDto(day: 'Thursday', mode: 'Open', slots: [SlotDto(open: '09:00', close: '18:00')]),
    DayHoursDto(day: 'Friday', mode: 'Open', slots: [SlotDto(open: '09:00', close: '18:00')]),
    DayHoursDto(day: 'Saturday', mode: 'Closed', slots: []),
    DayHoursDto(day: 'Sunday', mode: 'Closed', slots: []),
  ];

  bool _isLoading = false;

  List<Map<String, String>> get _phoneCountryItems {
    final list = <Map<String, String>>[];
    list.addAll(_customPhoneCountries);
    for (final c in _countries) {
      if (c.phoneCode != null && c.phoneCode!.isNotEmpty) {
        final code = c.phoneCode!.replaceAll('+', '').trim();
        final emoji = c.emoji ?? '🏳️';
        if (!list.any((item) => item['code'] == code)) {
          list.add({'code': code, 'name': c.name, 'flag': emoji});
        }
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _pincodeController.addListener(_onPincodeChanged);
    if (widget.businessToEdit != null) {
      final edit = widget.businessToEdit!;
      _nameController.text = edit.businessName;
      _descController.text = edit.description;
      _selectedCategoryId = edit.categoryId;
      _selectedSubcategoryId = edit.subcategoryId;
      final normalizedCode = edit.phoneCode.replaceAll('+', '').trim();
      _selectedPhoneCode = normalizedCode.isEmpty ? '91' : normalizedCode;
      _phoneController.text = edit.phoneNumber;
      _emailController.text = edit.email;
      _websiteController.text = edit.website;
      _addressController.text = edit.address;
      _pincodeController.text = edit.pincode;
      _latitude = edit.latitude;
      _longitude = edit.longitude;
      if (edit.hours.isNotEmpty) {
        _businessHours = edit.hours.map((h) => DayHoursDto(
          day: h.day,
          mode: h.mode,
          slots: h.slots.map((s) => SlotDto(open: s.open, close: s.close)).toList(),
        )).toList();
      }
      _selectedPhotoLabel = edit.photos.isNotEmpty ? 'Edit Current Logo' : 'No Photo Selected';
    }
    _loadCountries().then((_) {
      if (widget.businessToEdit != null) {
        _loadLocationDetailsForEdit();
      }
    });
  }

  Future<void> _loadLocationDetailsForEdit() async {
    final res = widget.businessToEdit!;
    if (res.country.isEmpty) return;
    setState(() {
      _loadingCountries = true;
      _loadingStates = true;
      _loadingCities = true;
    });

    try {
      final matchedCountry = _countries.firstWhere(
        (c) => c.name.toLowerCase() == res.country.toLowerCase(),
        orElse: () => _countries.first,
      );
      setState(() => _selectedCountry = matchedCountry);

      final states = await _locationRepo.getStates(matchedCountry.iso2);
      setState(() => _states = states);

      if (res.state.isNotEmpty && states.isNotEmpty) {
        final cleanStateName = res.state.replaceAll('State of ', '').replaceAll(' Union Territory', '').trim().toLowerCase();
        final matchedState = states.firstWhere(
          (s) => s.name.toLowerCase().contains(cleanStateName) || cleanStateName.contains(s.name.toLowerCase()),
          orElse: () => states.first,
        );
        setState(() => _selectedState = matchedState);

        final cities = await _locationRepo.getCities(matchedCountry.iso2, matchedState.iso2);
        setState(() => _cities = cities);

        if (res.city.isNotEmpty && cities.isNotEmpty) {
          final matchedCity = cities.firstWhere(
            (c) => c.name.toLowerCase() == res.city.toLowerCase() || c.name.toLowerCase().contains(res.city.toLowerCase()),
            orElse: () => cities.first,
          );
          setState(() => _selectedCity = matchedCity);
        }
      }
    } catch (e) {
      debugPrint('Error loading location for edit: $e');
    } finally {
      setState(() {
        _loadingCountries = false;
        _loadingStates = false;
        _loadingCities = false;
      });
    }
  }

  @override
  void dispose() {
    _pincodeController.removeListener(_onPincodeChanged);
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6 && int.tryParse(pincode) != null) {
      _lookupPincode(pincode);
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    try {
      final res = await _locationRepo.validatePincode(pincode);
      if (res.city != null && res.city!.isNotEmpty) {
        if (res.country != null && res.country!.isNotEmpty) {
          try {
            final matchedCountry = _countries.firstWhere(
              (c) => c.name.toLowerCase() == res.country!.toLowerCase(),
              orElse: () => _countries.firstWhere((c) => c.name.toLowerCase() == 'india', orElse: () => _countries.first),
            );
            setState(() => _selectedCountry = matchedCountry);

            await _loadStates(matchedCountry.iso2);

            if (res.state != null && res.state!.isNotEmpty) {
              final matchedState = _states.firstWhere(
                (s) => s.name.toLowerCase() == res.state!.toLowerCase(),
                orElse: () => _states.first,
              );
              setState(() => _selectedState = matchedState);

              await _loadCities(matchedCountry.iso2, matchedState.iso2);

              final matchedCity = _cities.firstWhere(
                (c) => c.name.toLowerCase() == res.city!.toLowerCase(),
                orElse: () => _cities.first,
              );
              setState(() => _selectedCity = matchedCity);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  LocationRepository get _locationRepo => ref.read(locationRepositoryProvider);

  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    try {
      final countries = await _locationRepo.getCountries();
      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });
    } catch (e) {
      debugPrint('Error loading countries: $e');
      setState(() => _loadingCountries = false);
    }
  }

  Future<void> _loadStates(String countryIso2) async {
    setState(() {
      _loadingStates = true;
      _states = [];
      _selectedState = null;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final states = await _locationRepo.getStates(countryIso2);
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (e) {
      debugPrint('Error loading states: $e');
      setState(() => _loadingStates = false);
    }
  }

  Future<void> _loadCities(String countryIso2, String stateIso2) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final cities = await _locationRepo.getCities(countryIso2, stateIso2);
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } catch (e) {
      debugPrint('Error loading cities: $e');
      setState(() => _loadingCities = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_selectedCategoryId == null || _selectedSubcategoryId == null) {
        AppFeedback.showWarning(context, 'Please select Category & Subcategory');
        return;
      }
      if (!_formKey.currentState!.validate()) {
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedCountry == null || _selectedState == null || _selectedCity == null) {
        AppFeedback.showWarning(context, 'Please complete location selection');
        return;
      }
      if (_latitude == null || _longitude == null || _latitude == 0.0 || _longitude == 0.0) {
        AppFeedback.showWarning(context, 'Valid map coordinates are required. Pin your store on the map.');
        return;
      }
      if (!_formKey.currentState!.validate()) {
        return;
      }
    } else if (_currentStep == 4) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() {
      if (_currentStep < 5) _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 1) _currentStep--;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null || _latitude == 0.0 || _longitude == 0.0) {
      AppFeedback.showError(
        context,
        'Valid map coordinates are required. Pin location on map.',
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final business = BusinessDto(
        businessId: widget.businessToEdit?.businessId ?? 0,
        businessName: _nameController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId!,
        phoneCode: '+$_selectedPhoneCode',
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        city: _selectedCity?.name ?? '',
        state: _selectedState?.name ?? '',
        country: _selectedCountry?.name ?? '',
        pincode: _pincodeController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        averageRating: widget.businessToEdit?.averageRating ?? 0.0,
        reviewCount: widget.businessToEdit?.reviewCount ?? 0,
        status: widget.businessToEdit?.status ?? 'Pending',
        hours: _businessHours,
        photos: widget.businessToEdit?.photos ?? [],
        photo: _photoBase64,
      );

      if (widget.businessToEdit != null) {
        final success = await ref
            .read(myBusinessesProvider.notifier)
            .updateBusinessProfile(widget.businessToEdit!.businessId, business);
        if (success) {
          if (mounted) {
            AppFeedback.showSuccess(context, 'Business updated successfully!');
            context.pop();
          }
        } else {
          throw Exception('Failed to update business profile.');
        }
      } else {
        final requestJson = business.toJson();
        if (_photoBase64 != null) {
          requestJson['photo'] = _photoBase64;
        }

        final businessId = await ref
            .read(myBusinessesProvider.notifier)
            .register(BusinessDto.fromJson(requestJson));

        if (mounted) {
          AppFeedback.showSuccess(
            context,
            'Business registered successfully! ID: $businessId',
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, AppErrorFormatter.format(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _mapInitialized = true;
    if (_latitude != null && _longitude != null && _latitude != 0.0 && _longitude != 0.0) {
      _addMarker(LatLng(_latitude!, _longitude!));
    }
  }

  void _onMapClick(Point<double> point, LatLng coordinates) {
    if (_mapController != null) {
      setState(() {
        _latitude = coordinates.latitude;
        _longitude = coordinates.longitude;
        _manuallySelectedCoordinates = true;
      });
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: coordinates,
            zoom: _mapController!.cameraPosition?.zoom ?? 12,
          ),
        ),
      );
      _addMarker(coordinates);
    }
  }

  Future<void> _addMarker(LatLng pos) async {
    if (_mapController == null) return;
    try {
      if (_marker != null) {
        await _mapController!.removeSymbol(_marker!);
      }
      _marker = await _mapController!.addSymbol(SymbolOptions(
        geometry: pos,
        iconImage: 'marker-15',
        iconSize: 2.0,
        iconColor: '#FF6600',
      ));
    } catch (e) {
      debugPrint('Skipping map symbol draw: $e');
    }
  }

  Future<void> _geocodeSelectedCity() async {
    if (_selectedCity == null) return;
    if (_manuallySelectedCoordinates) return;

    try {
      final cityStr = _selectedCity!.name;
      final stateStr = _selectedState?.name ?? '';
      final countryStr = _selectedCountry?.name ?? 'India';
      final queryText = '$cityStr, $stateStr, $countryStr';

      final dio = Dio();
      final response = await dio.get(
        'https://api.geoapify.com/v1/geocode/search',
        queryParameters: {
          'text': queryText,
          'format': 'json',
          'apiKey': AppConfig.geoapifyApiKey,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final result = results.first as Map<String, dynamic>;
          final lat = result['lat'] as double?;
          final lon = result['lon'] as double?;
          if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
            setState(() {
              _latitude = lat;
              _longitude = lon;
              _userInteractedWithMap = false;
            });
            if (_mapController != null) {
              final pos = LatLng(lat, lon);
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 12)),
              );
              _addMarker(pos);
            }
            return;
          }
        }
      }

      setState(() {
        _latitude = null;
        _longitude = null;
      });
    } catch (_) {
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppFeedback.showWarning(context, 'Location services are disabled.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppFeedback.showWarning(context, 'Location permissions are denied.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppFeedback.showWarning(context, 'Location permissions are permanently denied.');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (position.latitude != 0.0 && position.longitude != 0.0) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _userInteractedWithMap = false;
        });

        final pos = LatLng(position.latitude, position.longitude);
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 15)),
          );
        }
        _addMarker(pos);

        // Reverse geocode to auto-fill address
        final dio = Dio();
        final response = await dio.get(
          'https://api.geoapify.com/v1/geocode/reverse',
          queryParameters: {
            'lat': position.latitude,
            'lon': position.longitude,
            'format': 'json',
            'apiKey': AppConfig.geoapifyApiKey,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final results = response.data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final result = results.first as Map<String, dynamic>;
            final countryName = result['country'] as String?;
            final stateName = result['state'] as String?;
            final cityName = result['city'] as String? ?? result['town'] as String? ?? result['village'] as String?;
            final postcode = result['postcode'] as String?;
            final street = result['street'] as String?;
            final housenumber = result['housenumber'] as String?;

            String address = '';
            if (housenumber != null) address += '$housenumber ';
            if (street != null) address += street;

            setState(() {
              if (address.isNotEmpty) {
                _addressController.text = address;
              }
              if (postcode != null) {
                _pincodeController.text = postcode;
              }
            });

            if (countryName != null) {
              final matchedCountry = _countries.firstWhere(
                (c) => c.name.toLowerCase() == countryName.toLowerCase(),
                orElse: () => _countries.first,
              );
              setState(() => _selectedCountry = matchedCountry);
              await _loadStates(matchedCountry.iso2);

              if (stateName != null && _states.isNotEmpty) {
                final cleanStateName = stateName.replaceAll('State of ', '').replaceAll(' Union Territory', '').trim().toLowerCase();
                final matchedState = _states.firstWhere(
                  (s) => s.name.toLowerCase().contains(cleanStateName) || cleanStateName.contains(s.name.toLowerCase()),
                  orElse: () => _states.first,
                );
                setState(() => _selectedState = matchedState);
                await _loadCities(matchedCountry.iso2, matchedState.iso2);

                if (cityName != null && _cities.isNotEmpty) {
                  final matchedCity = _cities.firstWhere(
                    (c) => c.name.toLowerCase() == cityName.toLowerCase() || c.name.toLowerCase().contains(cityName.toLowerCase()),
                    orElse: () => _cities.first,
                  );
                  setState(() => _selectedCity = matchedCity);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Str = base64Encode(bytes);
        setState(() {
          _photoBase64 = base64Str;
          _selectedPhotoLabel = image.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _searchLocation(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _locationSuggestions = [];
      });
      return;
    }
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.geoapify.com/v1/geocode/autocomplete',
        queryParameters: {
          'text': text,
          'format': 'json',
          'apiKey': AppConfig.geoapifyApiKey,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List?;
        if (results != null) {
          setState(() {
            _locationSuggestions = results;
          });
        }
      }
    } catch (_) {}
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RegTok.bg,
      appBar: AppBar(
        backgroundColor: _RegTok.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.businessToEdit != null ? 'Edit Store Details' : 'List New Business',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: _RegTok.textHigh,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _RegTok.textMedium, size: 18),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: _RegTok.border,
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _RegTok.primary))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildStepper(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      physics: const BouncingScrollPhysics(),
                      child: _buildCurrentStepContent(),
                    ),
                  ),
                  _buildBottomNavigation(),
                ],
              ),
            ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: _RegTok.surface,
        border: Border(bottom: BorderSide(color: _RegTok.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1, 'Profile'),
          _buildStepLine(2),
          _buildStepCircle(2, 'Map'),
          _buildStepLine(3),
          _buildStepCircle(3, 'Gallery'),
          _buildStepLine(4),
          _buildStepCircle(4, 'Hours'),
          _buildStepLine(5),
          _buildStepCircle(5, 'Publish'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isCompleted = _currentStep > step;
    final isActive = _currentStep == step;
    final isPassed = _currentStep >= step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? _RegTok.primaryLight
                : isActive
                    ? _RegTok.primary
                    : _RegTok.surface,
            border: Border.all(
              color: isPassed ? _RegTok.primary : _RegTok.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: _RegTok.primary, size: 14)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isActive ? Colors.white : _RegTok.textMedium,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isPassed ? _RegTok.primary : _RegTok.textLow,
            fontSize: 9.5,
            fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int toStep) {
    final isHighlighted = _currentStep >= toStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
      color: isHighlighted ? _RegTok.primary : _RegTok.border,
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store Category & Brand',
          style: TextStyle(color: _RegTok.textHigh, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),

        categoriesAsync.when(
          data: (categories) => DropdownButtonFormField<int>(
            dropdownColor: _RegTok.bg,
            initialValue: categories.any((cat) => cat.categoryId == _selectedCategoryId) ? _selectedCategoryId : null,
            style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
            decoration: _inputDecoration('Primary Category', Icons.category_rounded),
            items: categories.map((cat) {
              return DropdownMenuItem<int>(
                value: cat.categoryId,
                child: Text(cat.categoryName),
              );
            }).toList(),
            onChanged: (catId) {
              setState(() {
                _selectedCategoryId = catId;
                _selectedSubcategoryId = null;
              });
            },
          ),
          loading: () => const LinearProgressIndicator(color: _RegTok.primary),
          error: (err, st) => const Text('Error loading categories', style: TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 14),

        if (_selectedCategoryId != null) ...[
          ref.watch(subcategoriesProvider(_selectedCategoryId!)).when(
                data: (subcategories) => DropdownButtonFormField<int>(
                  dropdownColor: _RegTok.bg,
                  initialValue: subcategories.any((sub) => sub.subcategoryId == _selectedSubcategoryId) ? _selectedSubcategoryId : null,
                  style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
                  decoration: _inputDecoration('Subcategory Type', Icons.layers_rounded),
                  items: subcategories.map((sub) {
                    return DropdownMenuItem<int>(
                      value: sub.subcategoryId,
                      child: Text(sub.subcategoryName),
                    );
                  }).toList(),
                  onChanged: (subId) {
                    setState(() {
                      _selectedSubcategoryId = subId;
                    });
                  },
                ),
                loading: () => const LinearProgressIndicator(color: _RegTok.primary),
                error: (err, st) => const Text('Error loading subcategories', style: TextStyle(color: Colors.red)),
              ),
          const SizedBox(height: 14),
        ],

        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
          decoration: _inputDecoration('Business / Store Name', Icons.storefront_rounded),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Business Name is required';
            return null;
          },
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _descController,
          style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
          maxLines: 4,
          decoration: _inputDecoration('Store Overview Description', Icons.description_rounded),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Description is required';
            if (value.trim().length < 10) return 'Must be at least 10 characters';
            return null;
          },
        ),
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _generateAIDescription,
            icon: const Icon(Icons.auto_awesome, color: _RegTok.primary, size: 14),
            label: const Text(
              'AI Generate Description',
              style: TextStyle(color: _RegTok.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final osmStyle = '''
{
  "version": 8,
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://maps.geoapify.com/v1/tile/osm-carto/{z}/{x}/{y}.png?apiKey=${AppConfig.geoapifyApiKey}"],
      "tileSize": 256
    }
  },
  "layers": [
    {
      "id": "osm-layer",
      "type": "raster",
      "source": "osm",
      "minzoom": 0,
      "maxzoom": 19
    }
  ]
}
''';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pin Location on Map',
          style: TextStyle(color: _RegTok.textHigh, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),

        // Search address autocomplete input field
        TextFormField(
          controller: _locationSearchController,
          style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
          decoration: _inputDecoration('Search Address to Pin...', Icons.search_rounded).copyWith(
            suffixIcon: _locationSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: _RegTok.textMedium, size: 16),
                    onPressed: () {
                      _locationSearchController.clear();
                      setState(() {
                        _locationSuggestions = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: _searchLocation,
        ),

        if (_locationSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 12),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: _RegTok.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _RegTok.border),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _locationSuggestions.length,
              itemBuilder: (context, idx) {
                final item = _locationSuggestions[idx];
                final address = item['formatted'] as String? ?? '';
                return ListTile(
                  title: Text(address, style: const TextStyle(color: _RegTok.textHigh, fontSize: 12)),
                  dense: true,
                  onTap: () async {
                    final lat = item['lat'] as double?;
                    final lon = item['lon'] as double?;
                    if (lat != null && lon != null) {
                      setState(() {
                        _latitude = lat;
                        _longitude = lon;
                        _locationSuggestions = [];
                        _locationSearchController.text = address;
                        _manuallySelectedCoordinates = true;
                      });
                      if (_mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(lat, lon), zoom: 15)),
                        );
                      }
                      _addMarker(LatLng(lat, lon));

                      // Auto-fill address detail fields
                      _addressController.text = item['name'] as String? ?? item['street'] as String? ?? '';
                      _pincodeController.text = item['postcode'] as String? ?? '';
                    }
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 14),

        // Map Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Map Finder', style: TextStyle(color: _RegTok.textMedium, fontSize: 12, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location_rounded, color: _RegTok.primary, size: 14),
              label: const Text('Use GPS', style: TextStyle(color: _RegTok.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),

        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _RegTok.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Listener(
                onPointerDown: (_) => setState(() => _userInteractedWithMap = true),
                child: MapLibreMap(
                  styleString: osmStyle,
                  initialCameraPosition: CameraPosition(
                    target: (_latitude != null && _longitude != null && _latitude != 0.0 && _longitude != 0.0)
                        ? LatLng(_latitude!, _longitude!)
                        : const LatLng(12.9716, 77.5946),
                    zoom: (_latitude != null && _longitude != null) ? 14 : 6,
                  ),
                  onMapCreated: _onMapCreated,
                  onMapClick: _onMapClick,
                  myLocationEnabled: true,
                  onCameraIdle: () {
                    if (_mapController != null && _mapInitialized && _userInteractedWithMap) {
                      final target = _mapController!.cameraPosition?.target;
                      if (target != null) {
                        setState(() {
                          _latitude = target.latitude;
                          _longitude = target.longitude;
                        });
                        _addMarker(target);
                      }
                    }
                  },
                ),
              ),
              IgnorePointer(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: const Icon(Icons.location_pin, color: _RegTok.primary, size: 34),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dropdowns for Country, State, City
        _loadingCountries
            ? const LinearProgressIndicator(color: _RegTok.primary)
            : DropdownButtonFormField<Country>(
                dropdownColor: _RegTok.bg,
                initialValue: _selectedCountry,
                style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
                decoration: _inputDecoration('Country', Icons.public_rounded),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (Country? val) {
                  setState(() {
                    _selectedCountry = val;
                    if (val != null) _loadStates(val.iso2);
                  });
                },
              ),
        const SizedBox(height: 14),

        if (_selectedCountry != null) ...[
          _loadingStates
              ? const LinearProgressIndicator(color: _RegTok.primary)
              : DropdownButtonFormField<StateModel>(
                  dropdownColor: _RegTok.bg,
                  initialValue: _selectedState,
                  style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
                  decoration: _inputDecoration('State', Icons.map_rounded),
                  items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (StateModel? val) {
                    setState(() {
                      _selectedState = val;
                      if (val != null) _loadCities(_selectedCountry!.iso2, val.iso2);
                    });
                  },
                ),
          const SizedBox(height: 14),
        ],

        if (_selectedState != null) ...[
          _loadingCities
              ? const LinearProgressIndicator(color: _RegTok.primary)
              : DropdownButtonFormField<CityModel>(
                  dropdownColor: _RegTok.bg,
                  initialValue: _selectedCity,
                  style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
                  decoration: _inputDecoration('City', Icons.location_city_rounded),
                  items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                  onChanged: (CityModel? val) {
                    setState(() {
                      _selectedCity = val;
                      _manuallySelectedCoordinates = false;
                    });
                    if (val != null) _geocodeSelectedCity();
                  },
                ),
          const SizedBox(height: 14),
        ],

        TextFormField(
          controller: _addressController,
          style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
          decoration: _inputDecoration('Street address & Landmark', Icons.home_rounded),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Street address is required';
            return null;
          },
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _pincodeController,
          style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
          decoration: _inputDecoration('Postal Pincode', Icons.pin_drop_rounded),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Pincode is required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Cover Media',
          style: TextStyle(color: _RegTok.textHigh, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),

        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: _RegTok.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _RegTok.border, style: BorderStyle.solid, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: _RegTok.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_photo_alternate_rounded, color: _RegTok.primary, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload Primary Banner Logo',
                  style: TextStyle(color: _RegTok.textHigh, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPhotoLabel,
                  style: const TextStyle(color: _RegTok.textLow, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        if (_photoBase64 != null) ...[
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: MemoryImage(base64Decode(_photoBase64!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _photoBase64 = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.businessToEdit != null && widget.businessToEdit!.photos.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage('${Uri.parse(DioClient().dio.options.baseUrl).origin}${widget.businessToEdit!.photos.first}'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact & Operating Timings',
          style: TextStyle(color: _RegTok.textHigh, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedPhoneCode,
                decoration: _inputDecoration('Code', Icons.add),
                dropdownColor: _RegTok.bg,
                style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
                items: _phoneCountryItems.map((pc) {
                  return DropdownMenuItem(value: pc['code'], child: Text('+${pc['code']}'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPhoneCode = val);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
                decoration: _inputDecoration('Phone Number', Icons.phone_rounded),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Phone number is required';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
          decoration: _inputDecoration('Store Email Address', Icons.email_rounded),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Email is required';
            return null;
          },
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
          decoration: _inputDecoration('Website URL (Optional)', Icons.language_rounded),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Schedules',
              style: TextStyle(color: _RegTok.textHigh, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                final monHours = _businessHours.first;
                setState(() {
                  for (int i = 1; i < _businessHours.length; i++) {
                    _businessHours[i] = DayHoursDto(
                      day: _businessHours[i].day,
                      mode: monHours.mode,
                      slots: monHours.slots.map((s) => SlotDto(open: s.open, close: s.close)).toList(),
                    );
                  }
                });
              },
              icon: const Icon(Icons.copy_rounded, color: _RegTok.primary, size: 14),
              label: const Text('Apply Mon to all days', style: TextStyle(color: _RegTok.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _businessHours.length,
          itemBuilder: (context, index) {
            final day = _businessHours[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _RegTok.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _RegTok.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(day.day, style: const TextStyle(color: _RegTok.textHigh, fontSize: 13, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      if (day.mode == 'Open') ...[
                        GestureDetector(
                          onTap: () async {
                            final initialTime = day.slots.isNotEmpty ? _parseTimeOfDay(day.slots.first.open) : const TimeOfDay(hour: 9, minute: 0);
                            final time = await showTimePicker(context: context, initialTime: initialTime);
                            if (time != null) {
                              final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                              setState(() {
                                day.slots[0] = SlotDto(open: formatted, close: day.slots.first.close);
                              });
                            }
                          },
                          child: Text(
                            day.slots.isNotEmpty ? day.slots.first.open : '09:00',
                            style: const TextStyle(color: _RegTok.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text(' - ', style: TextStyle(color: _RegTok.textLow)),
                        GestureDetector(
                          onTap: () async {
                            final initialTime = day.slots.isNotEmpty ? _parseTimeOfDay(day.slots.first.close) : const TimeOfDay(hour: 18, minute: 0);
                            final time = await showTimePicker(context: context, initialTime: initialTime);
                            if (time != null) {
                              final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                              setState(() {
                                day.slots[0] = SlotDto(open: day.slots.first.open, close: formatted);
                              });
                            }
                          },
                          child: Text(
                            day.slots.isNotEmpty ? day.slots.first.close : '18:00',
                            style: const TextStyle(color: _RegTok.primary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        const Text('Closed', style: TextStyle(color: Colors.red, fontSize: 12)),
                        const SizedBox(width: 8),
                      ],
                      Switch(
                        value: day.mode == 'Open',
                        activeTrackColor: _RegTok.primaryLight,
                        activeThumbColor: _RegTok.primary,
                        onChanged: (val) {
                          setState(() {
                            _businessHours[index] = DayHoursDto(
                              day: day.day,
                              mode: val ? 'Open' : 'Closed',
                              slots: val ? [SlotDto(open: '09:00', close: '18:00')] : [],
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Listing Mockup Preview',
          style: TextStyle(color: _RegTok.textHigh, fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Verify how customers will view your listing in local directory search feeds.',
          style: TextStyle(color: _RegTok.textMedium, fontSize: 11.5),
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _RegTok.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              _photoBase64 != null
                  ? Image.memory(base64Decode(_photoBase64!), height: 130, width: double.infinity, fit: BoxFit.cover)
                  : (widget.businessToEdit != null && widget.businessToEdit!.photos.isNotEmpty)
                      ? Image.network('${Uri.parse(DioClient().dio.options.baseUrl).origin}${widget.businessToEdit!.photos.first}', height: 130, width: double.infinity, fit: BoxFit.cover)
                      : Container(
                          height: 130,
                          color: _RegTok.surface,
                          child: const Center(child: Icon(Icons.storefront_rounded, color: _RegTok.primary, size: 40)),
                        ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _nameController.text.isEmpty ? 'Your Business Title' : _nameController.text,
                            style: const TextStyle(color: _RegTok.textHigh, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _RegTok.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                              SizedBox(width: 2),
                              Text('4.8', style: TextStyle(color: _RegTok.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Address: ${_addressController.text.isEmpty ? "No Address Entered" : _addressController.text}, ${_selectedCity?.name ?? ""}',
                      style: const TextStyle(color: _RegTok.textMedium, fontSize: 11.5),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: _RegTok.border, height: 1),
                    const SizedBox(height: 10),

                    // Actions Mock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPreviewIcon(Icons.call_rounded, 'Call'),
                        _buildPreviewIcon(Icons.directions_rounded, 'Directions'),
                        _buildPreviewIcon(Icons.language_rounded, 'Website'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text('About Store', style: TextStyle(color: _RegTok.textHigh, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _descController.text.isEmpty ? 'Enter a detailed description to attract users.' : _descController.text,
                      style: const TextStyle(color: _RegTok.textMedium, fontSize: 11.5, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _RegTok.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _RegTok.primary, size: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: _RegTok.textMedium, fontSize: 10)),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _RegTok.bg,
        border: Border(top: BorderSide(color: _RegTok.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 1)
            GestureDetector(
              onTap: _previousStep,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _RegTok.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _RegTok.border),
                ),
                child: const Text('Back', style: TextStyle(color: _RegTok.textMedium, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            )
          else
            const SizedBox(width: 70),

          GestureDetector(
            onTap: _currentStep == 5 ? _submitForm : _nextStep,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: _RegTok.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _RegTok.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _currentStep == 5 ? 'Publish Listing' : 'Next Step',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _RegTok.textMedium, fontSize: 12.5),
      prefixIcon: Icon(icon, color: _RegTok.primary, size: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _RegTok.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _RegTok.primary, width: 1.5),
      ),
      filled: true,
      fillColor: _RegTok.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
    );
  }

  Future<void> _generateAIDescription() async {
    final keywordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final generated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _RegTok.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: _RegTok.primary, size: 20),
            SizedBox(width: 8),
            Text('AI Description Generator', style: TextStyle(color: _RegTok.textHigh, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter keywords describing your store (e.g. coffee, cozy, vegan, wifi):',
                style: TextStyle(color: _RegTok.textMedium, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: keywordController,
                style: const TextStyle(color: _RegTok.textHigh, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'cozy, hand-made, local...',
                  hintStyle: const TextStyle(color: _RegTok.textLow, fontSize: 12),
                  filled: true,
                  fillColor: _RegTok.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _RegTok.border)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Keywords are required';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _RegTok.textLow)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _RegTok.primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: _RegTok.primary)),
                );

                try {
                  final keywords = keywordController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  final categoriesVal = ref.read(categoriesProvider);
                  final categoryName = categoriesVal.maybeWhen(
                    data: (list) {
                      final matched = list.firstWhere(
                        (c) => c.categoryId == _selectedCategoryId,
                        orElse: () => CategoryDto(categoryId: 0, categoryName: 'general', iconUrl: null),
                      );
                      return matched.categoryName;
                    },
                    orElse: () => 'general',
                  );

                  final response = await DioClient().dio.post(
                    'ai/generate-description',
                    data: {
                      'businessName': _nameController.text.trim().isEmpty ? 'Our Business' : _nameController.text.trim(),
                      'category': categoryName,
                      'keywords': keywords,
                    },
                  );

                  if (context.mounted) Navigator.pop(context); // Pop spinner
                  if (context.mounted) {
                    final data = response.data['data'] as String?;
                    Navigator.pop(context, data);
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context); // Pop spinner
                  if (context.mounted) {
                    AppFeedback.showError(context, 'Failed: ${e.toString()}');
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (generated != null && generated.isNotEmpty) {
      setState(() {
        _descController.text = generated;
      });
    }
  }
}
