import 'package:flutter/material.dart';
import 'package:mygame/components/Menu/usersetting/libwidget.dart';
import 'package:mygame/main.dart';
import 'package:mygame/user/user.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late Future<User> userFuture;

  @override
  void initState() {
    super.initState();
    _updateUserStreak();
    userFuture = UserDatabase.instance.getUser(1);
  }

  void _refresh() {
    setState(() {
      userFuture = UserDatabase.instance.getUser(1);
    });
  }

  void _updateUserStreak() async {
    await UserDatabase.instance.updateStreak();
    _refresh(); // reload UI
  }
  void _updateUserGoal(int newGoal) async {
    await UserDatabase.instance.UpdateGoal(newGoal);
    _refresh(); // reload UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: UserText(text: "user profile", textColor: Colors.white),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.redAccent,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<User>(
        future: userFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data!;
          return Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    SizedBox(height: 20),
                    BorderContainer(
                      padding: const EdgeInsets.all(20),
                      borderColor: Colors.teal,
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UserText(
                            text: 'Name :${user.name}',
                            textColor: Colors.tealAccent, // teal
                          ),
                          SizedBox(height: 20),
                          UserText(
                            text: 'Level: ${user.level}',
                            textColor: Colors.tealAccent,
                          ),
                          UserText(
                            text: '🔥 Streak: ${user.streak}',
                            textColor: Colors.redAccent, // red
                          ),
                          UserText(
                            text:
                                'Last Login: ${user.lastLoginDate.toString().split(' ')[0]}',
                            textColor: Colors.orangeAccent, // orange
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StreakLinearProgress(streak: user.streak),
                    BorderContainer(
                      borderColor: const Color.fromARGB(255, 150, 80, 0),
                      borderRadius: 16,
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          UserText(
                            text: 'Time In Game Goal:',
                            textColor: Colors.yellowAccent, // yellow
                          ),
                          SizedBox(
                            height: 85,
                            width: 200,
                            child: GoalDropdown(
                              userValue: user.goal,
                              onGoalSelected: (int minutes) async {
                                _updateUserGoal(minutes);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
