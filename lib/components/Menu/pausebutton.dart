import 'package:flutter/material.dart';
import 'package:mygame/main.dart';

class PauseButton extends StatelessWidget {
  final MyGame game;
  const PauseButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // bỏ padding mặc định
          backgroundColor: Colors.transparent, // nền trong suốt
          shadowColor: Colors.transparent,
        ),
        onPressed: () {
          game.pauseEngine();
          game.overlays.add('PauseMenu'); // show menu pause
          game.overlays.remove('PauseButton'); // ẩn nút khi menu hiện
        },
        child: SizedBox(
          height: 45,
          child: Image.asset("assets/menu/pauseMenu/pauseBtn.png")),
      ),
    );
  }
}
