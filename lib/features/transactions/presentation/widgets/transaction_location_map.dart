import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget pour afficher la localisation d'une transaction sur une carte OpenStreetMap
class TransactionLocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;

  const TransactionLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 20, color: AppColors.darkTextSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Localisation',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address ?? '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.flut_budget',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude, longitude),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.expense,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

