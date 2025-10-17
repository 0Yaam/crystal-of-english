import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/Theme/color.dart';
import 'package:mygame/components/Menu/flashcard/screen/decklist/deckwelcome.dart';

class Account extends StatelessWidget {
  const Account({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 20,
      child: IconButton(
        color: Colors.white,
        padding: EdgeInsets.all(20.0),
        iconSize: 40,
        icon: Icon(Icons.account_box),
        onPressed: () => {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileSreen()),
          ),
        },
      ),
    );
  }
}

class ProfileSreen extends StatefulWidget {
  const ProfileSreen({super.key});

  @override
  State<ProfileSreen> createState() => _ProfileSreenState();
}

class _ProfileSreenState extends State<ProfileSreen> {
  //final user = FirebaseAuth.instance.currentUser;

  int currentPageIndex = 0;

  NavigationDestinationLabelBehavior labelBehavior =
      NavigationDestinationLabelBehavior.onlyShowSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pro card")),
      bottomNavigationBar: NavigationBar(
        labelBehavior: labelBehavior,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: AppColor.primaryTeal,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.account_circle_rounded),
            icon: Icon(Icons.account_circle_outlined),
            label: 'Profile',
          ),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Decks'),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Statistics',
          ),
        ],
      ),
      body: <Widget>[
        Text("home"),
        DeckListScreen(),
        Text("screen"),
      ][currentPageIndex],
    );
  }
}
