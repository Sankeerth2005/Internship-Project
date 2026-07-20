import 'package:flutter/material.dart';
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

import '../../providers/business_provider.dart';
import '../../data/models/business_models.dart';
import '../../../auth/data/models/location_models.dart';
import '../../../auth/providers/location_provider.dart';
import '../../../auth/data/repositories/location_repository.dart';

class BusinessRegistrationScreen extends ConsumerStatefulWidget {
  final BusinessDto? businessToEdit;
  const BusinessRegistrationScreen({super.key, this.businessToEdit});

  @override
  ConsumerState<BusinessRegistrationScreen> createState() =>
      _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState
    extends ConsumerState<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 1;

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;

  // Step 2 Controllers
  String _selectedPhoneCode = '91';
  final List<Map<String, String>> _customPhoneCountries = [];

  List<Map<String, String>> get _phoneCountryItems {
    final list = <Map<String, String>>[];
    // list.addAll([
    //   {'code': '91', 'name': 'India', 'flag': '🇮🇳'},
    //   {'code': '1', 'name': 'United States', 'flag': '🇺🇸'},
    //   {'code': '44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    //   {'code': '61', 'name': 'Australia', 'flag': '🇦🇺'},
    // ]);
    
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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Location data
  List<Country> _countries = [];
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  Country? _selectedCountry;
  StateModel? _selectedState;
  CityModel? _selectedCity;

  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingCities = false;

  // Autocomplete Location Recommendation
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

  // Step 3 Data
  String? _photoBase64;
  String _selectedPhotoLabel = 'No Photo Selected';
  List<DayHoursDto> _businessHours = [
    DayHoursDto(
      day: 'Monday',
      mode: 'Open',
      slots: [SlotDto(open: '09:00', close: '18:00')],
    ),
    DayHoursDto(
      day: 'Tuesday',
      mode: 'Open',
      slots: [SlotDto(open: '09:00', close: '18:00')],
    ),
    DayHoursDto(
      day: 'Wednesday',
      mode: 'Open',
      slots: [SlotDto(open: '09:00', close: '18:00')],
    ),
    DayHoursDto(
      day: 'Thursday',
      mode: 'Open',
      slots: [SlotDto(open: '09:00', close: '18:00')],
    ),
    DayHoursDto(
      day: 'Friday',
      mode: 'Open',
      slots: [SlotDto(open: '09:00', close: '18:00')],
    ),
    DayHoursDto(
      day: 'Saturday',
      mode: 'Closed',
      slots: [],
    ),
    DayHoursDto(
      day: 'Sunday',
      mode: 'Closed',
      slots: [],
    ),
  ];

  bool _isLoading = false;

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
      if (_phoneCountryItems.any((pc) => pc['code'] == normalizedCode)) {
        _selectedPhoneCode = normalizedCode;
      } else if (normalizedCode.isNotEmpty) {
        _customPhoneCountries.add({'code': normalizedCode, 'name': 'Other', 'flag': '🏳️'});
        _selectedPhoneCode = normalizedCode;
      } else {
        _selectedPhoneCode = '91';
      }
      _phoneController.text = edit.phoneNumber;
      _emailController.text = edit.email;
      _websiteController.text = edit.website;
      _addressController.text = edit.address;
      _pincodeController.text = edit.pincode;
      _latitude = edit.latitude;
      _longitude = edit.longitude;
      _businessHours = List.from(edit.hours);
      _loadLocationForEdit();
    } else {
      _loadCountries();
    }
  }

  Future<void> _loadLocationForEdit() async {
    final edit = widget.businessToEdit;
    if (edit == null) return;

    setState(() {
      _loadingCountries = true;
      _loadingStates = true;
      _loadingCities = true;
    });

    try {
      // 1. Load countries
      final countries = await _locationRepo.getCountries();
      _countries = countries;
      _loadingCountries = false;

      // Find matching country
      Country? country;
      try {
        country = countries.firstWhere(
          (c) => c.name.toLowerCase() == edit.country.toLowerCase(),
        );
      } catch (_) {
        try {
          country = countries.firstWhere((c) => c.name == 'India');
        } catch (_) {
          if (countries.isNotEmpty) country = countries.first;
        }
      }
      _selectedCountry = country;

      if (country != null) {
        // 2. Load states
        final states = await _locationRepo.getStates(country.iso2);
        _states = states;
        _loadingStates = false;

        // Find matching state
        StateModel? state;
        try {
          state = states.firstWhere(
            (s) => s.name.toLowerCase() == edit.state.toLowerCase(),
          );
        } catch (_) {
          if (states.isNotEmpty) state = states.first;
        }

        if (state != null) {
          _selectedState = state;
          // 3. Load cities
          final cities = await _locationRepo.getCities(country.iso2, state.iso2);
          _cities = cities;
          _loadingCities = false;

          // Find matching city
          CityModel? city;
          try {
            city = cities.firstWhere(
              (c) => c.name.toLowerCase() == edit.city.toLowerCase(),
            );
          } catch (_) {
            if (cities.isNotEmpty) city = cities.first;
          }
          if (city != null) {
            _selectedCity = city;
          }
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
        // 1. Find and select the country
        if (res.country != null && res.country!.isNotEmpty) {
          try {
            final matchedCountry = _countries.firstWhere(
              (c) => c.name.toLowerCase() == res.country!.toLowerCase(),
              orElse: () => _countries.firstWhere((c) => c.name.toLowerCase() == 'india', orElse: () => _countries.first),
            );
            
            setState(() {
              _selectedCountry = matchedCountry;
            });
            
            // 2. Load states for this country
            await _loadStates(matchedCountry.iso2);
            
            // 3. Find and select the state
            if (res.state != null && res.state!.isNotEmpty) {
              final matchedState = _states.firstWhere(
                (s) => s.name.toLowerCase() == res.state!.toLowerCase(),
                orElse: () => _states.first,
              );
              setState(() {
                _selectedState = matchedState;
              });
              
              // 4. Load cities for this state
              await _loadCities(matchedCountry.iso2, matchedState.iso2);
              
              // 5. Find and select the city
              final matchedCity = _cities.firstWhere(
                (c) => c.name.toLowerCase() == res.city!.toLowerCase(),
                orElse: () => _cities.first,
              );
              setState(() {
                _selectedCity = matchedCity;
              });
            }
          } catch (e) {
            debugPrint('Failed to match location dropdown options: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Pincode lookup error: $e');
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select Category & Subcategory')));
        return;
      }
      if (!_formKey.currentState!.validate()) {
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedCountry == null ||
          _selectedState == null ||
          _selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please complete location selection')));
        return;
      }
      if (_latitude == null || _longitude == null || _latitude == 0.0 || _longitude == 0.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Valid map coordinates are required. Please geocode your city or select a point on the map.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }
    setState(() {
      if (_currentStep < 4) _currentStep++;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valid map coordinates are required. Please pin your business location on the map.'),
          backgroundColor: Colors.red,
        ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Business updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Business registered successfully! ID: $businessId'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        final errText = e.toString().replaceAll('Exception: ', '').replaceAll('Registration failed: ', '').replaceAll('Update failed: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errText),
            backgroundColor: Colors.redAccent,
          ),
        );
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
        iconColor: '#FF7A00',
      ));
    } catch (e) {
      debugPrint('Skipping map symbol draw: $e');
    }
  }

  Future<void> _geocodeSelectedCity() async {
    if (_selectedCity == null) return;
    // Don't override if user manually selected coordinates on map
    if (_manuallySelectedCoordinates) {
      debugPrint('Skipping geocode - user manually selected coordinates');
      return;
    }
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

      // If we reach here, geocoding returned no valid results
      setState(() {
        _latitude = null;
        _longitude = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resolve city coordinates. Please enter a valid address or locate manually on the map.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error geocoding selected city: $e');
      setState(() {
        _latitude = null;
        _longitude = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geocoding network error: $e. Please verify location details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.')),
          );
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
      }

      // Call reverse geocoding to auto-fill address
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

          // Match country, state, city dropdowns
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
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
    } catch (e) {
      debugPrint('Error searching location suggestions: $e');
    }
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
          border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
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
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Register Business',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF7A00), size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.05),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildStepper(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
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
      color: const Color(0xFF161616),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1, 'Basic'),
          _buildStepLine(2),
          _buildStepCircle(2, 'Contact'),
          _buildStepLine(3),
          _buildStepCircle(3, 'Info'),
          _buildStepLine(4),
          _buildStepCircle(4, 'Preview'),
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
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFFFF7A00).withValues(alpha: 0.15)
                : isActive
                    ? const Color(0xFFFF7A00)
                    : const Color(0xFF262626),
            border: Border.all(
              color: isPassed ? const Color(0xFFFF7A00) : Colors.white10,
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Color(0xFFFF7A00),
                    size: 16,
                  )
                : Text(
                    step.toString(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isActive ? Colors.black : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isPassed ? const Color(0xFFFF7A00) : Colors.white38,
            fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int toStep) {
    final isHighlighted = _currentStep >= toStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      color: isHighlighted ? const Color(0xFFFF7A00) : Colors.white10,
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
      default:
        return const SizedBox();
    }
  }
  Widget _buildStep1() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information',
            style: TextStyle(
                color: Color(0xFFFF7A00),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        categoriesAsync.when(
          data: (categories) => DropdownButtonFormField<int>(
            dropdownColor: const Color(0xFF1E1E1E),
            initialValue: categories.any((cat) => cat.categoryId == _selectedCategoryId) ? _selectedCategoryId : null,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Select Category', Icons.category),
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
          loading: () => const LinearProgressIndicator(color: Color(0xFFFF7A00)),
          error: (err, st) => const Text('Error loading categories',
              style: TextStyle(color: Colors.redAccent)),
        ),
        const SizedBox(height: 15),
        if (_selectedCategoryId != null)
          ref.watch(subcategoriesProvider(_selectedCategoryId!)).when(
                data: (subcategories) => DropdownButtonFormField<int>(
                  dropdownColor: const Color(0xFF1E1E1E),
                  initialValue: subcategories.any((sub) => sub.subcategoryId == _selectedSubcategoryId) ? _selectedSubcategoryId : null,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _inputDecoration('Select Subcategory', Icons.layers),
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
                loading: () =>
                    const LinearProgressIndicator(color: Color(0xFFFF7A00)),
                error: (err, st) => const Text('Error loading subcategories',
                    style: TextStyle(color: Colors.redAccent)),
              ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Business Name', Icons.business),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Business Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _descController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: _inputDecoration('Description', Icons.description),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _generateAIDescription,
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFFF7A00), size: 16),
            label: const Text(
              'AI Generate Description',
              style: TextStyle(color: Color(0xFFFF7A00), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAIDescription() async {
    final keywordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final generated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFF7A00)),
            SizedBox(width: 10),
            Text('AI Description Generator', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a few keywords describing your business (e.g. coffee, cozy, vegan, free wifi):',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: keywordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter keywords separated by commas...',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Keywords are required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A00)),
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                // Show local loading spinner
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
                  ),
                );
                
                try {
                  final keywords = keywordController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  // Get active category name
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: const Text('Generate', style: TextStyle(color: Colors.black)),
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
        const Text('Contact & Location Details',
            style: TextStyle(
                color: Color(0xFFFF7A00),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        // 1. Phone Number (with Country Code)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: DropdownButtonFormField<String>(
                value: _selectedPhoneCode,
                decoration: _inputDecoration('', Icons.add),
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                items: _phoneCountryItems
                    .map(
                      (pc) => DropdownMenuItem(
                        value: pc['code'],
                        child: Text(
                          '${pc['flag']} +${pc['code']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPhoneCode = val);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Phone Number', Icons.phone),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (_selectedPhoneCode == '91') {
                    if (!RegExp(r'^[3-9][0-9]{9}$').hasMatch(value.trim())) {
                      return 'Invalid Indian number';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // 2. Email Address
        TextFormField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('Email Address', Icons.email),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email address is required';
            }
            if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
              return 'Invalid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // 3. Website URL
        TextFormField(
          controller: _websiteController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.url,
          decoration: _inputDecoration('Website URL', Icons.language),
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              if (!RegExp(r'^(https?:\/\/)?(www\.)?[a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$').hasMatch(value.trim())) {
                return 'Invalid website URL';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // 4. Search Location (Autocomplete search field + suggestions list)
        const Text(
          'Search Location',
          style: TextStyle(
            color: Color(0xFFFF7A00),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _locationSearchController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Search Address or Place...', Icons.search).copyWith(
            suffixIcon: _locationSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _locationSearchController.clear();
                      setState(() {
                        _locationSuggestions = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            _searchLocation(val);
          },
        ),
        if (_locationSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5, bottom: 15),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _locationSuggestions.length,
              itemBuilder: (context, idx) {
                final item = _locationSuggestions[idx];
                final formattedAddress = item['formatted'] as String? ?? '';
                return ListTile(
                  title: Text(
                    formattedAddress,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onTap: () async {
                    final lat = item['lat'] as double?;
                    final lon = item['lon'] as double?;
                    if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
                      setState(() {
                        _latitude = lat;
                        _longitude = lon;
                        _locationSuggestions = [];
                        _locationSearchController.text = formattedAddress;
                        _manuallySelectedCoordinates = true;
                        _userInteractedWithMap = false;
                      });
                      final pos = LatLng(lat, lon);
                      if (_mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 15)),
                        );
                      }
                      _addMarker(pos);
                      
                      // Auto-fill fields from the selected recommendation
                      final countryName = item['country'] as String?;
                      final stateName = item['state'] as String?;
                      final cityName = item['city'] as String? ?? item['town'] as String? ?? item['village'] as String?;
                      final postcode = item['postcode'] as String?;
                      final street = item['street'] as String?;
                      final housenumber = item['housenumber'] as String?;

                      String address = '';
                      if (housenumber != null) address += '$housenumber ';
                      if (street != null) address += street;
                      if (address.isEmpty && item['name'] != null) {
                        address = item['name'] as String;
                      }

                      setState(() {
                        if (address.isNotEmpty) {
                          _addressController.text = address;
                        }
                        if (postcode != null) {
                          _pincodeController.text = postcode;
                        }
                      });

                      // cascading update dropdown selections
                      if (countryName != null) {
                        final matchedCountry = _countries.firstWhere(
                          (c) => c.name.toLowerCase() == countryName.toLowerCase(),
                          orElse: () => _countries.first,
                        );
                        setState(() => _selectedCountry = matchedCountry);
                        await _loadStates(matchedCountry.iso2);

                        if (stateName != null && _states.isNotEmpty) {
                          final cleanState = stateName.replaceAll('State of ', '').replaceAll(' Union Territory', '').trim().toLowerCase();
                          final matchedState = _states.firstWhere(
                            (s) => s.name.toLowerCase().contains(cleanState) || cleanState.contains(s.name.toLowerCase()),
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
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 25),

        // 5. Country
        _loadingCountries
            ? const LinearProgressIndicator(color: Color(0xFFFF7A00))
            : DropdownButtonFormField<Country>(
                dropdownColor: const Color(0xFF1E1E1E),
                value: _selectedCountry,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Country', Icons.public),
                items: _countries.map((Country country) {
                  return DropdownMenuItem<Country>(
                    value: country,
                    child: Text(country.name),
                  );
                }).toList(),
                onChanged: (Country? newValue) {
                  setState(() {
                    _selectedCountry = newValue;
                    if (newValue != null) {
                      _loadStates(newValue.iso2);
                    }
                  });
                },
              ),
        const SizedBox(height: 15),

        // 6. State
        if (_selectedCountry != null)
          _loadingStates
              ? const LinearProgressIndicator(color: Color(0xFFFF7A00))
              : DropdownButtonFormField<StateModel>(
                  dropdownColor: const Color(0xFF1E1E1E),
                  value: _selectedState,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('State', Icons.map),
                  items: _states.map((StateModel state) {
                    return DropdownMenuItem<StateModel>(
                      value: state,
                      child: Text(state.name),
                    );
                  }).toList(),
                  onChanged: (StateModel? newValue) {
                    setState(() {
                      _selectedState = newValue;
                      if (newValue != null && _selectedCountry != null) {
                        _loadCities(_selectedCountry!.iso2, newValue.iso2);
                      }
                    });
                  },
                ),
        const SizedBox(height: 15),

        // 7. City
        if (_selectedState != null)
          _loadingCities
              ? const LinearProgressIndicator(color: Color(0xFFFF7A00))
              : DropdownButtonFormField<CityModel>(
                  dropdownColor: const Color(0xFF1E1E1E),
                  value: _selectedCity,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('City', Icons.location_city),
                  items: _cities.map((CityModel city) {
                    return DropdownMenuItem<CityModel>(
                      value: city,
                      child: Text(city.name),
                    );
                  }).toList(),
                  onChanged: (CityModel? newValue) {
                    setState(() {
                      _selectedCity = newValue;
                      // Reset manual selection flag when city changes
                      _manuallySelectedCoordinates = false;
                    });
                    if (newValue != null) {
                      _geocodeSelectedCity();
                    }
                  },
                ),
        const SizedBox(height: 15),

        // 8. Street Address
        TextFormField(
          controller: _addressController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Street Address', Icons.location_on),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Street address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // 9. Pincode
        TextFormField(
          controller: _pincodeController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('Pincode', Icons.pin_drop),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pincode is required';
            }
            if (!RegExp(r'^[A-Za-z0-9\-\s]{3,10}$').hasMatch(value.trim())) {
              return 'Invalid pincode format';
            }
            return null;
          },
        ),
        const SizedBox(height: 25),

        // 10. Map Interaction Area
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pin Location on Map',
              style: TextStyle(
                color: Color(0xFFFF7A00),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location, color: Color(0xFFFF7A00), size: 18),
              label: const Text(
                'Use GPS',
                style: TextStyle(color: Color(0xFFFF7A00), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_latitude == null || _longitude == null || _latitude == 0.0 || _longitude == 0.0)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.businessToEdit != null
                        ? 'Location coordinates are missing in database. You must select a location on the map before saving.'
                        : 'Location coordinates are unselected. Geocode your city or pick a spot on the map.',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Listener(
                onPointerDown: (_) {
                  setState(() {
                    _userInteractedWithMap = true;
                  });
                },
                child: MapLibreMap(
                  styleString: osmStyle,
                  initialCameraPosition: CameraPosition(
                      target: (_latitude != null && _longitude != null && _latitude != 0.0 && _longitude != 0.0)
                          ? LatLng(_latitude!, _longitude!)
                          : const LatLng(17.385, 78.4867),
                      zoom: (_latitude != null && _longitude != null && _latitude != 0.0 && _longitude != 0.0) ? 12 : 5),
                  onMapCreated: _onMapCreated,
                  onMapClick: _onMapClick,
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  doubleClickZoomEnabled: true,
                  myLocationEnabled: true,
                  onCameraIdle: () {
                    if (_mapController != null && _mapInitialized) {
                      if (_userInteractedWithMap) {
                        final target = _mapController!.cameraPosition?.target;
                        if (target != null && target.latitude != 0.0 && target.longitude != 0.0) {
                          setState(() {
                            _latitude = target.latitude;
                            _longitude = target.longitude;
                          });
                          _addMarker(target);
                        }
                      }
                    }
                  },
                ),
              ),
              IgnorePointer(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 30), // Account for pin base point alignment
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFFF7A00),
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Information',
            style: TextStyle(
                color: Color(0xFFFF7A00),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        const Text('Business Photo / Logo',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedPhotoLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Will be uploaded as primary business cover',
                            style: TextStyle(color: Colors.white30, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate, color: Color(0xFFFF7A00), size: 28),
                    onPressed: _pickImage,
                    tooltip: 'Upload Photo from Library',
                  ),
                ],
              ),
              if (_photoBase64 != null) ...[
                const SizedBox(height: 15),
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.3)),
                    image: DecorationImage(
                      image: MemoryImage(base64Decode(_photoBase64!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ] else if (widget.businessToEdit != null &&
                  widget.businessToEdit!.photos.isNotEmpty) ...[
                const SizedBox(height: 15),
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                    image: DecorationImage(
                      image: NetworkImage('${Uri.parse(DioClient().dio.options.baseUrl).origin}${widget.businessToEdit!.photos.first}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Business Hours',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            Row(
              children: [
                _buildPresetChip('Mon-Fri', () {
                  setState(() {
                    for (int i = 0; i < _businessHours.length; i++) {
                      final dayName = _businessHours[i].day.toLowerCase();
                      final isWeekend = dayName == 'saturday' || dayName == 'sunday';
                      _businessHours[i] = DayHoursDto(
                        day: _businessHours[i].day,
                        mode: isWeekend ? 'Closed' : 'Open',
                        slots: isWeekend ? [] : [SlotDto(open: '09:00', close: '18:00')],
                      );
                    }
                  });
                }),
                const SizedBox(width: 8),
                _buildPresetChip('Mon-Sun', () {
                  setState(() {
                    for (int i = 0; i < _businessHours.length; i++) {
                      _businessHours[i] = DayHoursDto(
                        day: _businessHours[i].day,
                        mode: 'Open',
                        slots: [SlotDto(open: '09:00', close: '18:00')],
                      );
                    }
                  });
                }),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _businessHours.length,
          itemBuilder: (context, index) {
            final day = _businessHours[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(day.day,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      if (day.mode == 'Open') ...[
                        TextButton(
                          onPressed: () async {
                            final initialTime = day.slots.isNotEmpty 
                                ? _parseTimeOfDay(day.slots.first.open) 
                                : const TimeOfDay(hour: 9, minute: 0);
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );
                            if (picked != null) {
                              final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              setState(() {
                                final currentSlots = List<SlotDto>.from(day.slots);
                                if (currentSlots.isEmpty) {
                                  currentSlots.add(SlotDto(open: timeStr, close: '18:00'));
                                } else {
                                  currentSlots[0] = SlotDto(open: timeStr, close: currentSlots[0].close);
                                }
                                _businessHours[index] = DayHoursDto(
                                  day: day.day,
                                  mode: 'Open',
                                  slots: currentSlots,
                                );
                              });
                            }
                          },
                          child: Text(
                            day.slots.isNotEmpty ? day.slots.first.open : '09:00',
                            style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text('to', style: TextStyle(color: Colors.white30, fontSize: 12)),
                        TextButton(
                          onPressed: () async {
                            final initialTime = day.slots.isNotEmpty 
                                ? _parseTimeOfDay(day.slots.first.close) 
                                : const TimeOfDay(hour: 18, minute: 0);
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );
                            if (picked != null) {
                              final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              setState(() {
                                final currentSlots = List<SlotDto>.from(day.slots);
                                if (currentSlots.isEmpty) {
                                  currentSlots.add(SlotDto(open: '09:00', close: timeStr));
                                } else {
                                  currentSlots[0] = SlotDto(open: currentSlots[0].open, close: timeStr);
                                }
                                _businessHours[index] = DayHoursDto(
                                  day: day.day,
                                  mode: 'Open',
                                  slots: currentSlots,
                                );
                              });
                            }
                          },
                          child: Text(
                            day.slots.isNotEmpty ? day.slots.first.close : '18:00',
                            style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        const Text('Closed', style: TextStyle(color: Colors.red, fontSize: 13)),
                        const SizedBox(width: 10),
                      ],
                      Switch(
                        value: day.mode == 'Open',
                        activeTrackColor: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                        activeThumbColor: const Color(0xFFFF7A00),
                        onChanged: (val) {
                          setState(() {
                            _businessHours[index] = DayHoursDto(
                              day: day.day,
                              mode: val ? 'Open' : 'Closed',
                              slots: val ? [SlotDto(open: '09:00', close: '18:00')] : [],
                            );
                          });
                        },
                      )
                    ],
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review & Submit',
            style: TextStyle(
                color: Color(0xFFFF7A00),
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildPreviewItem('Business Name', _nameController.text),
        _buildPreviewItem('Description', _descController.text),
        _buildPreviewItem('Phone', '+$_selectedPhoneCode ${_phoneController.text}'),
        _buildPreviewItem('Email', _emailController.text),
        _buildPreviewItem('Location',
            '${_selectedCity?.name}, ${_selectedState?.name}, ${_selectedCountry?.name}'),
        _buildPreviewItem('Coordinates', 'Lat: ${_latitude?.toStringAsFixed(4) ?? "N/A"}, Lng: ${_longitude?.toStringAsFixed(4) ?? "N/A"}'),
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1E1E1E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 1)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Back',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            )
          else
            const SizedBox(width: 80),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _currentStep == 4 ? _submitForm : _nextStep,
            child: Text(
              _currentStep == 4 ? 'Submit' : 'Next',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFFFF7A00), size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF7A00)),
      ),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
    );
  }
}
