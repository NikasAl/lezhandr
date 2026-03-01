import 'motivation_models.dart';

/// All motivation texts database
class MotivationTexts {
  MotivationTexts._();

  static final List<MotivationText> all = [
    // THINKING - Развитие мышления
    const MotivationText(
      id: 'thinking_01',
      text: 'Каждая решенная задача — это гантель для твоего мозга: чем больше поднимаешь, тем сильнее становишься',
      category: MotivationCategory.thinking,
      tags: ['brain', 'strength', 'growth'],
    ),
    const MotivationText(
      id: 'thinking_02',
      text: 'Математика учит не только считать, но думать.',
      category: MotivationCategory.thinking,
      tags: ['math', 'physics', 'vision'],
    ),
    const MotivationText(
      id: 'thinking_03',
      text: 'Решая задачи сегодня, ты программируешь свой мозг на успех в любой сфере завтра',
      category: MotivationCategory.thinking,
      tags: ['future', 'success', 'programming'],
    ),
    const MotivationText(
      id: 'thinking_04',
      text: 'Математика — не про знание формул, а про понимание их происхождения. Выводи их сам!',
      category: MotivationCategory.thinking,
      tags: ['formulas', 'understanding', 'discovery'],
    ),
    const MotivationText(
      id: 'thinking_05',
      text: 'Только через задачи можно по-настоящему понять математику, физику и природу реальности',
      category: MotivationCategory.thinking,
      tags: ['reality', 'understanding', 'nature'],
    ),
    const MotivationText(
      id: 'thinking_06',
      text: 'Математику уже затем учить надо, что она ум в порядок приводит',
      category: MotivationCategory.thinking,
      tags: ['classic', 'mind', 'order'],
    ),
    const MotivationText(
      id: 'thinking_07',
      text: 'Физика — не формулы, а видение устройства мира глазами ученого',
      category: MotivationCategory.thinking,
      tags: ['physics', 'mind', 'order'],
    ), 

    // PRACTICAL - Практическая польза
    const MotivationText(
      id: 'practical_01',
      text: 'Знания из учебника останутся там же. А навыки, полученные при решении задач, пригодятся в реальной жизни каждый день',
      category: MotivationCategory.practical,
      tags: ['skills', 'real_life', 'practice'],
    ),
    const MotivationText(
      id: 'practical_02',
      text: 'Не знаешь, зачем тебе интегралы? Начни делать вещи, и интегралы пригодятся',
      category: MotivationCategory.practical,
      tags: ['integrals', 'action', 'understanding'],
    ),
    const MotivationText(
      id: 'practical_03',
      text: 'Каждая решенная задача — это шаг к тому, чтобы понимать, как устроен мир вокруг тебя',
      category: MotivationCategory.practical,
      tags: ['world', 'understanding', 'steps'],
    ),
    const MotivationText(
      id: 'practical_04',
      text: 'Невозможно применить на практике то, что не знаешь. Узнай математику — и увидишь её применения',
      category: MotivationCategory.practical,
      tags: ['practice', 'knowledge', 'application'],
    ),
    const MotivationText(
      id: 'practical_05',
      text: 'Задачи — это практическое знание. Теория без практики мертва',
      category: MotivationCategory.practical,
      tags: ['theory', 'practice', 'knowledge'],
    ),

    // SATISFACTION - Удовлетворение
    const MotivationText(
      id: 'satisfaction_01',
      text: 'Помнишь чувство, когда наконец-то решил сложную задачу? Это не просто ответ, это доказательство твоей силы',
      category: MotivationCategory.satisfaction,
      tags: ['achievement', 'strength', 'feeling'],
    ),
    const MotivationText(
      id: 'satisfaction_02',
      text: 'Лучший момент в учебе — когда после долгих попыток лампочка наконец загорается над головой',
      category: MotivationCategory.satisfaction,
      tags: ['eureka', 'success', 'effort'],
    ),
    const MotivationText(
      id: 'satisfaction_03',
      text: 'Решая задачи — ты собираешь пазл своего образования, где каждая деталь важна',
      category: MotivationCategory.satisfaction,
      tags: ['puzzle', 'education', 'importance'],
    ),
    const MotivationText(
      id: 'satisfaction_04',
      text: 'Чувство, когда понимаешь, КАК решать — лучше любого кофе. Заряжает на весь день!',
      category: MotivationCategory.satisfaction,
      tags: ['energy', 'understanding', 'motivation'],
    ),

    // CAREER - Будущее и карьера
    const MotivationText(
      id: 'career_01',
      text: 'Сегодня ты решаешь задачи в тетради, завтра — реальные проблемы в жизни. Навыки те же',
      category: MotivationCategory.career,
      tags: ['future', 'skills', 'problems'],
    ),
    const MotivationText(
      id: 'career_02',
      text: 'Хороший специалист в любой области — это человек, который умеет решать задачи. Начни с математических',
      category: MotivationCategory.career,
      tags: ['specialist', 'skills', 'professional'],
    ),
    const MotivationText(
      id: 'career_03',
      text: 'Диплом откроет двери, а умение решать сложные задачи обеспечит движение к целям',
      category: MotivationCategory.career,
      tags: ['career', 'value', 'indispensable'],
    ),
    const MotivationText(
      id: 'career_04',
      text: 'Инженеры, учёные, программисты — все они начали с решения задач. Этот путь начинается с задачников',
      category: MotivationCategory.career,
      tags: ['career', 'path', 'profession'],
    ),
    const MotivationText(
      id: 'career_05',
      text: 'Хороший специалист в любой области — это человек, который умеет решать задачи. Начни с физических',
      category: MotivationCategory.career,
      tags: ['specialist', 'skills', 'professional'],
    ),

    // PERSEVERANCE - Преодоление трудностей
    const MotivationText(
      id: 'perseverance_01',
      text: 'Самые сильные мышцы растут от тяжелых упражнений, а способности — от сложных задач',
      category: MotivationCategory.perseverance,
      tags: ['growth', 'difficulty', 'strength'],
    ),
    const MotivationText(
      id: 'perseverance_02',
      text: 'Хорошая задача решается три дня и три ночи. Не торопись, думай глубоко',
      category: MotivationCategory.perseverance,
      tags: ['patience', 'depth', 'thinking'],
    ),
    const MotivationText(
      id: 'perseverance_03',
      text: 'Если задача кажется слишком сложной — отлично! Значит, ты на пути к настоящему росту',
      category: MotivationCategory.perseverance,
      tags: ['growth', 'challenge', 'opportunity'],
    ),
    const MotivationText(
      id: 'perseverance_04',
      text: 'Не бойся ошибок. Каждая ошибка в решении — это шаг к правильному ответу и твоему опыту',
      category: MotivationCategory.perseverance,
      tags: ['mistakes', 'learning', 'experience'],
    ),
    const MotivationText(
      id: 'perseverance_05',
      text: 'Время, потраченное на задачи — это знания, опыт и лучшая инвестиция в будущее, которую можно сделать',
      category: MotivationCategory.perseverance,
      tags: ['time', 'investment', 'future'],
    ),
    const MotivationText(
      id: 'perseverance_06',
      text: 'Будь честен перед собой. Признай, если что-то не понимаешь — это первый шаг к пониманию',
      category: MotivationCategory.perseverance,
      tags: ['honesty', 'understanding', 'growth'],
    ),

    // ENERGETIC - Короткие и энергичные
    const MotivationText(
      id: 'energetic_01',
      text: 'Решил задачу — победил себя!',
      category: MotivationCategory.energetic,
      tags: ['victory', 'self', 'short'],
    ),
    const MotivationText(
      id: 'energetic_02',
      text: 'Сегодняшние уравнения — завтрашние возможности',
      category: MotivationCategory.energetic,
      tags: ['equations', 'opportunities', 'future'],
    ),
    const MotivationText(
      id: 'energetic_03',
      text: 'Одна задача — один шаг вперёд!',
      category: MotivationCategory.energetic,
      tags: ['progress', 'steps', 'action'],
    ),
    const MotivationText(
      id: 'energetic_04',
      text: 'Твой мозг способен на большее. Докажи это!',
      category: MotivationCategory.energetic,
      tags: ['potential', 'proof', 'challenge'],
    ),
    const MotivationText(
      id: 'energetic_05',
      text: 'Каждый гений начинал с простой задачи',
      category: MotivationCategory.energetic,
      tags: ['genius', 'beginning', 'inspiration'],
    ),

    // QUOTES - Цитаты великих
    const MotivationText(
      id: 'quote_01',
      text: 'Математику уже затем учить надо, что она ум в порядок приводит',
      category: MotivationCategory.quotes,
      tags: ['classic', 'mind', 'russian'],
    ),
    const MotivationText(
      id: 'quote_02',
      text: 'Вдохновение нужно в геометрии не меньше, чем в поэзии',
      category: MotivationCategory.quotes,
      tags: ['inspiration', 'geometry', 'poetry'],
    ),
    const MotivationText(
      id: 'quote_03',
      text: 'Математика — это музыка разума',
      category: MotivationCategory.quotes,
      tags: ['music', 'mind', 'beautiful'],
    ),
    const MotivationText(
      id: 'quote_04',
      text: 'Математика — царица наук, арифметика — царица математики',
      category: MotivationCategory.quotes,
      tags: ['queen', 'science', 'arithmetic'],
    ),
    const MotivationText(
      id: 'quote_05',
      text: 'Жизнь украшается двумя вещами: занятием математикой и её преподаванием',
      category: MotivationCategory.quotes,
      tags: ['life', 'teaching', 'passion'],
    ),

    // SESSION - Во время сессии
    const MotivationText(
      id: 'session_01',
      text: 'Не получается? Это нормально. Самые интересные открытия рождаются из тупиков',
      category: MotivationCategory.session,
      tags: ['stuck', 'discovery', 'patience'],
      trigger: 'stuck_15min',
    ),
    const MotivationText(
      id: 'session_02',
      text: 'Отдых — часть работы. Мозг обрабатывает информацию даже когда ты не думаешь о задаче',
      category: MotivationCategory.session,
      tags: ['rest', 'brain', 'processing'],
      trigger: 'session_30min',
    ),
    const MotivationText(
      id: 'session_03',
      text: 'Подсказка — не слабость, а инструмент. Даже великие математики советовались с коллегами',
      category: MotivationCategory.session,
      tags: ['hint', 'tool', 'collaboration'],
      trigger: 'hint_requested',
    ),
    const MotivationText(
      id: 'session_04',
      text: 'Ты уже потратил время. Теперь либо реши, либо извлеки урок. Оба варианта — победа',
      category: MotivationCategory.session,
      tags: ['time', 'lesson', 'victory'],
      trigger: 'session_long',
    ),
    const MotivationText(
      id: 'session_05',
      text: 'Иногда лучший шаг — отступить и посмотреть на задачу свежим взглядом завтра',
      category: MotivationCategory.session,
      tags: ['rest', 'perspective', 'tomorrow'],
      trigger: 'session_very_long',
    ),

    // STREAK - Про стрик
    const MotivationText(
      id: 'streak_01',
      text: '7 дней подряд! Ты формируешь привычку, которая изменит твою жизнь',
      category: MotivationCategory.streak,
      tags: ['streak', 'habit', 'milestone'],
      condition: 'streak_7',
    ),
    const MotivationText(
      id: 'streak_01b',
      text: 'Неделя практики! Твой мозг уже начал перестраиваться',
      category: MotivationCategory.streak,
      tags: ['streak', 'week', 'brain'],
      condition: 'streak_7',
    ),
    const MotivationText(
      id: 'streak_01c',
      text: '7 дней — это когда привычка начинает закрепляться. Не останавливайся!',
      category: MotivationCategory.streak,
      tags: ['streak', 'habit', 'continue'],
      condition: 'streak_7',
    ),
    const MotivationText(
      id: 'streak_10',
      text: '10 дней подряд! Ты доказал, что это не случайность',
      category: MotivationCategory.streak,
      tags: ['streak', 'consistency', 'proof'],
      condition: 'streak_10',
    ),
    const MotivationText(
      id: 'streak_10b',
      text: 'Дважды по пять! Прогресс неминуем',
      category: MotivationCategory.streak,
      tags: ['streak', 'numbers', 'fun'],
      condition: 'streak_10',
    ),
    const MotivationText(
      id: 'streak_14',
      text: '2 недели! Привычка укоренилась. Теперь это часть тебя',
      category: MotivationCategory.streak,
      tags: ['streak', 'two_weeks', 'habit'],
      condition: 'streak_14',
    ),
    const MotivationText(
      id: 'streak_14b',
      text: '14 дней — достаточно, чтобы мозг перестал сопротивляться. Легче станет!',
      category: MotivationCategory.streak,
      tags: ['streak', 'brain', 'easier'],
      condition: 'streak_14',
    ),
    const MotivationText(
      id: 'streak_21',
      text: '21 день! Психологи говорят, это срок формирования привычки. Ты молодец!',
      category: MotivationCategory.streak,
      tags: ['streak', 'psychology', 'habit'],
      condition: 'streak_21',
    ),
    const MotivationText(
      id: 'streak_21b',
      text: 'Три недели подряд! Ты теперь решаешь задачи на автомате',
      category: MotivationCategory.streak,
      tags: ['streak', 'automatic', 'success'],
      condition: 'streak_21',
    ),
    const MotivationText(
      id: 'streak_02',
      text: '30 дней! Это уже не привычка — это образ жизни',
      category: MotivationCategory.streak,
      tags: ['streak', 'lifestyle', 'milestone'],
      condition: 'streak_30',
    ),
    const MotivationText(
      id: 'streak_02b',
      text: 'Месяц без пропусков! Ты входишь в число немногих, кто доводит дело до конца',
      category: MotivationCategory.streak,
      tags: ['streak', 'month', 'dedication'],
      condition: 'streak_30',
    ),
    const MotivationText(
      id: 'streak_02c',
      text: '30 дней решения задач — это уже привычка. Самая полезная',
      category: MotivationCategory.streak,
      tags: ['streak', 'pride', 'milestone'],
      condition: 'streak_30',
    ),
    const MotivationText(
      id: 'streak_03',
      text: '100 дней подряд! Ты входишь в топ 1% людей по упорству',
      category: MotivationCategory.streak,
      tags: ['streak', 'top', 'dedication'],
      condition: 'streak_100',
    ),
    const MotivationText(
      id: 'streak_04',
      text: 'Не прерывай цепь! Один день пропуска — и начинай сначала',
      category: MotivationCategory.streak,
      tags: ['warning', 'chain', 'motivation'],
      trigger: 'streak_risk',
    ),
    const MotivationText(
      id: 'streak_05',
      text: 'С возвращением! Новый стрик начинается сейчас, и он будет ещё длиннее',
      category: MotivationCategory.streak,
      tags: ['return', 'new_start', 'encouragement'],
      trigger: 'streak_broken',
    ),
    const MotivationText(
      id: 'streak_06',
      text: 'Огонь решения задач горит уже {days}! Не дай ему погаснуть',
      category: MotivationCategory.streak,
      tags: ['fire', 'days', 'continue'],
      trigger: 'streak_active',
    ),
    const MotivationText(
      id: 'streak_06b',
      text: '{days} подряд! Каждый день делает тебя сильнее',
      category: MotivationCategory.streak,
      tags: ['days', 'strength', 'progress'],
      trigger: 'streak_active',
    ),
    const MotivationText(
      id: 'streak_06c',
      text: 'Твоя серия: {days}. Продолжай в том же духе!',
      category: MotivationCategory.streak,
      tags: ['series', 'continue', 'encouragement'],
      trigger: 'streak_active',
    ),

    // ACHIEVEMENTS - При достижениях
    const MotivationText(
      id: 'achievement_01',
      text: '🎉 10 задач решено! Ты на верном пути!',
      category: MotivationCategory.achievements,
      tags: ['milestone', 'beginner', 'progress'],
      condition: 'tasks_10',
    ),
    const MotivationText(
      id: 'achievement_02',
      text: '🏆 50 задач! Ты уже опытный решатель!',
      category: MotivationCategory.achievements,
      tags: ['milestone', 'experienced', 'progress'],
      condition: 'tasks_50',
    ),
    const MotivationText(
      id: 'achievement_03',
      text: '⭐ 100 задач за плечами! Ты мастер своего дела!',
      category: MotivationCategory.achievements,
      tags: ['milestone', 'master', 'achievement'],
      condition: 'tasks_100',
    ),
    const MotivationText(
      id: 'achievement_04',
      text: '💎 500 задач! Ты в элите! Таких людей — единицы!',
      category: MotivationCategory.achievements,
      tags: ['elite', 'rare', 'legendary'],
      condition: 'tasks_500',
    ),
    const MotivationText(
      id: 'achievement_05',
      text: '🔥 1000 XP заработано! Твой мозг становится сильнее с каждой задачей!',
      category: MotivationCategory.achievements,
      tags: ['xp', 'growth', 'milestone'],
      condition: 'xp_1000',
    ),
    const MotivationText(
      id: 'achievement_06',
      text: '💡 Первое озарение! Эти моменты — золото учёного!',
      category: MotivationCategory.achievements,
      tags: ['epiphany', 'first', 'special'],
      condition: 'first_epiphany',
    ),
    const MotivationText(
      id: 'achievement_07',
      text: '📚 Решены задачи из 5 разных источников! Разносторонность — это сила!',
      category: MotivationCategory.achievements,
      tags: ['sources', 'diversity', 'strength'],
      condition: 'sources_5',
    ),
  ];
}
