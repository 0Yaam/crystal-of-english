import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/Theme/color.dart';

class EchospellUI extends StatefulWidget {
  const EchospellUI({super.key});

  @override
  State<EchospellUI> createState() => _EchospellUIState();
}

class _EchospellUIState extends State<EchospellUI> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.darkBase,
      appBar: AppBar(
        leading: Row(
          children: [
            SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColor.darkBorder,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        title: LinearProgressIndicator(
          value: 0.1,
          backgroundColor: AppColor.darkCard,
          valueColor: AlwaysStoppedAnimation<Color>(AppColor.greenPrimary),
          minHeight: 18,
          borderRadius: BorderRadius.circular(9),
        ),
        backgroundColor: AppColor.darkBase,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 40),
                  Text(
                    "Tap to build the word.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // AnimatedPositioned(
          //   duration: const Duration(milliseconds: 500),
          //   curve: Curves.easeOutCubic,
          //   bottom: provider.answer ? 0 : -MediaQuery.of(context).size.height,
          //   left: 0,
          //   right: 0,
          //   height: MediaQuery.of(context).size.height,
          //   child: ReviewScreen(
          //     onPressed: () {
          //       reader.NextTask();
          //     },
          //   ),
          // ),
        ],
      ),
    );;
  }
}