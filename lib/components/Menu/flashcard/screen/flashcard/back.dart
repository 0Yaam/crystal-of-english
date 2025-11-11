import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/flashcard/business/Flashcard.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'newwayreview.dart';

class BackSide extends StatefulWidget {
  final Flashcard card;
  final String? media;
  const BackSide({super.key, required this.card, required this.media});

  @override
  State<BackSide> createState() => BackSideState();
}

class BackSideState extends State<BackSide> {
  void playSound(String media, String path) async {
    String soundPath =
        '/data/user/0/com.example.mygame/app_flutter/anki/$media/$path';
    try {
      await audio.play(DeviceFileSource(soundPath));
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dir =
        '/data/user/0/com.example.mygame/app_flutter/anki/${widget.media!}';
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.yellow[70],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [















            Row(
              children: [
                if (widget.card.img != null)
                  Container(
                    width: 400,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        height: 150,
                        fit:BoxFit.cover,
                        File('$dir/${widget.card.img}'),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Text(
                              widget.card.word ?? '',
                              style: const TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 167, 14, 77),
                              ),
                              overflow: TextOverflow.clip,
                            ),
                          ),
                          if (widget.card.ipa != null)
                            Flexible(
                              child: Text(
                                "/${widget.card.ipa!}/",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  overflow: TextOverflow.ellipsis,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),


                      if (widget.card.meaning != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Meaning: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              TextSpan(
                                text: widget.card.meaning ?? '',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      if (widget.card.example != null &&
                          widget.card.example != "")
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Example: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                              TextSpan(
                                text: widget.card.example ?? '',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    if (widget.card.sound != null)
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () async {
                              await audio.play(
                                DeviceFileSource('$dir/${widget.card.sound}'),
                              );
                            },
                          ),
                          Text("sound"),
                        ],
                      ),
                    if (widget.card.usageSound != null)
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () async {
                              await audio.play(
                                DeviceFileSource(
                                  '$dir/${widget.card.usageSound}',
                                ),
                              );
                            },
                          ),
                          Text("u sound"),
                        ],
                      ),
                    if (widget.card.defSound != null)
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () async {



                            },
                          ),
                          Text("defsound"),
                        ],
                      ),
                  ],
                ),
              ],
            ),
















          ],
        ),
      ),
    );
  }
}
