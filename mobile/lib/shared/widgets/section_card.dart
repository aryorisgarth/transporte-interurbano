import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.noPadding = false,
    this.actions,
  });

  final String? title;
  final String? subtitle;
  final Widget child;
  final bool noPadding;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || subtitle != null || actions != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC).withValues(alpha: 0.6),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (actions != null)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: actions!,
                      ),
                    ),
                ],
              ),
            ),
          if (noPadding) child else Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}
