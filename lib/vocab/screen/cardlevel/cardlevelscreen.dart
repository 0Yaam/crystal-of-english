import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'package:mygame/components/Menu/flashcard/screen/blankfill/blankwordscreen.dart';
import 'package:mygame/main.dart';
import 'package:mygame/vocab/placementtest/screen/screenmain.dart';
import 'package:mygame/vocab/screen/cardlevel/quest/quest.dart';
import 'package:provider/provider.dart';

import 'blankfillbylevel.dart';

class Cardlevelscreen extends StatefulWidget {
  final MyGame game;
  const Cardlevelscreen({super.key, required this.game});

  @override
  State<Cardlevelscreen> createState() => _CardlevelscreenState();
}

class _CardlevelscreenState extends State<Cardlevelscreen> {
  final List<String> entries = <String>['1', '2', '3', '4', '5', '6', '7'];
  final List<String> levelImage = <String>[
    'collo.png',
    'armor.png',
    'attack.png',
    'female.png',
    'beast.png',
    'cart.png',
    'jaw.png',
  ];
  final List<Color> colors = <Color>[
    Color.fromARGB(255, 228, 68, 44),
    Color.fromARGB(255, 241, 247, 190),
    Colors.blue,
    Color.fromARGB(255, 241, 247, 190),
    Colors.purple,
    Colors.yellow,
    Colors.orange,
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                Color(0xFFB0BEC5), // Light silver
                Color(0xFF90A4AE), // Medium gray
                Color(0xFFCFD8DC), // Highlight
                Color(0xFF607D8B), // Shadow
              ],
              stops: [0.0, 0.3, 0.6, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              widget.game.overlays.remove('CardLevelScreen');
              widget.game.resumeEngine();
            },
          ),
        ),
        actions: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  Color.fromARGB(255, 51, 107, 134), // Light silver
                  Color.fromARGB(255, 29, 172, 89), // Medium gray
                  Color.fromARGB(255, 189, 120, 216), // Highlight
                  Color.fromARGB(255, 251, 254, 255), // Shadow
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: Row(
              children: [
                Text(
                  "Placement Test",
                  style: TextStyle(color: Colors.white, fontSize: 26),
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>QuizApp()),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 32,),
          Row(
            children: const [
              Text(
                '160',
                style: TextStyle(color: Colors.yellowAccent, fontSize: 26),
              ),
              SizedBox(width: 4),
              Text('Coin', style: TextStyle(color: Colors.white, fontSize: 26)),
            ],
          ),
          SizedBox(width: 16),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  Color(0xFFB0BEC5), // Light silver
                  Color(0xFF90A4AE), // Medium gray
                  Color(0xFFCFD8DC), // Highlight
                  Color(0xFF607D8B), // Shadow
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: Row(
              children: [
                Text(
                  "Quests",
                  style: TextStyle(color: Colors.white, fontSize: 26),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QuestScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        title: const Text(
          'Complexity Levels',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              
            },
            child: Container(
              //height: 300,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 150,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: colors[index].withOpacity(
                      0.47,
                    ), // Shadow color with opacity
                    offset: const Offset(1, 1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage('assets/level-titan/${levelImage[index]}'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4),
                    BlendMode.darken,
                  ),
                ),
              ),

              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Complexity ',
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                    Text(
                      'Level ${entries[index]}',
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
