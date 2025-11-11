import 'package:flutter/material.dart';
import 'package:mygame/main.dart';

class PauseMenu extends StatelessWidget {
  final MyGame game;
  const PauseMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 225,
        width: 450,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/menu/pauseMenu/gamer-pause-screen.png'),
            fit: BoxFit.fitHeight
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            NavPauseMenu(game: game),
            SizedBox(height: 12,)
          ],
        ),
      ),
    );
  }
}

class NavPauseMenu extends StatelessWidget {
  const NavPauseMenu({super.key, required this.game});

  final MyGame game;
  final double btnSize=42;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            onPressed: () {
              game.resumeEngine();
              game.overlays.remove('PauseMenu');
            },
            child: SizedBox(
              height: btnSize,
              child: Image.asset("assets/menu/pauseMenu/HomeBtn.png"),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            onPressed: () {
              game.resumeEngine();
              game.overlays.add('MainMenu');
              game.overlays.remove('PauseMenu');
            },
            child: SizedBox(
              height: btnSize,
              child: Image.asset("assets/menu/pauseMenu/ResetBtn.png"),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            onPressed: () {
              game.resumeEngine();
              game.overlays.remove('PauseMenu');
            },
            child: SizedBox(
              height: btnSize,
              child: Image.asset("assets/menu/pauseMenu/ResumeBtn.png"),
            ),
          ),
        ],
      ),
    );
  }
}
