import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'package:provider/provider.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flip_card/flip_card.dart';
import 'front.dart';
import "back.dart";
import 'dart:math';


final AudioPlayer audio = AudioPlayer();


class Newwayreview extends StatefulWidget {
  final int deckId;
  const Newwayreview({super.key, required this.deckId});

  @override
  State<Newwayreview> createState() => _Newwayreview();
}

class _Newwayreview extends State<Newwayreview> {
  List<Flashcard> _dueCards = [];
  String media = "";
  List<Widget>? cardWidgets;

  Future<void> _loadDueCard() async {
    final cardModel = Provider.of<Cardmodel>(context, listen: false);
    _dueCards = await cardModel.getDueCards(widget.deckId);
    media = cardModel.media ?? "";
    cardWidgets = _dueCards.map((card) {
      return FlashCardItem(card: card, media: cardModel.media);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDueCard();
  }

  final controller = SwipableStackController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Cards'),
        actions: [
          IconButton(
            tooltip: 'Undo last review',
            icon: const Icon(Icons.undo),
            onPressed: () async {
              final cardModel = Provider.of<Cardmodel>(context, listen: false);
              await cardModel.undoLastReview();

              controller.rewind();
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadDueCard(),
        builder: (context, snapshot) => Column(
          children: [
            Expanded(
              child: SizedBox(
                width: 900,
                child: Center(
                  child: Swipeder(
                    controller: controller,
                    cardWidgets: cardWidgets,
                    cards: _dueCards,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class Swipeder extends StatefulWidget {
  const Swipeder({
    super.key,
    required this.controller,
    required this.cardWidgets,
    required this.cards,
  });

  final SwipableStackController controller;
  final List<Widget>? cardWidgets;
  final List<Flashcard>? cards;

  @override
  State<Swipeder> createState() => _SwipederState();
}

class _SwipederState extends State<Swipeder> {
  bool right = false;
  int _activeItem = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SwipableStack(
          controller: widget.controller,
          horizontalSwipeThreshold: 0.1,
          verticalSwipeThreshold: 0.3,
          detectableSwipeDirections: const {
            SwipeDirection.up,
            SwipeDirection.down,
          },
          swipeAssistDuration: Duration(milliseconds: 100),
          stackClipBehaviour: Clip.none,
          swipeAnchor: SwipeAnchor.bottom,
          overlayBuilder: (context, properties) {
            final opacity = min(properties.swipeProgress, 1.0);

            switch (properties.direction) {
              case SwipeDirection.up:
                return Opacity(

                  opacity: opacity,
                  child: CardLabel(
                    color: Colors.redAccent,
                    right: true,
                    value: "Hard",
                  ),
                );
              case SwipeDirection.down:
                return Opacity(
                  opacity: opacity,
                  child: CardLabel(
                    color: Colors.teal,
                    right: false,
                    value: "easy",
                  ),
                );
              default:
                return Text(SwipeDirection.values.toString());
            }
          },
          builder: (context, properties) {
            if (widget.cardWidgets == null || widget.cardWidgets!.isEmpty) {
              return SizedBox();
            }
            final itemIndex = (properties.index) % widget.cardWidgets!.length;

            _activeItem = itemIndex;
            return Stack(
              children: [Card(child: widget.cardWidgets?[itemIndex])],
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: EdgeInsets.only(bottom: 30),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(6, (i) {

                return ElevatedButton(
                  onPressed: () async {

                    if (widget.cards == null || widget.cards!.isEmpty) return;
                    final card = widget.cards![_activeItem];
                    final cardModel = Provider.of<Cardmodel>(context, listen: false);
                    await cardModel.updateCardAfterReview(card, i);

                    final dir = (i >= 3) ? SwipeDirection.down : SwipeDirection.up;
                    widget.controller.next(swipeDirection: dir);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: i >= 3 ? Colors.teal : Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(i.toString(), style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(
                        i == 5 ? 'Perfect' : (i == 4 ? 'Easy' : (i == 3 ? 'Good' : (i == 2 ? 'Again' : (i == 1 ? 'Poor' : 'Null')))),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class CardLabel extends StatelessWidget {
  final Color color;
  final bool right;
  final String value;
  const CardLabel({
    super.key,
    required this.color,
    required this.right,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: right ? Alignment.bottomCenter : Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.all(50.0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


class FlashCardItem extends StatefulWidget {
  final Flashcard? card;
  final String? media;
  const FlashCardItem({super.key, required this.card, required this.media});

  @override
  State<FlashCardItem> createState() => _FlashCardItemState();
}

class _FlashCardItemState extends State<FlashCardItem> {
  @override
  Widget build(BuildContext context) {
    final backKey = GlobalKey<BackSideState>();
    return Card(
      elevation: 0.0,
      color: Color.fromARGB(0, 255, 1, 1),
      child: FlipCard(
        front: FrontSide(widget: widget),

        back: BackSide(key: backKey, card: widget.card!, media: widget.media),

        onFlipDone: (isFront) {
          if (isFront) {
            backKey.currentState?.playSound(
              widget.media!,
              widget.card?.sound ?? '',
            );
          }
        },
      ),
    );
  }
}
