# Лежандр — Flutter клиент MindVector

## История изменений (Changelog)

### Версия 0.5.1 (Текущая)

#### Рефакторинг

##### 🔧 Разбивка library_screen.dart на модульные виджеты
**Проблема:** Файл `library_screen.dart` вырос до 1781 строки, что затрудняло поддержку и расширение.

**Решение:** Экран разделён на независимые виджеты:
```
library_screen.dart           → 723 строки (основной экран)
widgets/
├── load_more_card.dart       → 46 строк (карточка "Загрузить ещё")
├── filter_chip.dart          → 58 строк (чип фильтра "Мои")
├── safe_math_preview.dart    → 33 строки (предпросмотр с LaTeX)
├── problem_card.dart         → 281 строка (карточка задачи)
├── tags_selector.dart        → 151 строка (селектор тегов)
├── create_problem_sheet.dart → 512 строк (диалоги создания)
└── widgets.dart              → barrel export
```

**Изменённые файлы:**
- `lib/presentation/screens/library/library_screen.dart`
- `lib/presentation/screens/library/widgets/` (новые файлы)

---

#### Новые функции

##### ✨ Модерация источников и тегов
**Функция:** Пользователи могут создавать собственные источники и теги с модерацией.

**Реализовано:**
1. Поля `added_by` и `moderation_status` в моделях Source и Tag
2. Статусы: `pending` (на модерации), `approved` (одобрено), `rejected` (отклонено)
3. Отображение статуса модерации в селекторах источников и тегов
4. API методы `updateSource` и `updateTag` для редактирования владельцем
5. Pending-элементы видны только их автору

**Изменённые файлы:**
- `lib/data/models/problem.dart` — SourceModel, TagModel с новыми полями
- `lib/data/repositories/problems_repository.dart` — updateSource, updateTag
- `lib/presentation/providers/problems_provider.dart` — notifier methods
- `lib/presentation/screens/library/library_screen.dart` — UI статусов

---

#### Исправления ошибок

##### 1. Диалог добавления фото не открывался после создания задачи
**Проблема:** После создания задачи диалог предложения добавить фото закрывался, но камера не открывалась.

**Причина:** `Navigator.of(context).pop()` делал контекст недействительным, и последующий `showModalBottomSheet` не мог быть показан.

**Решение:**
1. `_CreateProblemSheet` теперь возвращает созданную задачу через `Navigator.pop(problem)`
2. Родительский виджет обрабатывает результат и показывает диалог фото
3. Контекст остаётся валидным на протяжении всего процесса

**Изменённые файлы:**
- `lib/presentation/screens/library/library_screen.dart`

---

##### 2. TextEditingController использовался после dispose
**Проблема:** `A TextEditingController was used after being disposed` при создании нового источника.

**Причина:** Контроллер создавался снаружи виджета, передавался в него, а затем уничтожался `dispose()` до завершения анимации закрытия bottom sheet.

**Решение:**
1. Контроллер создаётся внутри `_NewSourceSheetState`
2. `dispose()` вызывается автоматически при уничтожении виджета
3. Убран внешний параметр `controller`

**Изменённые файлы:**
- `lib/presentation/screens/library/library_screen.dart`

---

### Версия 0.5.0

#### Новые функции

##### ✨ Диалоги помощи для всех экранов
**Функция:** Добавлены информационные диалоги с описанием возможностей каждого экрана.

**Реализовано:**
1. Кнопка `?` в AppBar экранов: Библиотека, Задача, Решение, Сессия
2. Bottom sheet с описанием функций и советами
3. Закрытие свайпом вниз
4. Единый стиль оформления с иконками

**Изменённые файлы:**
- `lib/presentation/screens/library/library_screen.dart`
- `lib/presentation/screens/problems/problem_detail_screen.dart`
- `lib/presentation/screens/solutions/solution_detail_screen.dart`
- `lib/presentation/screens/solutions/solution_session_screen.dart`

---

##### ✨ Редактирование и удаление озарений
**Функция:** Пользователь может редактировать и удалять озарения после создания.

**Реализовано:**
1. Меню опций при нажатии на озарение (просмотр, редактирование, удаление)
2. Диалог редактирования текста и силы озарения (1-3 звезды)
3. Подтверждение удаления
4. API методы `updateEpiphany` и `deleteEpiphany`

**Изменённые файлы:**
- `lib/data/models/artifacts.dart` — добавлен `EpiphanyUpdate`
- `lib/data/repositories/artifacts_repository.dart`
- `lib/presentation/providers/artifacts_provider.dart`
- `lib/presentation/screens/solutions/solution_session_screen.dart`
- `lib/presentation/screens/solutions/dialogs/epiphany_edit_dialog.dart` (новый)

---

##### ✨ Адаптивный layout для широких экранов
**Функция:** Интерфейс адаптируется для планшетов, десктопов и веба.

**Реализовано:**
1. Ограничение максимальной ширины контента (900px)
2. Центрирование контента на широких экранах
3. Адаптация bottom navigation bar
4. Адаптивные диалоги и bottom sheets

