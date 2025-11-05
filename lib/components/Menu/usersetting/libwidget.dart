import 'package:flutter/material.dart';

class GoalDropdown extends StatefulWidget {
  int userValue;
  final void Function(int) onGoalSelected; // callback
  GoalDropdown({required this.onGoalSelected, required this.userValue});
  @override
  _GoalDropdownState createState() => _GoalDropdownState();
}

class _GoalDropdownState extends State<GoalDropdown> {
  String? selectedGoal ;
  @override
  void initState() {
    super.initState();
    // Initialize from parent
    selectedGoal = widget.userValue.toString();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900], // dark grey background
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedGoal,
        dropdownColor: Colors.grey[850],
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.teal, // color when not focused
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.red, // color when focused
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.grey[900], // background color
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.tealAccent),
        style: TextStyle(color: Colors.white, fontSize: 16),
        items: [
          DropdownMenuItem(
            value: '15',
            child: Text(
              '15 minutes',
              style: TextStyle(
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.teal, Colors.red, Colors.yellow],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
          ),
          DropdownMenuItem(
            value: '30',
            child: Text(
              '30 minutes',
              style: TextStyle(
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [Colors.teal, Colors.red, Colors.yellow],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
          ),
          DropdownMenuItem(
            value: '60',
            child: Text(
              '60 minutes',
              style: TextStyle(
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [
                      Colors.teal,
                      const Color.fromARGB(255, 204, 133, 128),
                      Colors.yellow,
                    ],
                  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            selectedGoal = value;
          });
          widget.onGoalSelected(int.parse(value!));
        },
      ),
    );
  }
}

class UserText extends StatelessWidget {
  final Color textColor;
  final String text;
  const UserText({super.key, required this.textColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: textColor, fontSize: 30));
  }
}

class BorderContainer extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;

  const BorderContainer({
    super.key,
    required this.child,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

class StreakLinearProgress extends StatefulWidget {
  final int streak;

  const StreakLinearProgress({super.key, required this.streak});

  @override
  State<StreakLinearProgress> createState() => _StreakLinearProgressState();
}

class _StreakLinearProgressState extends State<StreakLinearProgress> {
  int goalDay = 7;
  double getProgress() {
    if (widget.streak <= 7) return widget.streak / 7;
    if (widget.streak <= 30) return (widget.streak - 7) / (30 - 7);
    if (widget.streak <= 365) return (widget.streak - 30) / (365 - 30);
    return 1.0;
  }

  void updateGoalDay() {
    if (widget.streak <= 7) {
      goalDay = 7;
    } else if (widget.streak <= 30) {
      goalDay = 30;
    } else if (widget.streak <= 365) {
      goalDay = 365;
    } else {
      goalDay = 365;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 400,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          UserText(
            textColor: Colors.orange,
            text: 'Streak Progress: ${widget.streak}/$goalDay days',
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
              },
              child: LinearProgressIndicator(
                value: getProgress(),
                minHeight: 20,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(
                  Colors.white,
                ), // color ignored by shader
              ),
            ),
          ),
        ],
      ),
    );
  }
}
