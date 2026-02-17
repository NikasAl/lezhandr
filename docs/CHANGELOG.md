# Лежандр — Flutter клиент MindVector

## История изменений (Changelog)

### Версия 0.3.0 (Текущая)

#### Новые функции

##### ✨ Редактирование условия и тегов задачи
**Функция:** Пользователь может редактировать условие и теги задачи после её создания.

**Реализовано:**
1. Меню действий (⋮) в AppBar экрана задачи с опциями:
   - Редактировать текст условия
   - Загрузить фото условия
   - Распознать текст (OCR)
   - Открыть фото в полном размере
2. Диалог редактирования тегов с поиском по мере набора
3. Переключение между текстом и фото условия

**Изменённые файлы:**
- `lib/presentation/screens/problems/problem_detail_screen.dart`
- `lib/presentation/providers/problems_provider.dart`

---

##### ✨ Просмотр фото условия при наличии текста
**Функция:** Если у задачи есть и текст условия, и фото, можно переключаться между ними.

**Реализовано:**
1. Кнопка переключения "Текст/Фото" в карточке условия
2. Кнопка "Посмотреть фото условия" под текстом
3. Масштабирование фото при клике

**Изменённые файлы:**
- `lib/presentation/screens/problems/problem_detail_screen.dart`

---

##### ✨ Условие задачи в сессии решения
**Функция:** Условие задачи отображается прямо в карточке во время сессии.

**Реализовано:**
1. Текстовое условие с поддержкой LaTeX
2. Изображение условия с возможностью открытия в полном размере
3. Кнопка "Развернуть" для перехода к полной задаче

**Изменённые файлы:**
- `lib/presentation/screens/solutions/solution_session_screen.dart`

---

#### Исправления ошибок

##### 1. Кнопка "Сохранить ответ" была неактивна
**Проблема:** При ответе на вопрос в сессии кнопка сохранения оставалась неактивной.
**Решение:** Добавлен `onChanged` callback для отслеживания ввода текста.

##### 2. Фото решения не отображалось после загрузки
**Проблема:** После загрузки фото решения без OCR изображение не появлялось в карточке.
**Решение:** Добавлен `invalidate` провайдера после загрузки фото.

##### 3. Формулы LaTeX в подсказках отображались некорректно
**Проблема:** Текст подсказок мог содержать формулы, но они не рендерились.
**Решение:** Использован виджет `MarkdownWithMath` для отображения подсказок.

##### 4. Символы $ в hintText вызывали ошибку компиляции
**Проблема:** Строка с `$...` интерпретировалась как string interpolation.
**Решение:** Использован raw string `r'...'`.

---

### Версия 0.2.0

#### Новые функции

##### ✨ Автоматическое предложение OCR после загрузки фото
**Проблема:** После загрузки фото условия/решения пользователь не получал подтверждения и должен был вручную искать кнопку OCR.

**Решение:** Реализован полный флоу как в CLI версии (mv_screens.py:469):
1. После успешной загрузки фото показывается SnackBar с подтверждением
2. Для категорий `condition` и `solution` автоматически предлагается распознать текст
3. Пользователь выбирает AI-персону (Кот Базис, Петрович, Лежандр)
4. Запускается OCR и показывается результат

**Изменённые файлы:**
- `lib/presentation/screens/camera/camera_screen.dart`
  - Добавлен метод `_offerOcrAfterUpload()` для предложения OCR
  - Добавлен импорт `persona_selector.dart` и `problems_provider.dart`
  - Добавлено обновление `problemProvider` после загрузки

**UI поток:**
```
Фото → [Отправить] → "Фото загружено" → "Распознать текст?" → Выбор персоны → OCR → Результат
```

---

##### ✨ Артефакты сессии (Озарения, Вопросы, Подсказки)
**Функция:** Полная реализация работы с артефактами во время сессии решения.

**Реализовано:**
1. Создание озарений с указанием силы (1-3 звезды)
2. Создание вопросов с возможностью фото контекста
3. Ответы на вопросы вручную или через AI
4. Черновики подсказок с AI-генерацией
5. Просмотр всех артефактов в деталях решения