**Изменённые файлы:**
- `lib/presentation/widgets/shared/adaptive_layout.dart` (новый)
- `lib/presentation/screens/library/library_screen.dart`
- `lib/presentation/screens/problems/problem_detail_screen.dart`
- `lib/presentation/screens/solutions/solution_detail_screen.dart`
- `lib/presentation/screens/solutions/solution_session_screen.dart`

---

#### Улучшения UI

##### ✨ Конвертация диалогов в bottom sheets
**Изменено:** Все основные диалоги переписаны с `AlertDialog` на `showModalBottomSheet`.

**Преимущества:**
1. Закрытие свайпом вниз (`enableDrag: true`)
2. Больше места для контента
3. Единообразный UI с drag handle
4. Лучшая адаптация под клавиатуру

**Затронутые диалоги:**
- Создание задачи (Библиотека)
- Редактирование тегов
- Ввод озарения, вопроса, подсказки (Сессия)
- Детали вопроса и подсказки
- Редактирование озарения

---

##### ✨ Улучшения карточек на экране Сессия
**Изменено:**

1. **Карточка Озарения:**
   - До 4 строк текста (было 2)
   - Убрана иконка меню — открывается по нажатию на текст
   - Уменьшены отступы слева/справа
   - Markdown с формулами в деталях

2. **Карточка Вопроса:**
   - Убрана иконка `>` для большей ширины текста
   - Текст вопроса обёрнут в `MarkdownWithMath`
   - Кнопки редактирования в заголовках секций
   - Закрытие свайпом вниз

3. **Все карточки:**
   - Уменьшен `contentPadding` для лучшего использования ширины

**Изменённые файлы:**
- `lib/presentation/screens/solutions/solution_session_screen.dart`
- `lib/presentation/screens/solutions/dialogs/question_detail_dialog.dart`
- `lib/presentation/screens/solutions/dialogs/epiphany_edit_dialog.dart`

---

##### ✨ Улучшения заголовка задачи
**Изменено:** Реструктурирован layout заголовка для лучшего использования пространства.

**Новая структура:**
```
[Источник] [Номер задачи]
[👤 Пользователь]
```

**Особенности:**
- Источник может занимать несколько строк
- Номер задачи справа в той же строке (если вмещается)
- Пользователь отдельной строкой ниже

**Изменённые файлы:**
- `lib/presentation/screens/problems/widgets/problem_header.dart`

---

#### Исправления ошибок

##### 1. Ошибка закрытия bottom sheet на Android
**Проблема:** `_dependents.isEmpty` assertion error при закрытии диалогов на Android.

**Причина:** `TextEditingController` создавался вне виджета и уничтожался до завершения анимации закрытия.

**Решение:**
1. Контроллеры создаются в `initState()` и уничтожаются в `dispose()`
2. Диалоги вынесены в отдельные `StatefulWidget` классы
3. Данные возвращаются через result-объекты

**Изменённые файлы:**
- `lib/presentation/screens/solutions/dialogs/epiphany_dialog.dart`
- `lib/presentation/screens/solutions/dialogs/question_dialog.dart`
- `lib/presentation/screens/solutions/dialogs/hint_dialog.dart`

---

##### 2. SnackBar всплывал над кнопками на широких экранах
**Проблема:** `SnackBar` отображался над bottom bar вместо того чтобы быть внутри него.

**Решение:** Заменён `Center` на `margin` для позиционирования `bottomNavigationBar`.

**Изменённые файлы:**
- `lib/presentation/screens/solutions/solution_session_screen.dart`

---

### Версия 0.4.1

#### Рефакторинг

##### 🔧 Экран решения разбит на модульные виджеты
**Проблема:** Файл `solution_detail_screen.dart` вырос до 1327 строк, что затрудняло поддержку и расширение.

**Решение:** Экран разделён на независимые виджеты:
```
solution_detail_screen.dart  → 199 строк (основной экран)
widgets/
├── status_card.dart            → 152 строки (статус и статистика)
├── solution_text_section.dart  → 168 строк (текст с OCR и редактированием)
├── problem_condition_card.dart → 125 строк (условие задачи)
├── concepts_section.dart       → 244 строки (навыки с анализом)
├── epiphanies_section.dart     → 110 строк (озарения)
├── questions_section.dart      → 152 строки (вопросы)
├── hints_section.dart          → 155 строк (подсказки)
├── solution_photo_card.dart    → 110 строк (фото решения)
└── widgets.dart                → barrel export
```

**Изменённые файлы:**
- `lib/presentation/screens/solutions/solution_detail_screen.dart`
- `lib/presentation/screens/solutions/widgets/` (новые файлы)

---

#### Улучшения UI

##### ✨ OCR и редактирование в карточке текста решения
**Функция:** Кнопки OCR и редактирования перенесены из AppBar в заголовок карточки "Текст решения".

**Реализовано:**
1. Кнопка OCR с индикатором загрузки
2. Кнопка переключения режим просмотр/редактирование
3. Кнопка очистить (значок ✕) при редактировании
4. Анимация ThinkingIndicator во время OCR

