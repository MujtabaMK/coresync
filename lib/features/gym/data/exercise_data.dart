import '../domain/exercise_model.dart';

class ExerciseData {
  ExerciseData._();

  static const List<String> _categories = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Cardio',
  ];

  static List<String> get categories => _categories;

  static final Map<String, List<ExerciseModel>> _exercises = {
    'Chest': const [
      ExerciseModel(
        name: 'Bench Press',
        youtubeUrl: 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
        category: 'Chest',
      ),
      ExerciseModel(
        name: 'Push-ups',
        youtubeUrl: 'https://www.youtube.com/watch?v=IODxDxX7oi4',
        category: 'Chest',
      ),
      ExerciseModel(
        name: 'Dumbbell Fly',
        youtubeUrl: 'https://www.youtube.com/watch?v=eozdVDA78K0',
        category: 'Chest',
      ),
      ExerciseModel(
        name: 'Cable Crossover',
        youtubeUrl: 'https://www.youtube.com/watch?v=taI4XduLpTk',
        category: 'Chest',
      ),
      ExerciseModel(
        name: 'Incline Dumbbell Press',
        youtubeUrl: 'https://www.youtube.com/watch?v=8iPEnn-ltC8',
        category: 'Chest',
      ),
    ],
    'Back': const [
      ExerciseModel(
        name: 'Pull-ups',
        youtubeUrl: 'https://www.youtube.com/watch?v=eGo4IYlbE5g',
        category: 'Back',
      ),
      ExerciseModel(
        name: 'Barbell Row',
        youtubeUrl: 'https://www.youtube.com/watch?v=FWJR5Ve8bnQ',
        category: 'Back',
      ),
      ExerciseModel(
        name: 'Lat Pulldown',
        youtubeUrl: 'https://www.youtube.com/watch?v=CAwf7n6Luuc',
        category: 'Back',
      ),
      ExerciseModel(
        name: 'Deadlift',
        youtubeUrl: 'https://www.youtube.com/watch?v=op9kVnSso6Q',
        category: 'Back',
      ),
      ExerciseModel(
        name: 'Seated Cable Row',
        youtubeUrl: 'https://www.youtube.com/watch?v=GZbfZ033f74',
        category: 'Back',
      ),
    ],
    'Shoulders': const [
      ExerciseModel(
        name: 'Overhead Press',
        youtubeUrl: 'https://www.youtube.com/watch?v=2yjwXTZQDDI',
        category: 'Shoulders',
      ),
      ExerciseModel(
        name: 'Lateral Raise',
        youtubeUrl: 'https://www.youtube.com/watch?v=3VcKaXpzqRo',
        category: 'Shoulders',
      ),
      ExerciseModel(
        name: 'Face Pull',
        youtubeUrl: 'https://www.youtube.com/watch?v=rep-qVOkqgk',
        category: 'Shoulders',
      ),
      ExerciseModel(
        name: 'Arnold Press',
        youtubeUrl: 'https://www.youtube.com/watch?v=6Z15_WdXmVw',
        category: 'Shoulders',
      ),
    ],
    'Arms': const [
      ExerciseModel(
        name: 'Bicep Curl',
        youtubeUrl: 'https://www.youtube.com/watch?v=ykJmrZ5v0Oo',
        category: 'Arms',
      ),
      ExerciseModel(
        name: 'Tricep Dip',
        youtubeUrl: 'https://www.youtube.com/watch?v=0326dy_-CzM',
        category: 'Arms',
      ),
      ExerciseModel(
        name: 'Hammer Curl',
        youtubeUrl: 'https://www.youtube.com/watch?v=zC3nLlEvin4',
        category: 'Arms',
      ),
      ExerciseModel(
        name: 'Skull Crusher',
        youtubeUrl: 'https://www.youtube.com/watch?v=d_KZxkY_0cM',
        category: 'Arms',
      ),
    ],
    'Legs': const [
      ExerciseModel(
        name: 'Squat',
        youtubeUrl: 'https://www.youtube.com/watch?v=ultWZbUMPL8',
        category: 'Legs',
      ),
      ExerciseModel(
        name: 'Lunges',
        youtubeUrl: 'https://www.youtube.com/watch?v=QOVaHwm-Q6U',
        category: 'Legs',
      ),
      ExerciseModel(
        name: 'Leg Press',
        youtubeUrl: 'https://www.youtube.com/watch?v=IZxyjW7MPJQ',
        category: 'Legs',
      ),
      ExerciseModel(
        name: 'Calf Raise',
        youtubeUrl: 'https://www.youtube.com/watch?v=gwLzBJYoWlI',
        category: 'Legs',
      ),
      ExerciseModel(
        name: 'Romanian Deadlift',
        youtubeUrl: 'https://www.youtube.com/watch?v=jEy_czb3RKA',
        category: 'Legs',
      ),
    ],
    'Core': const [
      ExerciseModel(
        name: 'Plank',
        youtubeUrl: 'https://www.youtube.com/watch?v=ASdvN_XEl_c',
        category: 'Core',
      ),
      ExerciseModel(
        name: 'Crunches',
        youtubeUrl: 'https://www.youtube.com/watch?v=Xyd_fa5zoEU',
        category: 'Core',
      ),
      ExerciseModel(
        name: 'Russian Twist',
        youtubeUrl: 'https://www.youtube.com/watch?v=wkD8rjkodUI',
        category: 'Core',
      ),
      ExerciseModel(
        name: 'Leg Raise',
        youtubeUrl: 'https://www.youtube.com/watch?v=JB2oyawG9KI',
        category: 'Core',
      ),
    ],
    'Cardio': const [
      ExerciseModel(
        name: 'Running',
        youtubeUrl: 'https://www.youtube.com/watch?v=_kGESn8ArrU',
        category: 'Cardio',
      ),
      ExerciseModel(
        name: 'Jump Rope',
        youtubeUrl: 'https://www.youtube.com/watch?v=FJmRQ5iTXKE',
        category: 'Cardio',
      ),
      ExerciseModel(
        name: 'Burpees',
        youtubeUrl: 'https://www.youtube.com/watch?v=dZgVxmf6jkA',
        category: 'Cardio',
      ),
      ExerciseModel(
        name: 'Mountain Climbers',
        youtubeUrl: 'https://www.youtube.com/watch?v=nmwgirgXLYM',
        category: 'Cardio',
      ),
    ],
  };

  static List<ExerciseModel> getByCategory(String category) {
    return _exercises[category] ?? [];
  }
}
