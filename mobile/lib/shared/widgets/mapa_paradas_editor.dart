import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/viaje.dart';
import '../../core/theme/app_colors.dart';

/// Mapa interactivo de paradas con marcadores seleccionables.
class MapaParadasEditor extends StatelessWidget {
  const MapaParadasEditor({
    super.key,
    required this.paradas,
    this.height = 420,
    this.selectedId,
    this.onMapTap,
    this.onMarkerTap,
  });

  final List<ParadaRuta> paradas;
  final double height;
  final int? selectedId;
  final void Function(double lat, double lng)? onMapTap;
  final ValueChanged<int>? onMarkerTap;

  static const _defaultCenter = LatLng(12.5, -84.5);

  LatLng _center() {
    final conCoords = paradas.where((p) => p.latitud != null && p.longitud != null).toList();
    if (conCoords.isEmpty) return _defaultCenter;
    final lat = conCoords.map((p) => p.latitud!).reduce((a, b) => a + b) / conCoords.length;
    final lng = conCoords.map((p) => p.longitud!).reduce((a, b) => a + b) / conCoords.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final center = _center();
    final markers = paradas
        .where((p) => p.latitud != null && p.longitud != null)
        .map(
          (p) => Marker(
            point: LatLng(p.latitud!, p.longitud!),
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () => onMarkerTap?.call(p.id),
              child: Container(
                decoration: BoxDecoration(
                  color: selectedId == p.id ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${p.orden}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: selectedId == p.id ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();

    if (markers.length >= 2) {
      final polyline = Polyline(
        points: paradas
            .where((p) => p.latitud != null && p.longitud != null)
            .map((p) => LatLng(p.latitud!, p.longitud!))
            .toList(),
        color: AppColors.primary,
        strokeWidth: 3,
      );
      return SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 7.5,
              onTap: (_, point) => onMapTap?.call(point.latitude, point.longitude),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.transporte.mobile',
              ),
              PolylineLayer(polylines: [polyline]),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 7.5,
            onTap: (_, point) => onMapTap?.call(point.latitude, point.longitude),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.transporte.mobile',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
