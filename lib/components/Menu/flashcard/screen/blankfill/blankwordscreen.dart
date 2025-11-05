import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/Theme/color.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'package:provider/provider.dart';

AudioPlayer audioPlayer = AudioPlayer();

class BlankWordScreen extends StatefulWidget {
  final int deck_id;
  const BlankWordScreen({super.key, required this.deck_id});

  @override
  State<BlankWordScreen> createState() => _BlankWordScreenState();
}

class _BlankWordScreenState extends State<BlankWordScreen> {
  late Future<List<Flashcard>> futureCard;
  late String media;
  Future<List<Flashcard>> _loadDueCard() async {
    final cardModel = Provider.of<Cardmodel>(context, listen: false);
    media = cardModel.media ?? "";
    return cardModel.getDueCards(widget.deck_id);
  }

  @override
  void initState() {
    super.initState();
    futureCard = _loadDueCard();
    print(widget.deck_id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("blank")),
      body: FutureBuilder(
        future: futureCard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No cards found"));
          }

          final list = snapshot.data!;

          return ChangeNotifierProvider(
            create: (_) => QuizzModel(list: list, media: media),
            child: Consumer<QuizzModel>(
              builder: (context, quiz, _) => Stack(
                children: [
                  BlankWordQuizz(
                    media: quiz.file,
                    onComplete: quiz.NextWord,
                    card: quiz.currentCard,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class QuizzModel extends ChangeNotifier {
  final List<Flashcard> list;
  final String media;
  QuizzModel({required this.list, required this.media});

  String get file => media;
  int wordIdx = 0;
  Flashcard get currentCard => list[wordIdx];
  void NextWord() {
    wordIdx = (wordIdx + 1) % list.length;
    notifyListeners();
  }
}

class BlankWordQuizz extends StatefulWidget {
  final Flashcard card;
  final String media;
  final VoidCallback onComplete;
  const BlankWordQuizz({
    super.key,
    required this.media,
    required this.onComplete,
    required this.card,
  });

  @override
  State<BlankWordQuizz> createState() => _BlankWordQuizzState();
}

class _BlankWordQuizzState extends State<BlankWordQuizz> {
  String get word => widget.card.word ?? "";
  String get media => widget.media;
  Flashcard get card => widget.card;
  late List<String> blanks;
  int curIdx = 0;
  late List<String> list;
  late List<String> wordList;
  List<bool> visible = [];
  List<bool> trueList = [];
  bool finish = false;
  @override
  void initState() {
    super.initState();
    if (word.contains(' ')) {
      list = word.split(' ')..shuffle();
      wordList = word.split(' ');
      blanks = List.filled(list.length, '-------');
      visible = List.filled(list.length, true);
      trueList = List.filled(list.length, true);
    } else {
      list = word.split('')..shuffle();
      wordList = word.split('');
      blanks = List.filled(word.length, '_');
      visible = List.filled(list.length, true);
      trueList = List.filled(list.length, true);
    }
  }

  Future<bool> checkAnswer(String letter, int index) async {
    try {
      if (letter == wordList[curIdx]) {
        setState(() {
          blanks[curIdx] = wordList[curIdx];
          visible[index] = false;
          curIdx++;
        });

        if (curIdx <= wordList.length && curIdx == wordList.length) {
          print("in wait list");
          if (media != "" || card.sound != null || card.sound != '') {
            try {
              await audioPlayer.play(
                DeviceFileSource(
                  "/data/user/0/com.example.mygame/app_flutter/anki/$media/${card.sound}",
                ),
              );
            } catch (e) {
              print(e);
            }
          }
          print("done sound");
          setState(() {
            finish = true;
          });
          Future.delayed(Duration(milliseconds: 1000), () {
            setState(() {
              finish = false;
            });
          });
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) widget.onComplete();
        }
        return true;
      } else {
        setState(() {
          trueList[index] = false;
        });

        Future.delayed(Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() {
            trueList[index] = true; // back to blue
          });
        });
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant BlankWordQuizz oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.word != widget.card.word) {
      setState(() {
        if (word.contains(' ')) {
          list = word.split(' ')..shuffle();
          wordList = word.split(' ');
          blanks = List.filled(list.length, '-------');
          visible = List.filled(list.length, true);
          trueList = List.filled(list.length, true);
        } else {
          list = word.split('')..shuffle();
          wordList = word.split('');
          blanks = List.filled(word.length, '_');
          visible = List.filled(list.length, true);
          trueList = List.filled(list.length, true);
        }
        curIdx = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Center(
              child: Container(
                width: 800,
                height: 200,
                decoration: BoxDecoration(color: AppColor.blueist),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.meaning ?? "",
                          style: TextStyle(color: Colors.white, fontSize: 30),
                          textAlign: TextAlign.center,
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: blanks.asMap().entries.map((entry) {
                            return Text(
                              "${entry.value} ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(list.length, (index) {
                    final value = list[index];
                    return AnimatedOpacity(
                      opacity: visible[index] ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: () => checkAnswer(value, index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: trueList[index]
                              ? Colors.blue
                              : Colors.red,
                        ),
                        child: Text(
                          value,
                          style: TextStyle(color: Colors.white, fontSize: 30),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        Visibility(
          visible: finish,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                color: AppColor.blueist,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.word ?? "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        card.meaning ?? "",
                        overflow: TextOverflow.clip,
                        style: TextStyle(color: Colors.white, fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
