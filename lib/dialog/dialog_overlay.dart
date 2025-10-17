import 'package:flutter/material.dart';
import 'dialog_manager.dart';
import '../ui/sprite_slice.dart';

class DialogOverlay extends StatefulWidget {
  static const id = 'dialog';
  final DialogManager manager;
  const DialogOverlay({super.key, required this.manager});

  @override
  State<DialogOverlay> createState() => _DialogOverlayState();
}

class _DialogOverlayState extends State<DialogOverlay> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const panelFactor = 0.30;
    final panelH = size.height * panelFactor;
    final manager = widget.manager;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (manager.currentChoices.value.isEmpty) {
          manager.advance();
        }
      },
      child: Stack(
        children: [
          // Avatar trái
          ValueListenableBuilder<Portrait?>(
            valueListenable: manager.currentPortrait,
            builder: (context, p, _) {
              if (p == null) return const SizedBox.shrink();
              return Positioned(
                left: 12,
                bottom: panelH + 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SpriteSlice(
                    asset: p.asset,
                    source: p.src ?? const Rect.fromLTWH(0, 0, 48, 48),
                    displaySize: p.size,
                  ),
                ),
              );
            },
          ),

          // Avatar phải (nếu có)
          ValueListenableBuilder<Portrait?>(
            valueListenable: manager.currentRightPortrait,
            builder: (context, p, _) {
              if (p == null) return const SizedBox.shrink();
              return Positioned(
                right: 12,
                bottom: panelH + 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SpriteSlice(
                    asset: p.asset,
                    source: p.src ?? const Rect.fromLTWH(0, 0, 48, 48),
                    displaySize: p.size,
                  ),
                ),
              );
            },
          ),

          // Panel dưới
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                width: size.width,
                height: panelH,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Text trái
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: manager.currentText,
                          builder: (context, text, _) => SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: double.infinity),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                       fontFamily: 'MyFont',  
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: 1.35,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: 140,
                          maxWidth: size.width * 0.28,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 218, 218, 218).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: ValueListenableBuilder<List<DialogueChoice>>(
                            valueListenable: manager.currentChoices,
                            builder: (context, choices, _) {
                              if (choices.isEmpty) return const SizedBox.shrink();
                              return ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: choices.length,
                                itemBuilder: (context, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _ChoiceButton(
                                    label: choices[i].text,
                                    onPressed: () => manager.choose(i),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _ChoiceButton({required this.label, required this.onPressed});

  @override
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onPressed();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'MyFont', 
                color: Colors.black,
                fontSize: 15,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
