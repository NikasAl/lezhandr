import '../models/user.dart';
import '../models/problem.dart';
import '../models/solution.dart';
import '../models/gamification.dart';

/// Mock data for demo mode
class MockData {
  static UserModel get demoUser => UserModel(
        id: 1,
        username: 'Демо Пользователь',
        isAnonymous: false,
        role: UserRole.user,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

  static List<SourceModel> get sources => [
        SourceModel(id: 1, name: 'Кижнер', slug: 'kizhner'),
        SourceModel(id: 2, name: 'Рымкевич', slug: 'rymkevich'),
        SourceModel(id: 3, name: 'Сборник', slug: 'sbornik'),
      ];

  static List<TagModel> get tags => [
        TagModel(id: 1, name: 'Механика', slug: 'mechanics'),
        TagModel(id: 2, name: 'Термодинамика', slug: 'thermodynamics'),
        TagModel(id: 3, name: 'Электричество', slug: 'electricity'),
        TagModel(id: 4, name: 'Оптика', slug: 'optics'),
        TagModel(id: 5, name: 'Кинематика', slug: 'kinematics'),
      ];

  static List<ProblemModel> get problems => [
        ProblemModel(
          id: 1,
          sourceId: 1,
          reference: '1.1',
          conditionText:
              'Тело движется равноускоренно без начальной скорости. За третью секунду оно прошло путь 5 м. Какой путь пройдет тело за первые три секунды?',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          source: sources[0],
          tags: [tags[4], tags[0]],
        ),
        ProblemModel(
          id: 2,
          sourceId: 1,
          reference: '1.2',
          conditionText:
              'Камень брошен вертикально вверх со скоростью 20 м/с. На какую высоту поднимется камень и через какое время он упадет обратно?',
          createdAt: DateTime.now().subtract(const Duration(days: 9)),
          source: sources[0],
          tags: [tags[4], tags[0]],
        ),
        ProblemModel(
          id: 3,
          sourceId: 2,
          reference: '234',
          conditionText:
              'Определите КПД тепловой машины, если за цикл она получает от нагревателя 1000 Дж и отдает холодильнику 600 Дж.',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
          source: sources[1],
          tags: [tags[1]],
        ),
        ProblemModel(
          id: 4,
          sourceId: 2,
          reference: '567',
          conditionText:
              'Электрон влетает в однородное магнитное поле перпендикулярно линиям индукции со скоростью 10⁷ м/с. Индукция поля 0,1 Тл. Определите радиус окружности, по которой движется электрон.',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          source: sources[1],
          tags: [tags[2]],
        ),
        ProblemModel(
          id: 5,
          sourceId: 3,
          reference: 'A12',
          conditionText:
              'Предмет находится на расстоянии 20 см от собирающей линзы с фокусным расстоянием 15 см. На каком расстоянии от линзы получится изображение?',
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
          source: sources[2],
          tags: [tags[3]],
        ),
        ProblemModel(
          id: 6,
          sourceId: 1,
          reference: '2.15',
          conditionText:
              'Автомобиль движется по закруглению дороги радиусом 50 м со скоростью 36 км/ч. Каково центростремительное ускорение автомобиля?',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          source: sources[0],
          tags: [tags[4]],
        ),
        ProblemModel(
          id: 7,
          sourceId: 2,
          reference: '890',
          conditionText:
              'Идеальный газ совершает работу 300 Дж при изобарном расширении. Какое количество теплоты было передано газу?',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
          source: sources[1],
          tags: [tags[1]],
        ),
        ProblemModel(
          id: 8,
          sourceId: 3,
          reference: 'B5',
          conditionText:
              'Два точечных заряда 10 нКл и -10 нКл находятся на расстоянии 20 см друг от друга. Определите напряженность поля в точке, находящейся на середине отрезка, соединяющего заряды.',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          source: sources[2],
          tags: [tags[2]],
        ),
      ];

  static List<SolutionModel> get activeSolutions => [
        SolutionModel(
          id: 1,
          problemId: 1,
          userId: 1,
          status: SolutionStatus.active,
          totalMinutes: 25.5,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          problem: problems[0],
        ),
        SolutionModel(
          id: 2,
          problemId: 3,
          userId: 1,
          status: SolutionStatus.active,
          totalMinutes: 10.0,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          problem: problems[2],
        ),
      ];

  static GamificationModel get gamification => GamificationModel(
        totalXp: 1250.0,
        currentHearts: 4,
        maxHearts: 5,
        streakCurrent: 7,
        streakMax: 14,
        solvedTasksToday: 3,
      );
}
