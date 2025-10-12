import 'package:flutter/material.dart';
import '../audio/audio_manager.dart';

class SettingsOverlay extends StatefulWidget {
  static const id = 'settings_overlay';

  final AudioManager audio;
  const SettingsOverlay({super.key, required this.audio});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  bool open = false;

  late bool _bgmEnabled;
  late bool _sfxEnabled;
  late double _bgmVol;
  late double _sfxVol;

  @override
  void initState() {
    super.initState();
    _bgmEnabled = widget.audio.bgmEnabled;
    _sfxEnabled = widget.audio.sfxEnabled;
    _bgmVol = widget.audio.bgmVolume;
    _sfxVol = widget.audio.sfxVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              Material(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => open = !open),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.settings, color: Colors.white, size: 24),
                  ),
                ),
              ),
              if (open) const SizedBox(height: 8),
              if (open)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Material(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune, size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                'Settings',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => setState(() => open = false),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Music toggle + volume
                          Row(
                            children: [
                              Switch(
                                value: _bgmEnabled,
                                onChanged: (v) {
                                  setState(() => _bgmEnabled = v);
                                  widget.audio.setBgmEnabled(v);
                                },
                              ),
                              const SizedBox(width: 6),
                              const Text('Music'),
                            ],
                          ),
                          Slider(
                            value: _bgmVol,
                            min: 0,
                            max: 1,
                            onChanged: (val) {
                              setState(() => _bgmVol = val);
                              widget.audio.setBgmVolume(val);
                            },
                          ),
                          const SizedBox(height: 4),
                          // SFX toggle + volume
                          Row(
                            children: [
                              Switch(
                                value: _sfxEnabled,
                                onChanged: (v) {
                                  setState(() => _sfxEnabled = v);
                                  widget.audio.setSfxEnabled(v);
                                },
                              ),
                              const SizedBox(width: 6),
                              const Text('SFX'),
                            ],
                          ),
                          Slider(
                            value: _sfxVol,
                            min: 0,
                            max: 1,
                            onChanged: (val) {
                              setState(() => _sfxVol = val);
                              widget.audio.setSfxVolume(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}
