import 'package:flutter/material.dart';

import '../models/viaje.dart';
import '../theme/app_colors.dart';
import '../utils/formato.dart';

const _seatColors = {
  'DISPONIBLE': AppColors.seatDisponible,
  'VENDIDO': AppColors.seatVendido,
  'CANCELADO': AppColors.seatCancelado,
  'RESERVADO_EXCEPCIONAL': AppColors.seatReservado,
};

Color colorAsiento(AsientoViaje asiento) {
  return _seatColors[asiento.estado] ?? AppColors.seatCancelado;
}

List<List<AsientoViaje>> _agruparPares(List<AsientoViaje> asientos) {
  final cabina = asientos.where((a) => !a.posicion.startsWith('TRASERA')).toList()
    ..sort((a, b) => a.numero.compareTo(b.numero));
  final pares = <List<AsientoViaje>>[];
  for (var i = 0; i < cabina.length; i += 2) {
    pares.add(i + 1 < cabina.length ? [cabina[i], cabina[i + 1]] : [cabina[i]]);
  }
  return pares;
}

List<AsientoViaje> _asientosTrasera(List<AsientoViaje> asientos) {
  return asientos.where((a) => a.posicion.startsWith('TRASERA')).toList()
    ..sort((a, b) => a.numero.compareTo(b.numero));
}

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _seatColors.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: e.value.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: e.value.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: e.value, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                etiquetaEstadoAsiento(e.key),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: e.value.withValues(alpha: 0.95)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class SeatGrid extends StatelessWidget {
  const SeatGrid({
    super.key,
    required this.asientos,
    this.busNumeroInterno,
    this.seleccionados = const [],
    this.modoSeleccion = false,
    this.onToggle,
  });

  final List<AsientoViaje> asientos;
  final String? busNumeroInterno;
  final List<int> seleccionados;
  final bool modoSeleccion;
  final void Function(int viajeAsientoId)? onToggle;

  @override
  Widget build(BuildContext context) {
    final pares = _agruparPares(asientos);
    final trasera = _asientosTrasera(asientos);
    final filas = <({List<AsientoViaje>? izq, List<AsientoViaje>? der})>[];
    for (var i = 0; i < pares.length; i += 2) {
      filas.add((izq: pares[i], der: i + 1 < pares.length ? pares[i + 1] : null));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SeatLegend(),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: const [AppColors.cardShadow],
          ),
          child: Column(
            children: [
              _YutongCabina(
                total: asientos.length,
                busNumeroInterno: busNumeroInterno,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _ColumnLabel('IZQUIERDA', alignment: Alignment.centerLeft)),
                        const SizedBox(width: 36),
                        Expanded(child: _ColumnLabel('DERECHA', alignment: Alignment.centerRight)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...filas.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: f.izq != null
                                    ? _BloquePar(
                                        par: f.izq!,
                                        seleccionados: seleccionados,
                                        modoSeleccion: modoSeleccion,
                                        onToggle: onToggle,
                                      )
                                    : const SizedBox(),
                              ),
                              _Pasillo(),
                              Expanded(
                                child: f.der != null
                                    ? _BloquePar(
                                        par: f.der!,
                                        seleccionados: seleccionados,
                                        modoSeleccion: modoSeleccion,
                                        onToggle: onToggle,
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        )),
                    if (trasera.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'FILA TRASERA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey.shade600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _BloquePar(
                        par: trasera,
                        fullWidth: true,
                        seleccionados: seleccionados,
                        modoSeleccion: modoSeleccion,
                        onToggle: onToggle,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Icon(Icons.arrow_upward, size: 16, color: Colors.blueGrey.shade400),
                    Text(
                      'FRENTE DEL BUS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade500),
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
}

class _ColumnLabel extends StatelessWidget {
  const _ColumnLabel(this.text, {required this.alignment});

  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade500, letterSpacing: 0.5),
      ),
    );
  }
}

class _Pasillo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              width: 2,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

class _BloquePar extends StatelessWidget {
  const _BloquePar({
    required this.par,
    this.fullWidth = false,
    this.seleccionados = const [],
    this.modoSeleccion = false,
    this.onToggle,
  });

  final List<AsientoViaje> par;
  final bool fullWidth;
  final List<int> seleccionados;
  final bool modoSeleccion;
  final void Function(int viajeAsientoId)? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.seatDisponible.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.seatDisponible.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          for (var i = 0; i < par.length; i++) ...[
            if (i > 0) Container(width: 1, height: 44, color: AppColors.seatDisponible.withValues(alpha: 0.25)),
            Expanded(
              child: _SeatTile(
                asiento: par[i],
                seleccionado: seleccionados.contains(par[i].viajeAsientoId),
                modoSeleccion: modoSeleccion,
                onToggle: onToggle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.asiento,
    this.seleccionado = false,
    this.modoSeleccion = false,
    this.onToggle,
  });

  final AsientoViaje asiento;
  final bool seleccionado;
  final bool modoSeleccion;
  final void Function(int viajeAsientoId)? onToggle;

  @override
  Widget build(BuildContext context) {
    final puedeTap = modoSeleccion && asiento.estado == 'DISPONIBLE' && onToggle != null;
    var fill = colorAsiento(asiento);
    if (seleccionado) fill = AppColors.primary;

    return GestureDetector(
      onTap: puedeTap ? () => onToggle!(asiento.viajeAsientoId) : null,
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: seleccionado ? Border.all(color: AppColors.primaryDark, width: 2.5) : null,
          boxShadow: [
            BoxShadow(color: fill.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${asiento.numero}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, height: 1),
            ),
            const SizedBox(height: 2),
            Text(
              asiento.esVentana ? 'V' : 'P',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YutongCabina extends StatelessWidget {
  const _YutongCabina({required this.total, this.busNumeroInterno});

  final int total;
  final String? busNumeroInterno;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yutong.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'YUTONG',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
                color: AppColors.yutong,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Interurbano${busNumeroInterno != null ? ' · Bus $busNumeroInterno' : ''} · $total asientos',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
