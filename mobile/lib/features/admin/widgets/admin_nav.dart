import 'package:flutter/material.dart';

import '../admin_section.dart';

class AdminNav extends StatelessWidget {
  const AdminNav({
    super.key,
    required this.section,
    required this.onSectionChange,
    required this.esGlobal,
  });

  final AdminSectionId section;
  final ValueChanged<AdminSectionId> onSectionChange;
  final bool esGlobal;

  @override
  Widget build(BuildContext context) {
    final groups = buildAdminNav(esGlobal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: groups.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                group.title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            ...group.items.map((item) {
              final active = section == item.id;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Material(
                  color: active ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onSectionChange(item.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: active
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border(left: BorderSide(color: const Color(0xFF5EEAD4), width: 3)),
                            )
                          : null,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: active ? const Color(0xFF99F6E4) : Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}
