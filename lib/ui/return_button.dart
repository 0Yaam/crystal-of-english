import 'package:flutter/material.dart';

class RightAction {
  final String label;
  final VoidCallback onTap;
  const RightAction(this.label, this.onTap);
}
class ReturnButton extends StatelessWidget {
  static const id = 'return_button';
  final ValueNotifier<List<RightAction>> actions;

  const ReturnButton({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ValueListenableBuilder<List<RightAction>>(
            valueListenable: actions,
            builder: (context, items, _) {
              if (items.isEmpty) return const SizedBox.shrink();

              return Container(
                constraints: BoxConstraints(maxHeight: size.height * 0.9),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final a in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: a.onTap,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(a.label, textAlign: TextAlign.left),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
