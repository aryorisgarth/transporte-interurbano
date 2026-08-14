import 'package:flutter/material.dart';

import '../../core/utils/formato.dart';

class HoraSalidaField extends StatelessWidget {
  const HoraSalidaField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Hora salida',
    this.dense = false,
  });

  final HoraSalidaNicaragua value;
  final ValueChanged<HoraSalidaNicaragua> onChanged;
  final String label;
  final bool dense;

  static const _horas = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  static final _minutos = List.generate(60, (i) => i.toString().padLeft(2, '0'));

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: dense,
      contentPadding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 10 : 12),
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  Widget _dropdown<T>({
    required T current,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required double minWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: DropdownButtonFormField<T>(
        value: current,
        isExpanded: true,
        decoration: _dec(hint),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(fontSize: dense ? 13 : 14, color: Colors.grey.shade700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _dropdown<int>(
              current: value.hora,
              hint: 'Hora',
              minWidth: dense ? 88 : 96,
              items: _horas.map((h) => DropdownMenuItem(value: h, child: Text('$h'))).toList(),
              onChanged: (h) {
                if (h != null) onChanged(HoraSalidaNicaragua(hora: h, minuto: value.minuto, ampm: value.ampm));
              },
            ),
            Text(':', style: TextStyle(fontSize: dense ? 18 : 20, color: Colors.grey.shade600)),
            _dropdown<String>(
              current: value.minuto,
              hint: 'Min',
              minWidth: dense ? 88 : 96,
              items: _minutos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (m) {
                if (m != null) onChanged(HoraSalidaNicaragua(hora: value.hora, minuto: m, ampm: value.ampm));
              },
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'AM', label: Text('AM')),
                ButtonSegment(value: 'PM', label: Text('PM')),
              ],
              selected: {value.ampm},
              onSelectionChanged: (sel) {
                if (sel.isNotEmpty) {
                  onChanged(HoraSalidaNicaragua(hora: value.hora, minuto: value.minuto, ampm: sel.first));
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
