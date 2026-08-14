import 'package:flutter/material.dart';

import '../../../core/models/empresa.dart';

class TenantSelector extends StatelessWidget {
  const TenantSelector({
    super.key,
    required this.esGlobal,
    required this.empresas,
    required this.empresaId,
    required this.empresaNombre,
    required this.onChange,
    this.compact = false,
    this.sidebar = false,
  });

  final bool esGlobal;
  final List<Empresa> empresas;
  final int? empresaId;
  final String empresaNombre;
  final void Function(int id, String nombre) onChange;
  final bool compact;
  final bool sidebar;

  @override
  Widget build(BuildContext context) {
    if (!esGlobal) {
      return Chip(
        avatar: const Icon(Icons.business, size: 16),
        label: Text(
          empresaNombre.isNotEmpty ? empresaNombre : 'Mi cooperativa',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (empresas.isEmpty) {
      return Text(
        'Sin cooperativas',
        style: TextStyle(color: sidebar ? Colors.white70 : Colors.grey.shade600, fontSize: 12),
      );
    }

    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: empresaId,
        isDense: compact,
        isExpanded: !sidebar,
        dropdownColor: sidebar ? const Color(0xFF0C4A6E) : null,
        style: TextStyle(
          color: sidebar ? Colors.white : null,
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w600,
        ),
        items: empresas
            .map(
              (e) => DropdownMenuItem(
                value: e.id,
                child: Text(
                  '${e.nombre}${e.activo ? '' : ' (inactiva)'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (id) {
          if (id == null) return;
          final sel = empresas.firstWhere((e) => e.id == id);
          onChange(id, sel.nombre);
        },
      ),
    );

    if (sidebar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'COOPERATIVA',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: dropdown,
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth < 960 ? double.infinity : 260,
          child: Row(
            children: [
              if (constraints.maxWidth >= 960) ...[
                Icon(Icons.business, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: empresaId,
                    isDense: compact,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: empresas
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(
                              '${e.nombre}${e.activo ? '' : ' (inactiva)'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      final sel = empresas.firstWhere((e) => e.id == id);
                      onChange(id, sel.nombre);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
