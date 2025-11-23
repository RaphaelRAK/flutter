import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';

/// Résultat de recherche d'adresse
class AddressSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? address;

  AddressSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

/// Écran pour sélectionner une localisation sur une carte interactive
class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddress;
  bool _isSearching = false;
  List<AddressSearchResult> _searchResults = [];
  List<Marker> _markers = [];
  double _currentZoom = 15.0;
  LatLng _currentCenter = const LatLng(48.8566, 2.3522); // Paris par défaut
  DateTime? _lastSearchTime;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _selectedAddress = widget.initialAddress;
    _searchController.text = widget.initialAddress ?? '';

    if (_selectedLatitude != null && _selectedLongitude != null) {
      // On a déjà une localisation initiale, l'utiliser
      _currentCenter = LatLng(_selectedLatitude!, _selectedLongitude!);
      _addMarker(_selectedLatitude!, _selectedLongitude!, _selectedAddress);
      // Centrer la carte sur la position initiale
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_currentCenter, _currentZoom);
        // Si on n'a pas d'adresse mais qu'on a les coordonnées, essayer de récupérer l'adresse
        if (_selectedAddress == null || _selectedAddress!.isEmpty) {
          _getAddressFromCoordinates(_selectedLatitude!, _selectedLongitude!).catchError((e) {
            // Ignorer silencieusement
          });
        }
      });
    } else {
      // Pas de localisation initiale, essayer d'obtenir la position actuelle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les services de localisation sont désactivés.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_currentCenter, _currentZoom);
      
      // Ajouter un marqueur sur la position actuelle
      _addMarker(position.latitude, position.longitude, null);
      
      // Mettre à jour la sélection
      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });
      
      // Essayer d'obtenir l'adresse (sans afficher d'erreur si ça échoue)
      _getAddressFromCoordinates(position.latitude, position.longitude).catchError((e) {
        // Ignorer silencieusement les erreurs de géocodage inverse
      });
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Respecter le rate limiting de Nominatim (1 requête par seconde)
    if (_lastSearchTime != null) {
      final timeSinceLastSearch = DateTime.now().difference(_lastSearchTime!);
      if (timeSinceLastSearch.inMilliseconds < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - timeSinceLastSearch.inMilliseconds));
      }
    }

    setState(() {
      _isSearching = true;
    });
    
    _lastSearchTime = DateTime.now();

    try {
      // Utiliser le service de géocodage de Nominatim (OpenStreetMap)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=10&addressdetails=1',
      );

      final client = HttpClient();
      try {
        final request = await client.getUrl(url);
        // User-Agent requis par Nominatim pour éviter le rate limiting
        request.headers.add('User-Agent', 'FlutBudget/1.0 (contact@example.com)');
        request.headers.add('Accept', 'application/json');
        
        // Timeout de 10 secondes
        final response = await request.close().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout: La requête a pris trop de temps');
          },
        );
        
        // Vérifier le code de statut
        if (response.statusCode != 200) {
          throw Exception('Erreur HTTP ${response.statusCode}');
        }
        
        final responseBody = await response.transform(utf8.decoder).join();
        
        // Vérifier si la réponse est du JSON (et non du HTML)
        if (responseBody.trim().startsWith('<')) {
          throw Exception('Réponse HTML reçue au lieu de JSON. Veuillez réessayer dans quelques instants.');
        }
        
        final data = jsonDecode(responseBody) as List<dynamic>;

        final results = <AddressSearchResult>[];
        for (final item in data) {
          final map = item as Map<String, dynamic>;
          results.add(AddressSearchResult(
            displayName: map['display_name'] as String? ?? '',
            latitude: double.parse(map['lat'] as String),
            longitude: double.parse(map['lon'] as String),
            address: map['display_name'] as String?,
          ));
        }

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        // Afficher les résultats sur la carte
        _displaySearchResultsOnMap(results);
      } finally {
        client.close();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur lors de la recherche';
        if (e.toString().contains('HTML')) {
          errorMessage = 'Trop de requêtes. Veuillez patienter quelques secondes avant de réessayer.';
        } else if (e.toString().contains('Timeout') || e.toString().contains('timeout')) {
          errorMessage = 'La requête a pris trop de temps. Vérifiez votre connexion internet.';
        } else if (e.toString().contains('HTTP') || e.toString().contains('SocketException') || e.toString().contains('connection')) {
          errorMessage = 'Erreur de connexion. Vérifiez votre connexion internet et réessayez.';
        } else {
          errorMessage = 'Erreur: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _searchAddress(_searchController.text);
                }
              },
            ),
          ),
        );
      }
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _displaySearchResultsOnMap(List<AddressSearchResult> results) {
    if (results.isEmpty) return;

    final markers = <Marker>[];
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      markers.add(
        Marker(
          point: LatLng(result.latitude, result.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _selectSearchResult(result),
            child: Container(
              decoration: BoxDecoration(
                color: i == 0 ? AppColors.expense : AppColors.accentSecondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                i == 0 ? Icons.location_on : Icons.place,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });

    // Centrer la carte sur le premier résultat
    if (results.isNotEmpty) {
      final firstResult = results.first;
      _currentCenter = LatLng(firstResult.latitude, firstResult.longitude);
      _mapController.move(_currentCenter, _currentZoom);
    }
  }

  void _selectSearchResult(AddressSearchResult result) {
    setState(() {
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
      _selectedAddress = result.address ?? result.displayName;
      _searchController.text = result.displayName;
      _searchResults = [];
    });

    _addMarker(result.latitude, result.longitude, _selectedAddress);
    _currentCenter = LatLng(result.latitude, result.longitude);
    _mapController.move(_currentCenter, _currentZoom);
  }

  void _addMarker(double lat, double lon, String? address) {
    setState(() {
      _markers = [
        Marker(
          point: LatLng(lat, lon),
          width: 50,
          height: 50,
          child: Icon(
            Icons.location_on,
            color: AppColors.expense,
            size: 50,
          ),
        ),
      ];
    });
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );

      final client = HttpClient();
      try {
        final request = await client.getUrl(url);
        request.headers.add('User-Agent', 'FlutBudget/1.0 (contact@example.com)');
        request.headers.add('Accept', 'application/json');
        
        // Timeout de 5 secondes (plus court pour éviter les attentes)
        final response = await request.close().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Timeout');
          },
        );
        
        if (response.statusCode != 200) {
          return;
        }
        
        final responseBody = await response.transform(utf8.decoder).join();
        
        // Vérifier si la réponse est du JSON
        if (responseBody.trim().startsWith('<')) {
          return;
        }
        
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        
        if (data.containsKey('display_name')) {
          setState(() {
            _selectedAddress = data['display_name'] as String?;
            if (_selectedLatitude == null || _selectedLongitude == null) {
              _selectedLatitude = lat;
              _selectedLongitude = lon;
            }
            if (_selectedAddress != null && _searchController.text.isEmpty) {
              _searchController.text = _selectedAddress!;
            }
          });
        }
      } finally {
        client.close();
      }
    } catch (e) {
      // Ignorer silencieusement les erreurs de géocodage inverse
      // On garde les coordonnées même si on n'a pas l'adresse
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLatitude = point.latitude;
      _selectedLongitude = point.longitude;
    });
    _addMarker(point.latitude, point.longitude, null);
    // Essayer d'obtenir l'adresse (sans afficher d'erreur si ça échoue)
    _getAddressFromCoordinates(point.latitude, point.longitude).catchError((e) {
      // Ignorer silencieusement les erreurs de géocodage inverse
    });
  }

  void _confirmSelection() {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      Navigator.of(context).pop({
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner une localisation'),
      ),
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flut_budget',
                maxZoom: 19,
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          // Barre de recherche en haut
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Rechercher un lieu',
                      hintText: 'Ex: Carrefour, Restaurant, Paris...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _markers = [];
                                    });
                                  },
                                )
                              : null,
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text == value && value.isNotEmpty) {
                          _searchAddress(value);
                        }
                      });
                    },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _searchAddress(value);
                      }
                    },
                  ),
                  // Résultats de recherche
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: Icon(
                              index == 0 ? Icons.location_on : Icons.place,
                              color: index == 0 ? AppColors.expense : AppColors.darkTextSecondary,
                            ),
                            title: Text(
                              result.displayName,
                              style: TextStyle(
                                fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              _selectSearchResult(result);
                              _searchFocusNode.unfocus();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Bouton position actuelle en bas à droite (au-dessus du panneau de validation)
          Positioned(
            bottom: (_selectedLatitude != null && _selectedLongitude != null) ? 120 : 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.my_location),
            ),
          ),
          // Adresse sélectionnée et bouton de validation en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedAddress != null || (_selectedLatitude != null && _selectedLongitude != null))
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedAddress != null)
                          Row(
                            children: [
                              Icon(Icons.location_on, color: AppColors.expense),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedAddress!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (_selectedLatitude != null && _selectedLongitude != null)
                          Padding(
                            padding: EdgeInsets.only(top: _selectedAddress != null ? 4 : 0),
                            child: Text(
                              '${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  // Bouton de validation
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedLatitude != null && _selectedLongitude != null)
                          ? _confirmSelection
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Valider cette localisation'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.expense,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (_selectedLatitude == null || _selectedLongitude == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Cliquez sur la carte ou recherchez un lieu pour sélectionner une localisation',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