**Изменённые файлы:**
- `lib/data/repositories/artifacts_repository.dart`
- `lib/presentation/providers/artifacts_provider.dart`
- `lib/presentation/screens/solutions/solution_session_screen.dart`
- `lib/presentation/screens/solutions/solution_detail_screen.dart`

---

### Версия 0.1.0

#### Исправления ошибок

##### 1. ProviderScope отсутствовал (Критическая ошибка)
**Проблема:** Приложение падало с ошибкой `Bad state: No ProviderScope found`
**Причина:** Riverpod требует `ProviderScope` в корневом виджете приложения
**Решение:** Добавлен `ProviderScope` в `main.dart`:
```dart
runApp(
  const ProviderScope(
    child: LezhandrApp(),
  ),
);
```

##### 2. Отсутствовала локализация ru_RU (Критическая ошибка)
**Проблема:** `This application's locale, ru_RU, is not supported by all of its localization delegates`
**Решение:**
- Добавлен пакет `flutter_localizations` в `pubspec.yaml`
- Добавлены `localizationsDelegates` в `MaterialApp.router`:
```dart
localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```

##### 3. Несовместимость версий intl
**Проблема:** `intl ^0.19.0` несовместим с `flutter_localizations`, который требует `intl 0.20.2`
**Решение:** Обновлена версия intl в `pubspec.yaml`:
```yaml
intl: ^0.20.2
```

##### 4. Конфликт с Clang компилятором (Linux)
**Проблема:** `flutter_secure_storage 9.0.0` выдавал ошибки deprecated literal operator
**Решение:** Обновлена версия:
```yaml
flutter_secure_storage: ^10.0.0
```

##### 5. Отсутствующие шрифты и ресурсы
**Проблема:** `unable to locate asset entry in pubspec.yaml: "assets/fonts/JetBrainsMono-Regular.ttf"`
**Решение:** Закомментированы секции assets и fonts в `pubspec.yaml`

##### 6. Null safety в моделях данных (Критическая ошибка)
**Проблема:** `type 'Null' is not a subtype of type 'int' in type cast`
**Причина:** API возвращает null для некоторых полей, а модели ожидали non-null значения
**Решение:** Полностью переписаны все модели данных с:
- Nullable полями для опциональных данных
- Безопасными `fromJson` методами с default значениями
- Ручной реализацией `toJson` вместо кодогенерации
- Удалены `.g.dart` файлы

**Затронутые файлы:**
- `lib/data/models/problem.dart`
- `lib/data/models/solution.dart`
- `lib/data/models/user.dart`
- `lib/data/models/gamification.dart`
- `lib/data/models/billing.dart`

##### 7. Null safety в UI экранах
**Проблема:** `Property 'name' cannot be accessed on 'SourceModel?' because it is potentially null`
**Решение:** Добавлен геттер `sourceName` в `ProblemModel` и использован в экранах:
```dart
String get sourceName => source?.name ?? 'Unknown';
```

---

## Архитектура проекта

### Структура директорий
```
lib/
├── main.dart                 # Точка входа
├── app.dart                  # Корневой виджет с MaterialApp
├── core/
│   ├── config/
│   │   └── app_config.dart   # Конфигурация (API URL, таймауты)
│   ├── theme/
│   │   └── app_theme.dart    # Material 3 тема
│   ├── router/
│   │   └── app_router.dart   # GoRouter навигация
│   └── motivation/
│       ├── motivation_engine.dart    # Движок мотивации
│       └── motivation_models.dart    # Модели мотивации
├── data/
│   ├── models/               # DTO модели
│   ├── repositories/         # Репозитории для API
│   ├── services/
│   │   └── api_client.dart   # Dio HTTP клиент
│   └── storage/              # SecureStorage обёртки
├── domain/                   # (Планируется) Business logic
└── presentation/
    ├── providers/            # Riverpod providers
    ├── screens/              # UI экраны
    └── widgets/              # Переиспользуемые виджеты
```

