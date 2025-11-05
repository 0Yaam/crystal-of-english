import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'package:mygame/components/Menu/flashcard/screen/blankfill/blankwordscreen.dart';
import 'package:mygame/components/Menu/flashcard/screen/flashcard/newwayreview.dart';
import 'package:mygame/main.dart';
import 'package:mygame/vocab/screen/cardlevel/cardlevelscreen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

final AudioPlayer audio = AudioPlayer();

class CardListScreen extends StatefulWidget {
  final int? deckId;
  final String? deckName;
  const CardListScreen({super.key, required this.deckId,required this.deckName});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.deckId != null) {
        final cardModel = Provider.of<Cardmodel>(context, listen: false);
        cardModel.fetchCards(widget.deckId!);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _NavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              NavPageBtn(label: "review", screenBuilder: ()=>Newwayreview(deckId: widget.deckId!)),
              NavPageBtn(label: "blank word", screenBuilder: ()=>BlankWordScreen(deck_id: widget.deckId!,)),
              
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardModel = Provider.of<Cardmodel>(context);
    final List<Widget> cardWidgets = cardModel.card.map((card) {
      return FlashCardItem(card: card, media: cardModel.media);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text('My Deck')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cardWidgets.length,
              itemBuilder: (context, index) {
                return cardWidgets[index];
              },
            ),
          ),
          _NavBar(context),
        ],
      ),
    );
  }
}

class NavPageBtn extends StatelessWidget {
  final String label;
  final Widget Function() screenBuilder;

  const NavPageBtn({
    super.key,
    required this.label,
    required this.screenBuilder
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final cardModel = Provider.of<Cardmodel>(context, listen: false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider<Cardmodel>.value(
              value: cardModel,
              child: screenBuilder(),
            ),
          ),
        );
      },
      child: Text(label),
    );
  }
}

class FlashCardItem extends StatelessWidget {
  final Flashcard card;
  final String? media;
  const FlashCardItem({super.key, required this.card, required this.media});

  @override
  Widget build(BuildContext context) {
    final String? dir = (media != null && media!.isNotEmpty)
        ? '/data/user/0/com.example.mygame/app_flutter/anki/${media!}'
        : null;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            PictureHolder(path: (dir != null && card.img != null) ? '$dir/${card.img}' : null),
            IPAandWord(card: card),
            CardInformation(card: card, dir: dir),
            PictureHolder(path: (dir != null && card.synonyms != null) ? '$dir/${card.synonyms}' : null),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChipTitle(
                  title: "Interval",
                  value: card.interval.toString(),
                  color: Colors.blue[50]!,
                ),
                ChipTitle(
                  title: "Reps",
                  value: card.reps.toString(),
                  color: Colors.green[50]!,
                ),
                Complexity(card: card),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IPAandWord extends StatelessWidget {
  const IPAandWord({super.key, required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            card.word ?? '',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 167, 14, 77),
            ),
            overflow: TextOverflow.fade,
          ),
        ),
        if (card.ipa != null)
          Flexible(
            child: Text(
              "/${card.ipa!}/",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                overflow: TextOverflow.ellipsis,
                color: Colors.grey[700],
              ),
            ),
          ),
      ],
    );
  }
}

class CardInformation extends StatelessWidget {
  const CardInformation({super.key, required this.card, required this.dir});

  final Flashcard card;
  final String? dir;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Word + IPA
              const SizedBox(height: 4),
              TitleAndValue(title: "Meaning", value: card.meaning ?? ''),
              TitleAndValue(title: "Example", value: card.example ?? ''),
              TitleAndValue(title: "Image", value: card.img ?? ''),
              TitleAndValue(title: "Sound", value: card.sound ?? ''),
              TitleAndValue(
                title: "Definition Sound",
                value: card.defSound ?? '',
              ),
              TitleAndValue(title: "Usage Sound", value: card.usageSound ?? ''),
              const SizedBox(height: 6),
              if (card.due != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    'Due: ${DateFormat('MM/dd').format(card.due!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
        Column(
          children: [
            SoundTitle(
              title: "sound",
              value: (dir != null && card.sound != null) ? '$dir/${card.sound}' : '',
              icon: const Icon(Icons.volume_up),
            ),
            SoundTitle(
              title: "u sound",
              value: (dir != null && card.usageSound != null) ? '$dir/${card.usageSound}' : '',
              icon: const Icon(Icons.volume_up),
            ),
            SoundTitle(
              title: "def sound",
              value: (dir != null && card.defSound != null) ? '$dir/${card.defSound}' : '',
              icon: const Icon(Icons.volume_up),
            ),
          ],
        ),
      ],
    );
  }
}

class PictureHolder extends StatelessWidget {
  final String? path;
  const PictureHolder({super.key, required this.path});
  
  @override
  Widget build(BuildContext context) {
    if (path != null) {
      return Container(
        width: 400,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path!),
            fit: BoxFit.fitWidth, 
          ),
        ),
      );
    } else {
      return Text("synonyms");
    }
  }
}

class SoundTitle extends StatelessWidget {
  final String title;
  final String value;
  final Icon icon;
  const SoundTitle({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (value!=''||value.isNotEmpty) {
      return Column(
        children: [
          IconButton(
            icon: icon,
            onPressed: () async {

              await audio.play(DeviceFileSource(value));
            },
          ),
          Text(title),
        ],
      );
    } else {
      return SizedBox();
    }
  }
}

class ChipTitle extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const ChipTitle({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$title: $value'), backgroundColor: color);
  }
}

class TitleAndValue extends StatelessWidget {
  final String title;
  final String value;

  const TitleAndValue({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value!='') {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            TextSpan(text: value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      );
    } else {
      return SizedBox();
    }
  }
}

class Complexity extends StatelessWidget {
  const Complexity({super.key, required this.card});

  final Flashcard card;
  Color _getChipColor(int complexity) {
    if (complexity == 1) {
      return const Color.fromARGB(
        255,
        0,
        168,
        6,
      ); 
    } else if (complexity == 2) {
      return const Color.fromARGB(
        255,
        0,
        97,
        73,
      ); 
    } else if (complexity == 3) {
      return const Color.fromARGB(
        255,
        0,
        59,
        94,
      );
    } else if (complexity == 4) {
      return const Color.fromARGB(
        255,
        141,
        3,
        106,
      ); // Mức độ khó vừa (cam nhạt)
    } else if (complexity == 5) {
      return const Color.fromARGB(255, 138, 3, 16); 
    } else {
      // Mặc định hoặc giá trị không xác định
      return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getChipColor(card.complexity ?? 0);
    return Chip(
      label: Text(
        'level: ${card.complexity}',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}
