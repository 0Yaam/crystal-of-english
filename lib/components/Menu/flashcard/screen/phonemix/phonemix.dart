import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/flashcard/screen/phonemix/phonemixNoti.dart';
import 'package:mygame/components/Menu/flashcard/screen/phonemix/phonemixUI.dart';
import 'package:provider/provider.dart';

class PhoneMix extends StatefulWidget {
  int deckID;
  PhoneMix({super.key, required this.deckID});

  @override
  State<PhoneMix> createState() => _PhoneMixState();
}

class _PhoneMixState extends State<PhoneMix> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => phoneMixNoti()..getFlashcardList(widget.deckID),
      child: Consumer<phoneMixNoti>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          return PhoneMixUI();
        },
      ),
    );
  }
}
