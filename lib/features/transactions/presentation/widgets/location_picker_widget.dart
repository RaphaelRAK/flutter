import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/location_picker_screen.dart';

/// Widget pour sélectionner la localisation d'une transaction
class LocationPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double? latitude, double? longitude, String? address)? onLocationSelected;

  const LocationPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.onLocationSelected,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  double? _latitude;
  double? _longitude;
  String? _address;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _address = widget.initialAddress;
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<Map<String, dynamic?>>(
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialAddress: _address,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'] as double?;
        _longitude = result['longitude'] as double?;
        _address = result['address'] as String?;
      });

      if (widget.onLocationSelected != null) {
        widget.onLocationSelected!(_latitude, _longitude, _address);
      }
    }
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _address = null;
    });

    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(null, null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _latitude != null && _longitude != null;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Localisation'),
            subtitle: hasLocation
                ? Text(
                    _address ?? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text('Aucune localisation'),
            trailing: hasLocation
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearLocation,
                    tooltip: 'Supprimer la localisation',
                  )
                : null,
          ),
          // Aperçu de la localisation si sélectionnée
          if (hasLocation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkTextSecondary.withOpacity(0.2)),
                  color: Colors.grey[100],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openLocationPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                color: AppColors.expense,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  _address ?? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.darkTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Appuyez pour modifier',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.darkTextSecondary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.expense,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Bouton pour ouvrir la carte
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.map),
                label: Text(hasLocation ? 'Modifier sur la carte' : 'Sélectionner sur la carte'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
