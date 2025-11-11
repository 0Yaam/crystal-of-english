import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
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
    final manager = widget.manager;





    final dialogType = manager.currentType.value ?? '';
  final isNpcDialog = dialogType.trim().isEmpty;

  final panelFactor = isNpcDialog ? 0.4 : 0.6;
    final panelH = size.height * panelFactor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (manager.currentChoices.value.isEmpty) {
          manager.advance();
        }
      },
      child: Stack(
        children: [

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
                  padding: EdgeInsets.fromLTRB(
                    size.width * 0.02,
                    size.height * 0.015,
                    size.width * 0.02,
                    size.height * 0.012,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.all(size.width * 0.015),
                          child: ValueListenableBuilder<String?>(
                            valueListenable: manager.currentType,
                            builder: (context, type, _) {
                              final text = manager.currentText.value;
                              final imageRaw = manager.currentImage.value;
                              final soundRaw = manager.currentSound.value;
                              final t = (type ?? 'text').toLowerCase();
                              if (t == 'image') {
                                if (imageRaw == null || imageRaw.isEmpty) {
                                  return Center(child: Text('Image not found', style: TextStyle(color: Colors.white)));
                                }

                                return Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: panelH * 0.85,
                                      child: Image.asset(
                                        imageRaw,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                );
                              } else if (t == 'sound') {
                                return Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (soundRaw != null && soundRaw.isNotEmpty) FlameAudio.play(soundRaw);
                                    },
                                    icon: const Icon(Icons.volume_up),
                                    label: const Text('Play'),
                                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                );
                              } else if (t == 'imagesound' || t == 'image_sound') {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (soundRaw != null && soundRaw.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: () => FlameAudio.play(soundRaw),
                                        icon: const Icon(Icons.volume_up),
                                        label: const Text('Play'),
                                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      ),
                                    const SizedBox(height: 8),
                                    if (imageRaw != null && imageRaw.isNotEmpty)
                                      SizedBox(
                                        height: panelH * 0.8,
                                        child: Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.asset(imageRaw, fit: BoxFit.contain, width: double.infinity),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              } else {

                                return Center(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'MyFont',
                                        color: Colors.white,


                                        fontSize: (size.height * 0.042).clamp(18.0, 44.0),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),

                      SizedBox(width: size.width * 0.015),


                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.all(size.width * 0.01),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 218, 218, 218).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: ValueListenableBuilder<List<DialogueChoice>>(
                            valueListenable: manager.currentChoices,
                            builder: (context, choices, _) {
                              if (choices.isEmpty) return const SizedBox.shrink();
                              final dialogType = manager.currentType.value ?? '';
                              final showLetters = dialogType == 'flashcard' || dialogType == 'quiz';
                              if (showLetters) {

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final totalH = constraints.maxHeight;
                                    final n = choices.length;
                                    final gap = panelH * 0.012;
                                    final totalGap = (n > 1) ? gap * (n - 1) : 0.0;
                                    final itemH = (totalH - totalGap) / n;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: choices.asMap().entries.map((entry) {
                                        final i = entry.key;
                                        final c = entry.value;
                                        final letter = String.fromCharCode(65 + i);
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: i == n - 1 ? 0 : gap),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: itemH,
                                            child: ElevatedButton(
                                              onPressed: () => manager.choose(i),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(size.width * 0.018),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: panelH * 0.014,
                                                  horizontal: size.width * 0.02,
                                                ),
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '$letter. ${c.text}',
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(

                                                    fontSize: (size.height * 0.034).clamp(16.0, 30.0),
                                                    height: 1.15,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                );
                              } else {

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final n = choices.length;
                                    final gap = panelH * 0.01;
                                    final totalGap = (n > 1) ? gap * (n - 1) : 0.0;
                                    final itemH = (constraints.maxHeight - totalGap) / n;
                                    return Column(
                                      children: choices.asMap().entries.map((entry) {
                                        final idx = entry.key;
                                        final c = entry.value;
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: idx == n - 1 ? 0 : gap),
                                          child: SizedBox(
                                            height: itemH,
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () => manager.choose(idx),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF3B82F6).withOpacity(0.12),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(size.width * 0.015),
                                                ),
                                                side: const BorderSide(color: Colors.white24),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: panelH * 0.014,
                                                  horizontal: size.width * 0.02,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  c.text,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: (size.height * 0.032).clamp(16.0, 28.0),
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                );
                              }
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

          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.02,
            vertical: MediaQuery.of(context).size.height * 0.008,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'MyFont',
                color: Colors.black,

                fontSize: (MediaQuery.of(context).size.height * 0.022).clamp(12.0, 20.0),
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