**Изменённые файлы:**
- `lib/presentation/screens/solutions/widgets/solution_text_section.dart`

---

##### ✨ Исправление переполнения кнопок при редактировании
**Проблема:** Кнопки "Очистить", "Сбросить", "Сохранить" не помещались в строку на узких экранах.

**Решение:** `Row` заменён на `Wrap` с автоматическим переносом на следующую строку.

**Изменённые файлы:**
- `lib/presentation/screens/solutions/widgets/solution_text_section.dart`

---

#### Исправления ошибок

##### 1. Поддержка `\(...\)` для inline LaTeX
**Проблема:** LLM иногда выдают формулы в формате `\(formula\)` вместо `$formula$`, которые не распознавались.

**Решение:** Расширен regex парсер для поддержки обоих форматов:
- `$formula$` — классический markdown
- `\(formula\)` — LaTeX формат от LLM

**Изменённые файлы:**
- `lib/presentation/widgets/shared/markdown_with_math.dart`

---

##### 2. Нумерация списков с формулами между элементами
**Проблема:** Списки с display math между элементами отображались как `1. ... 1. ...` вместо `1. ... 2. ...`.

**Решение:** 
1. Улучшен парсинг списков — пустые строки между элементами пропускаются
2. Исправлена индексация — `asMap().entries` вместо `indexOf`

**Пример:**
```
1. **Если** $X \in (-\infty; -1)$...
   $$ \frac{X + 1}{X} $$
2. **Если** $X \in (-1; 0)$...
```

**Изменённые файлы:**
- `lib/presentation/widgets/shared/markdown_with_math.dart`

---

##### 3. Жирный текст с inline формулами
**Проблема:** `**text $formula$**` отображался с звёздочками: `**text** $formula$`.

**Решение:** Объединённый парсер `_parseMarkdownInline` теперь обрабатывает markdown и формулы вместе, с рекурсивным парсингом содержимого bold/italic.

**Изменённые файлы:**
- `lib/presentation/widgets/shared/markdown_with_math.dart`

---

### Версия 0.4.0

#### Новые функции

##### ✨ Поддержка полной Markdown разметки
**Функция:** Виджет `MarkdownWithMath` теперь поддерживает базовую markdown разметку.

**Реализовано:**
1. Заголовки: `# H1`, `## H2`, `### H3` (до 6 уровней)
2. **Жирный текст**: `**text**` или `__text__`
3. *Курсив*: `*text*` или `_text_`
4. ***Жирный курсив***: `***text***`
5. `Инлайн код`: `` `code` ``
6. Блоки кода с серым фоном: ` ```code``` `
7. Маркированные списки: `- item` или `* item`
8. Нумерованные списки: `1. item`
9. Сохранена поддержка LaTeX формул: `$formula$` и `$$formula$$`

**Изменённые файлы:**
- `lib/presentation/widgets/shared/markdown_with_math.dart`

---

##### ✨ Права доступа на основе владельца
**Функция:** Ограничение редактирования задач и решений только для их авторов.

**Реализовано:**
1. Отображение имени автора в карточке задачи/решения
2. Кнопки редактирования текста, OCR и загрузки фото видны только владельцу
3. Анализ концептов доступен всем пользователям
4. Просмотр фото доступен всем, загрузка — только владельцу

**Изменённые файлы:**
- `lib/presentation/screens/problems/problem_detail_screen.dart`
- `lib/presentation/screens/solutions/solution_detail_screen.dart`

---

##### ✨ Правильные русские склонения числительных
**Функция:** Корректное склонение слов после чисел (день/дня/дней).

**Реализовано:**
1. Создан утилитарный класс `RussianPlural` с методом `format()`
2. Обновлён движок мотивации: "1 день", "2 дня", "5 дней"
3. Обновлён экран статистики
4. Обновлён домашний экран

**Изменённые файлы:**
- `lib/core/utils/russian_plural.dart` (новый)
- `lib/core/motivation/motivation_engine.dart`
- `lib/presentation/screens/statistics/statistics_screen.dart`
- `lib/presentation/screens/main_menu/home_screen.dart`

---

#### Исправления ошибок

##### 1. Редирект на home при обновлении профиля
**Проблема:** Pull-to-refresh на странице профиля перенаправлял на домашнюю страницу.
**Причина:** Router следил за всем `authStateProvider`, который обновлялся при refresh.
**Решение:** Использован `select()` для отслеживания только routing-критичных полей (`isAuthenticated`, `showLoginScreen`, `isLoading`).

**Изменённые файлы:**
- `lib/core/router/app_router.dart`
- `lib/presentation/screens/profile/profile_screen.dart`

##### 2. Синтаксические ошибки в экранах задачи и решения
**Проблема:** Неправильное использование `whenData()` в `actions` AppBar.
**Решение:** Переписан метод `actions` с использованием правильного паттерна `.when()`.

---

### Версия 0.3.0

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


*Документация создана для проекта Лежандр — Flutter клиент MindVector*
