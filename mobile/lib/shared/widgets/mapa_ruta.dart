import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/viaje.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formato.dart';
import 'section_card.dart';

const _centroNicaragua = LatLng(12.4, -85.0);

List<ParadaRuta> _paradasConCoordenadas(List<ParadaRuta> paradas) {
  return paradas.where((p) => p.latitud != null && p.longitud != null).toList();
}

String urlGoogleMapsCoordenadas(List<ParadaRuta> paradas) {
  final puntos = _paradasConCoordenadas(paradas);
  if (puntos.isEmpty) return 'https://www.google.com/maps';
  final segmentos = puntos.map((p) => '${p.latitud},${p.longitud}').join('/');
  return 'https://www.google.com/maps/dir/$segmentos';
}

class ParadasTimeline extends StatelessWidget {
  const ParadasTimeline({super.key, required this.paradas});

  final List<ParadaRuta> paradas;

  @override
  Widget build(BuildContext context) {
    if (paradas.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < paradas.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.place,
              size: 20,
              color: i == 0
                  ? AppColors.primary
                  : i == paradas.length - 1
                      ? Colors.red.shade700
                      : Colors.grey.shade600,
            ),
            title: Text('${paradas[i].orden}. ${paradas[i].nombre}'),
            subtitle: _buildSubtitle(paradas[i]),
          ),
      ],
    );
  }

  Widget? _buildSubtitle(ParadaRuta p) {
    final parts = <String>[];
    if (p.latitud != null && p.longitud != null) {
      parts.add('GPS: ${p.latitud!.toStringAsFixed(4)}, ${p.longitud!.toStringAsFixed(4)}');
    }
    if (p.horaEstimada != null) {
      parts.add('Llegada estimada: ${formatearHora(p.horaEstimada!)}');
    }
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }
}

class MapaParadas extends StatelessWidget {
  const MapaParadas({super.key, required this.paradas, this.height = 360});

  final List<ParadaRuta> paradas;
  final double height;

  @override
  Widget build(BuildContext context) {
    final puntos = _paradasConCoordenadas(paradas);
    final latLngs = puntos.map((p) => LatLng(p.latitud!, p.longitud!)).toList();

    LatLng center = _centroNicaragua;
    double zoom = 7;
    if (latLngs.isNotEmpty) {
      var minLat = latLngs.first.latitude;
      var maxLat = latLngs.first.latitude;
      var minLng = latLngs.first.longitude;
      var maxLng = latLngs.first.longitude;
      for (final ll in latLngs) {
        if (ll.latitude < minLat) minLat = ll.latitude;
        if (ll.latitude > maxLat) maxLat = ll.latitude;
        if (ll.longitude < minLng) minLng = ll.longitude;
        if (ll.longitude > maxLng) maxLng = ll.longitude;
      }
      center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      final latSpan = (maxLat - minLat).abs();
      final lngSpan = (maxLng - minLng).abs();
      final span = latSpan > lngSpan ? latSpan : lngSpan;
      if (span < 0.05) {
        zoom = 12;
      } else if (span < 0.2) {
        zoom = 10;
      } else if (span < 1) {
        zoom = 8;
      } else {
        zoom = 7;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'transporte_mobile',
            ),
            if (latLngs.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: latLngs,
                    color: AppColors.secondary,
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < puntos.length; i++)
                  Marker(
                    point: LatLng(puntos[i].latitud!, puntos[i].longitud!),
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.location_on,
                      color: i == 0
                          ? AppColors.primary
                          : i == puntos.length - 1
                              ? Colors.red.shade700
                              : AppColors.secondary,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MapaRuta extends StatelessWidget {
  const MapaRuta({
    super.key,
    required this.paradas,
    this.origen,
    this.destino,
  });

  final List<ParadaRuta> paradas;
  final String? origen;
  final String? destino;

  Future<void> _abrirGoogleMaps() async {
    final url = Uri.parse(urlGoogleMapsCoordenadas(paradas));
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (paradas.isEmpty) return const SizedBox.shrink();

    final tituloRuta = origen != null && destino != null ? '$origen → $destino' : 'en mapa';

    return SectionCard(
      title: 'Ruta $tituloRuta',
      actions: OutlinedButton.icon(
        onPressed: _abrirGoogleMaps,
        icon: const Icon(Icons.map, size: 18),
        label: const Text('Google Maps'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ParadasTimeline(paradas: paradas),
          const SizedBox(height: 16),
          MapaParadas(paradas: paradas),
          const SizedBox(height: 8),
          Text(
            'Marcadores: salida, paradas intermedias y llegada con coordenadas GPS reales. '
            'Horarios estimados según salida programada.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
