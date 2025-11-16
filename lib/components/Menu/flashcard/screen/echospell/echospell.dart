import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/flashcard/screen/echospell/echospellUI.dart';

class Echospell extends StatefulWidget {
  final int deck_id;
  Echospell({
    super.key,
    required this.deck_id
    });

  @override
  State<Echospell> createState() => _EchospellState();
}

class _EchospellState extends State<Echospell> {
  @override
  Widget build(BuildContext context) {
    return EchospellUI();
  }
}