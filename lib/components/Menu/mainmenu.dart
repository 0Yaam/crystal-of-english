import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mygame/components/Menu/flashcard/screen/decklist/deckwelcome.dart';
import 'package:mygame/components/Menu/usersetting/setting.dart';
import 'package:mygame/main.dart';

import 'package:flutter/foundation.dart';
import 'package:mygame/audio/audio_manager.dart';
import 'package:mygame/components/Menu/save_load/save_load_screen.dart';
import 'package:mygame/ui/settings_overlay.dart';

class MainMenu extends StatefulWidget {
  final MyGame game;

  const MainMenu({super.key, required this.game});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  void initState() {
    super.initState();

    widget.game.overlays.remove(SettingsOverlay.id);
  }

  @override
  void dispose() {

    if (!widget.game.overlays.isActive(SettingsOverlay.id)) {
      widget.game.overlays.add(SettingsOverlay.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(

          image: AssetImage("assets/menu/menuimage.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: MenuContent(game: widget.game),
      ),
    );
  }
}

class MenuContent extends StatelessWidget {
  const MenuContent({super.key, required this.game});

  final MyGame game;

  @override
  Widget build(BuildContext context) {

    return SizedBox.expand(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: MenuNav(game: game),
        ),
      ),
    );
  }
}

class MenuNav extends StatelessWidget {
  const MenuNav({super.key, required this.game});

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        SizedBox(
          height: 120,
          child: Image.asset(
            "assets/menu/game_name.png",
            errorBuilder: (c, e, s) => const Center(
              child: Text(
                'Crystal of English',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),


        GestureDetector(
          onTap: () async {
            if (kIsWeb) {
              await AudioManager.instance.playBgm(
                'audio/bgm_overworld.mp3',
                volume: 0.4,
              );
            }

            game.overlays.remove('MainMenu');
            if (!game.overlays.isActive(SettingsOverlay.id)) {
              game.overlays.add(SettingsOverlay.id);
            }
            game.resumeEngine();
          },
          child: const Text(
            'New Game',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),

        const SizedBox(height: 16),


        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SaveLoadScreen(game: game),
              ),
            );
          },
          child: const Text(
            'Save / Load',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),

        const SizedBox(height: 16),


        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserScreen()),
            );
          },
          child: const Text(
            'Options',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),

        const SizedBox(height: 16),


        GestureDetector(
          onTap: () {
            SystemNavigator.pop();
          },
          child: const Text(
            'Exit',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DeckListScreen()),
            );
          },
          child: const Text(
            'Flash Card',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ],
    );
  }
}
