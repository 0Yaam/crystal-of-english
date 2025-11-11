class NextSchedule {
  final int intervalDays;
  final int reps;
  final double easeFactor;

  NextSchedule(this.intervalDays, this.reps, this.easeFactor);
}



NextSchedule computeSM2({
  required int quality,
  int prevInterval = 0,
  int prevReps = 0,
  double prevEF = 2.5,
}) {
  double ef = prevEF;
  int reps = prevReps;
  int intervalDays;

  if (quality < 3) {
    reps = 0;
    intervalDays = 1;

  } else {
    reps = prevReps + 1;
    if (reps == 1) {
      intervalDays = 1;
    } else if (reps == 2) {
      intervalDays = 6;
    } else {
      intervalDays = ( (prevInterval > 0 ? prevInterval : 6) * ef ).round();
      if (intervalDays < 1) intervalDays = 1;
    }
  }

  ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  if (ef < 1.3) ef = 1.3;

  return NextSchedule(intervalDays, reps, ef);
}
