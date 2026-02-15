# Краткий справочник разработчика

## Быстрые исправления ошибок

### Ошибка: `Bad state: No ProviderScope found`
**Файл:** `lib/main.dart`
```dart
runApp(const ProviderScope(child: LezhandrApp()));
```

### Ошибка: `locale ru_RU is not supported`
**Файл:** `pubspec.yaml` — добавить:
```yaml
flutter_localizations:
  sdk: flutter
```
**Файл:** `lib/app.dart` — добавить:
```dart
localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```

### Ошибка: `type 'Null' is not a subtype of type 'int'`
**Решение:** Все модели данных должны использовать nullable типы и default значения:
```dart
factory MyModel.fromJson(Map<String, dynamic> json) {
  return MyModel(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
  );
}
```

### Ошибка: `Cannot access property on potentially null`
**Решение:** Добавить safe getter или использовать `?.`:
```dart
String get sourceName => source?.name ?? 'Unknown';
```

---

## Архитектура проекта

```
lib/
├── main.dart              # ProviderScope обёртка
├── app.dart               # MaterialApp.router + локализация
├── core/                  # Общие компоненты
│   ├── config/            # AppConfig (API URL)
│   ├── theme/             # Material 3 тема
│   ├── router/            # GoRouter маршруты
│   └── motivation/        # Движок мотивации
├── data/                  # Слой данных
│   ├── models/            # DTO (без json_serializable!)
│   ├── repositories/      # API вызовы
│   ├── services/          # ApiClient (Dio)
│   └── storage/           # TokenStorage
└── presentation/          # UI слой
    ├── providers/         # Riverpod StateNotifier
    ├── screens/           # Виджеты экранов
    └── widgets/           # Переиспользуемые компоненты
```

---

## Текущие TODO

| Приоритет | Задача |
|-----------|--------|
| 🔴 Высокий | BUG-001: Фильтрация задач по user_id |
| 🔴 Высокий | Реализовать создание задачи (FAB) |
| 🟡 Средний | OCR интеграция |
| 🟡 Средний | AI подсказки в сессии |
| 🟢 Низкий | Переключение темы |
| 🟢 Низкий | Offline режим |

---

## Запуск

```bash
flutter pub get
flutter run -d linux
```

---

## Важно помнить

1. **Не использовать json_serializable** — только ручной fromJson/toJson
2. **Все поля из API — nullable** — API может вернуть null
3. **ProviderScope обязателен** — Riverpod не работает без него
4. **Локализация требует delegates** — иначе краш на ru_RU
