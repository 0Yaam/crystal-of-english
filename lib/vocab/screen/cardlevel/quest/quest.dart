import 'package:flutter/material.dart';
import 'dart:math';

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> tasks = [
    {"name": "Finish 10 words", "reward": 100, "done": false},
    {"name": "Review 3 cards", "reward": 150, "done": false},
    {"name": "Earn 1 streak", "reward": 200, "done": false},
    {"name": "Train 5 min", "reward": 120, "done": false},
    {"name": "Claim daily bonus", "reward": 50, "done": false},
  ];

  late AnimationController _controller;
  late Animation<double> _animation;
  int money = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  void toggleTask(int index) {
  setState(() {
    tasks[index]["done"] = !tasks[index]["done"];
    final int reward = tasks[index]["reward"] as int;
    if (tasks[index]["done"]) {
      money += reward;
    } else {
      money -= reward;
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Quests",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // 💰 Top bar (total money)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 62, 0, 73), Color.fromARGB(255, 0, 9, 24)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  '$money Coins',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return GestureDetector(
                      onTap: () => toggleTask(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 20),
                        width: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: task["done"]
                                ? [Colors.greenAccent, Colors.teal]
                                : [Colors.deepPurple, Colors.indigoAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Icon(
                                task["done"]
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task["name"],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on,
                                          color: Colors.amber, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        "+${task["reward"]}",
                                        style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    height: 6,
                                    width: task["done"] ? 180 : 80,
                                    decoration: BoxDecoration(
                                      color: task["done"]
                                          ? Colors.greenAccent
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
