import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/flashcard/business/Deck.dart';
import 'package:mygame/main.dart';
import 'package:provider/provider.dart';

import 'cardlistscreen.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> color1;
  late Animation<Color?> color2;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    color1 = ColorTween(
      begin: Colors.teal.shade900,
      end: Colors.red.shade900,
    ).animate(_controller);

    color2 = ColorTween(
      begin: Colors.black,
      end: Colors.teal.shade800,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTile(BuildContext context, dynamic deck, dynamic deckModel, int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.withOpacity(0.6 + 0.2 * sin(index + _controller.value * pi)),
                Colors.red.withOpacity(0.6 + 0.2 * cos(index + _controller.value * pi)),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            title: Text(
              deck.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const Icon(Icons.layers, color: Colors.white),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<Cardmodel>(
                    create: (_) => Cardmodel(),
                    child: CardListScreen(deckId: deck.id,deckName:deck.name,),
                  ),
                ),
              );
            },
            trailing: IconButton(
              onPressed: () {
                if (deck.id != null) {
                  deckModel.deleteDeck(deck.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red.shade800,
                      content: Text('Deck "${deck.name}" deleted'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete, color: Colors.white70),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            leading: const Icon(Icons.menu_book, color: Colors.white),
            backgroundColor: color1.value,
            elevation: 10,
            title: const Text(
              "My Decks",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 60),
                child: IconButton(
                  onPressed: () {
                    Provider.of<Deckmodel>(context, listen: false).filePicker();
                  },
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color2.value!, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Consumer<Deckmodel>(
                      builder: (context, deckModel, child) {
                        return ListView.builder(
                          itemCount: deckModel.deck.length,
                          itemBuilder: (context, index) {
                            final deck = deckModel.deck[index];
                            return _buildAnimatedTile(context, deck, deckModel, index);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CreateNewDeck extends StatefulWidget {
  const CreateNewDeck({super.key});

  @override
  State<CreateNewDeck> createState() => _CreateNewDeckState();
}

class _CreateNewDeckState extends State<CreateNewDeck> {
  final deckController = TextEditingController();

  void _createDeck(BuildContext context, Deckmodel value) {
    final deckName = deckController.text.trim();
    if (deckName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck name cannot be empty')),
      );
      return;
    }
    final deckExists = value.deck.any((deck) => deck.name == deckName);
    if (deckExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deck "$deckName" already exists')),
      );
      return;
    }
    value.insertDeck(deckName);
    deckController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Deckmodel>(
      builder: (context, value, child) {
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: deckController,
                decoration: InputDecoration(labelText: "new deck name"),
                onSubmitted: (_) => _createDeck(context, value), 
              ),
            ),
            ElevatedButton(
              onPressed: () => _createDeck(context, value), 
              child: Text('them deck'),
            ),
          ],
        );
      },
    );
  }
}
