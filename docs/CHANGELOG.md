# Лежандр — Flutter клиент MindVector

## История изменений (Changelog)

### Версия 0.1.0 (Текущая)

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

### Критические (Требуют исправления)

#### BUG-001: Активные задачи показываются от других пользователей
**Приоритет:** Высокий  
**Статус:** Открыт  
**Описание:** В списке активных задач отображаются решения других пользователей. Пользователь может "возобновить" чужую сессию.  
**Место:** `home_screen.dart` → `_ActiveSolutionsCard`, `solutions_provider.dart`  
**Предполагаемая причина:** API `/solutions` возвращает все активные решения без фильтрации по user_id  

**Необходимые действия:**
1. **[Server]** Добавить фильтрацию по user_id в эндпоинте `/solutions`
2. **[Client]** Добавить параметр `user_id` в запрос
3. **[Client]** Разделить "Мои активные задачи" и "Задачи команды" (если применимо)

#### BUG-002: Не работают некоторые кнопки
**Приоритет:** Средний  
**Статус:** Открыт  
**Описание:** Часть кнопок не имеет реализации (TODO заглушки)  

**Известные неработающие элементы:**
| Кнопка | Экран | Действие |
|--------|-------|----------|
| Уведомления (колокольчик) | HomeScreen AppBar | Нет обработчика |
| "Анализ концепций" | HomeScreen | Нет навигации |
| Создать задачу (FAB +) | LibraryScreen | Нет реализации |
| Тёмная тема | ProfileScreen | Переключатель не связан |
| Уведомления | ProfileScreen | Переключатель не связан |
| Вибрация | ProfileScreen | Переключатель не связан |

### Минорные проблемы

#### BUG-003: Ошибки libsecret на Linux
**Описание:** `libsecret_error: Failed to unlock the keyring`  
**Влияние:** Не влияет на работу, но засоряет лог  
**Решение:** Проблема gnome-keyring, требует настройки системы пользователя

#### BUG-004: Flutter accessibility crash (Linux)
**Описание:** `assertion failed: (child != nullptr)` в `fl_view_accessible.cc`  
**Влияние:** Редкий краш на Linux  
**Статус:** Известный баг Flutter на Linux

---

## План дальнейшей разработки

### Фаза 1: Критические исправления
- [ ] **BUG-001:** Исправить фильтрацию активных задач по пользователю
- [ ] **BUG-002:** Реализовать или убрать заглушки кнопок

### Фаза 2: OCR интеграция
**Цель:** Распознавание текста условий задач с фотографий

**Задачи:**
- [ ] Выбрать OCR сервис (Google Vision API / Tesseract / собственный сервер)
- [ ] Создать `OcrService` в `data/services/`
- [ ] Добавить эндпоинт `/ocr/process` в API (если серверный OCR)
- [ ] Интегрировать в `ProblemDetailScreen`
- [ ] Добавить индикатор загрузки и обработку ошибок

**UI поток:**
```
Фото условия → [OCR кнопка] → Распознанный текст → [Редактировать] → Сохранить
```

### Фаза 3: Работа с камерой
**Цель:** Полноценная съёмка фото условий и решений

**Зависимости:**
- `camera: ^0.10.5+9` (уже добавлен)
- `image_picker: ^1.0.7` (уже добавлен)

**Задачи:**
- [ ] Доработать `CameraScreen` для Android/iOS
- [ ] Добавить галерею для выбора существующих фото
- [ ] Сжатие изображений перед загрузкой
- [ ] Загрузка фото на сервер (multipart/form-data)
- [ ] Отображение загруженных фото

**API endpoints (потребуются):**
```
POST /problems/{id}/condition-image
POST /solutions/{id}/solution-image
```

### Фаза 4: Markdown viewer
**Цель:** Красивое отображение форматированных условий и решений

**Зависимости:**
- `flutter_markdown: ^0.6.19` (уже добавлен)

**Задачи:**
- [ ] Создать `MarkdownCard` виджет
- [ ] Поддержка математических формул (KaTeX/MathJax)
- [ ] Поддержка изображений в markdown
- [ ] Кастомные стили для тёмной темы

### Фаза 5: Концепции и анализ знаний
**Цель:** Показ связанных концепций для задачи

**Задачи:**
- [ ] Экран списка концепций
- [ ] Экран детализации концепции
- [ ] Граф связей между концепциями
- [ ] Прогресс изучения концепций

**UI компоненты:**
- `ConceptCard` — карточка концепции
- `ConceptGraph` — интерактивный граф связей
- `ConceptProgressIndicator` — прогресс изучения

### Фаза 6: Уведомления
**Цель:** Push-уведомления для напоминаний и событий

**Задачи:**
- [ ] Интеграция Firebase Cloud Messaging
- [ ] Локальные уведомления (flutter_local_notifications)
- [ ] Настройки уведомлений в профиле
- [ ] Напоминания о стрике
- [ ] Уведомления о достижениях

### Фаза 7: Offline режим (Отложено)
**Причина:** Усложняет отладку на текущем этапе

**План на будущее:**
- [ ] SQLite/Drift для локального хранения
- [ ] Очередь синхронизации
- [ ] Conflict resolution
- [ ] Индикатор offline режима в UI

---

## Нереализованный функционал (TODO)

### Детальный список TODO в коде

| Файл | Строка | Описание | Приоритет |
|------|--------|----------|-----------|
| `home_screen.dart` | ~43 | Показ уведомлений | Средний |
| `home_screen.dart` | ~119 | Навигация к концепциям | Низкий |
| `library_screen.dart` | ~147 | Создание новой задачи | Высокий |
| `profile_screen.dart` | ~257 | Переключение темы | Средний |
| `profile_screen.dart` | ~265 | Настройка уведомлений | Низкий |
| `profile_screen.dart` | ~275 | Настройка вибрации | Низкий |
| `solution_session_screen.dart` | ~121 | Сохранение озарений | Средний |
| `solution_session_screen.dart` | ~162 | Сохранение вопросов | Средний |
| `solution_session_screen.dart` | ~207 | Запрос подсказки AI | Высокий |

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
- **Оригинальный CLI клиент:** Python MindVector
- **Flutter документация:** https://docs.flutter.dev
- **Riverpod документация:** https://riverpod.dev
- **GoRouter документация:** https://pub.dev/packages/go_router
- **Material 3:** https://m3.material.io

---

*Документация создана для проекта Лежандр — Flutter клиент MindVector*
