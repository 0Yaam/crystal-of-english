import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mygame/components/Menu/usersetting/setting.dart';
import 'package:mygame/main.dart';
import 'package:provider/provider.dart';
import 'package:mygame/components/Menu/flashcard/business/Deck.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'package:mygame/components/Menu/flashcard/screen/decklist/deckwelcome.dart';
import 'package:flutter/foundation.dart';
import 'package:mygame/audio/audio_manager.dart';

class MainMenu extends StatefulWidget {
  final MyGame game;

  const MainMenu({super.key, required this.game});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/menu/background.jpg"),
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
    return Center(child: MenuNav(game: game));
  }
}

class MenuNav extends StatelessWidget {
  const MenuNav({super.key, required this.game});

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 140, child: Image.asset("assets/menu/game_name.png")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, // bỏ padding mặc định
            backgroundColor: Colors.transparent, // nền trong suốt
            shadowColor: Colors.transparent,
          ),
          onPressed: () async {
            if (kIsWeb) {
              // Start BGM on a user gesture to satisfy autoplay policy
              await AudioManager.instance.playBgm(
                'audio/bgm_overworld.mp3',
                volume: 0.4,
              );
            }
            game.overlays.remove('MainMenu'); // ẩn menu
            game.resumeEngine(); // chạy game tiếp
          },
          child: SizedBox(
            height: 40,
            child: Image.asset("assets/menu/NewGame.png"),
          ),
        ),
        // Flashcards entry
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MultiProvider(
                  providers: [
                    ChangeNotifierProvider<Deckmodel>(
                      create: (_) => Deckmodel()..fetchDecks(),
                    ),
                    ChangeNotifierProvider<Cardmodel>(
                      create: (_) => Cardmodel(),
                    ),
                  ],
                  child: const DeckListScreen(),
                ),
              ),
            );
          },
          child: SizedBox(
            height: 40,
            child: Image.asset(
              "assets/menu/Flashcards.png",
              package: null,
              errorBuilder: (c, e, s) {
                // Fallback text if asset missing
                return const Center(
                  child: Text(
                    'Flashcards',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: () {
            game.overlays.remove('MainMenu'); // ẩn menu
            game.resumeEngine();
          },
          child: SizedBox(
            height: 40,
            child: Image.asset("assets/menu/Continue.png"),
          ),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, // bỏ padding mặc định
            backgroundColor: Colors.transparent, // nền trong suốt
            shadowColor: Colors.transparent,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserScreen()),
            );
          },
          child: SizedBox(
            height: 40,
            child: Image.asset("assets/menu/Settings.png"),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, // bỏ padding mặc định
            backgroundColor: Colors.transparent, // nền trong suốt
            shadowColor: Colors.transparent,
          ),
          onPressed: () {
            SystemNavigator.pop();
          },
          child: SizedBox(
            height: 40,
            child: Image.asset("assets/menu/Exit.png"),
          ),
        ),
      ],
    );
  }
}