### Используемые технологии
- **Flutter 3.x** с Material 3
- **Riverpod 2.x** — управление состоянием
- **GoRouter 13.x** — навигация
- **Dio 5.x** — HTTP клиент
- **Flutter Secure Storage 10.x** — безопасное хранение токенов

### Поток данных
```
UI (screens) 
    ↓ вызывает
Providers (Riverpod)
    ↓ использует
Repositories
    ↓ делает запросы через
ApiClient (Dio)
    ↓ отправляет на
Backend API
```

---

## Известные проблемы и баги

Актуальный список багов и их статусов см. в документе **BUG_STATUS.md**.

### Критические (Требуют исправления)

#### BUG-AUTH-001: Автоматический вход при истечении токена
**Приоритет:** Высокий
**Статус:** Открыт
**Описание:** При истечении токена создаётся новый анонимный аккаунт вместо переподключения к существующему.

#### BUG-COMM-001: Активные задачи от других пользователей
**Приоритет:** Высокий
**Статус:** Открыт
**Описание:** В списке активных задач отображаются решения других пользователей.

---

## План дальнейшей разработки

### Фаза 1: Критические исправления
- [ ] **BUG-AUTH-001:** Автоматическое переподключение при истечении токена
- [ ] **BUG-UI-001:** Улучшение экрана первого входа
- [ ] **BUG-COMM-001:** Фильтрация активных задач по пользователю (server-side)

### Фаза 2: Комьюнити (P2)
- [ ] Комментарии к задачам и решениям
- [ ] Лайки/дизлайки
- [ ] Статьи

### Фаза 3: Концепции и анализ знаний (P2)
- [ ] Экран списка концепций
- [ ] Экран детализации концепции
- [ ] Граф связей между концепциями
- [ ] AI-анализ задач и решений

### Фаза 4: Финансы (P2)
- [ ] UI пополнения баланса
- [ ] История транзакций

---

## Инструкции для разработчиков

### Требования к среде
- Flutter SDK 3.x
- Dart 3.x
- Linux: GTK 3.0+, CMake, Ninja
- Android: Android SDK 21+

### Запуск проекта
```bash
# Клонирование (если нужно)
git clone <repo-url>
cd lezhandr

# Получить зависимости
flutter pub get

# Запуск на Linux
flutter run -d linux

# Запуск на Android
flutter run -d android

# Сборка release
flutter build linux --release
flutter build apk --release
```

### Правила создания моделей данных

**ВАЖНО:** Не использовать json_serializable для моделей API!

Причина: API может возвращать null для любых полей. Использовать ручную реализацию:

```dart
// ✅ Правильно
class MyModel {
  final int? id;
  final String name;

  MyModel({this.id, this.name = ''});

  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

// ❌ Неправильно (создаст проблемы с null)
@JsonSerializable()
class MyModel {
  final int id;  // Упадёт если API вернёт null
  ...
}
```

### Добавление новых экранов

1. Создать файл в `lib/presentation/screens/<category>/<name>_screen.dart`
2. Добавить маршрут в `lib/core/router/app_router.dart`
3. Создать провайдеры данных в `lib/presentation/providers/`
4. Добавить импорт и тестировать

### Код-стайл

- Использовать `const` где возможно для оптимизации
- Nullable типы (`Type?`) для опциональных данных из API
- Default значения для обязательных полей в `fromJson`
- Геттеры для вычисляемых свойств (как `sourceName`)
- Документировать public API комментариями `///`

### Структура коммитов

```
feat: добавлена новая функция
fix: исправление бага
docs: обновление документации
refactor: рефакторинг без изменения функционала
style: форматирование кода
test: добавление тестов
```

---

## Ссылки и ресурсы

- **API документация:** См. `KODA.md` (оригинальный проект MindVector)
- **Статус багов:** См. `BUG_STATUS.md`
- **Оригинальный CLI клиент:** Python MindVector
- **Flutter документация:** https://docs.flutter.dev
- **Riverpod документация:** https://riverpod.dev
- **GoRouter документация:** https://pub.dev/packages/go_router
- **Material 3:** https://m3.material.io

---

*Документация создана для проекта Лежандр — Flutter клиент MindVector*
