# План реализации Flutter клиента (на основе CLI)

_Последнее обновление: 2025-01-16_

## Статус функционала

### ✅ Реализовано

| Функция | Описание | Файлы |
|---------|----------|-------|
| Авторизация | device_login, get_me | `auth_repository.dart`, `auth_provider.dart` |
| Просмотр источников/задач/тегов | Sources, Problems, Tags | `problems_repository.dart`, `library_screen.dart` |
| Создание задачи | create_problem | `problems_repository.dart`, `library_screen.dart` |
| Создание решения | create_solution | `solutions_repository.dart` |
| Сессия решения | Timer, status tracking | `solution_session_screen.dart` |
| Завершение решения | finish_solution | `solutions_repository.dart` |
| Геймификация | XP, hearts, streak, activity | `gamification_repository.dart`, `statistics_screen.dart` |
| Просмотр профиля | Profile screen | `profile_screen.dart` |
| Загрузка изображений | upload_image (multipart) | `uploads_repository.dart`, `camera_screen.dart` |
| OCR условий и решений | trigger_problem_ocr, trigger_solution_ocr | `ocr_provider.dart`, `problem_detail_screen.dart` |
| Выбор AI-персоны | Basis/Petrovich/Legendre | `persona_selector.dart` |
| Просмотр изображений | Image viewer с zoom | `image_viewer.dart` |
| Markdown с LaTeX | MathJax рендеринг | `markdown_with_math.dart` |
| Детали задачи | Просмотр, OCR, решения | `problem_detail_screen.dart` |
| Детали решения | Просмотр, OCR | `solution_detail_screen.dart` |
| Просмотр озарений | Список, фото | `artifacts_repository.dart`, `solution_detail_screen.dart` |

### ❌ Не реализовано (из CLI)

| Приоритет | Функция | API Endpoint | Описание | Сложность |
|-----------|---------|--------------|----------|-----------|
| 🔴 P0 | update_problem_text | PATCH /problems/{id} | Редактирование условия | низкая |
| 🔴 P0 | update_solution_text | PATCH /solutions/{id} | Редактирование решения | низкая |
| 🔴 P0 | create_epiphany | POST /epiphanies | Создание озарения в сессии | средняя |
| 🔴 P0 | get_epiphanies | GET /epiphanies/by-solution/{id} | Список озарений решения | низкая |
| 🟡 P1 | create_question | POST /questions | Создание вопроса в сессии | средняя |
| 🟡 P1 | get_questions | GET /questions/by-solution/{id} | Список вопросов | низкая |
| 🟡 P1 | answer_question | PATCH /questions/{id} | Ответ на вопрос вручную | низкая |
| 🟡 P1 | generate_question_answer | POST /questions/{id}/generate | AI ответ на вопрос | средняя |
| 🟡 P1 | create_hint_draft | POST /hints/draft | Создание черновика подсказки | средняя |
| 🟡 P1 | generate_hint | POST /hints/{id}/generate | AI генерация подсказки | средняя |
| 🟡 P1 | get_hints | GET /hints/by-solution/{id} | Список подсказок | низкая |
| 🟡 P1 | update_hint | PATCH /hints/{id} | Редактирование подсказки | низкая |
| 🟢 P2 | analyze_problem | POST /concepts/analyze/problem/{id} | Анализ знаний в задаче | высокая |
| 🟢 P2 | analyze_solution | POST /concepts/analyze/solution/{id} | Трейс навыков решения | высокая |
| 🟢 P2 | get_concepts_by_solution | GET /concepts/by-solution/{id} | Связи решение-концепт | низкая |
| 🟢 P2 | deduplicate_concepts | POST /concepts/deduplicate | Дедупликация концептов | высокая |
| 🟢 P2 | create_topup | POST /billing/top-up | Пополнение баланса | высокая |
| 🟢 P2 | get_comments_by_* | GET /comments/by-* | Комментарии | средняя |
| 🟢 P2 | create_comment | POST /comments | Создание комментария | средняя |
| 🟢 P2 | get_vote_summary | GET /votes/summary | Лайки/дизлайки | низкая |
| 🟢 P2 | create_or_update_vote | POST /votes | Голосование | низкая |
| 🟢 P2 | get_articles | GET /articles | Статьи | низкая |
| 🟢 P2 | link_email | PATCH /users/me/convert | Привязка email к device-аккаунту | средняя |
| 🟢 P2 | merge_tags | POST /tags/merge | Объединение тегов (admin) | средняя |
| 🟢 P2 | flow_admin | Admin endpoints | Админка | высокая |

---

## Порядок реализации

### Фаза 1: Редактирование текста (P0) ✅ В ПРОЦЕССЕ
**Цель:** Возможность редактировать распознанный/введённый текст

1. ✅ Создать методы `updateProblemText` и `updateSolutionText` в репозиториях
2. ⬜ Добавить UI редактирования в `ProblemDetailScreen`
3. ⬜ Добавить UI редактирования в `SolutionDetailScreen`
4. ⬜ Добавить кнопку "Редактировать" после OCR

**Файлы:**
- `lib/data/repositories/problems_repository.dart`
- `lib/data/repositories/solutions_repository.dart`
- `lib/presentation/screens/problems/problem_detail_screen.dart`
- `lib/presentation/screens/solutions/solution_detail_screen.dart`

---

### Фаза 2: Озарения в сессии (P0)
**Цель:** Создание озарений прямо во время сессии решения

1. ⬜ Добавить метод `createEpiphany` в `ArtifactsRepository`
2. ⬜ Создать диалог создания озарения
3. ⬜ Добавить кнопку в `SolutionSessionScreen`
4. ⬜ Прикрепление фото к озарению

**Файлы:**
- `lib/data/repositories/artifacts_repository.dart`
- `lib/presentation/screens/solutions/solution_session_screen.dart`
- `lib/presentation/widgets/session/epiphany_dialog.dart` (новый)

---

### Фаза 3: Вопросы (P1)
**Цель:** Система вопросов в сессии с AI-ответами

1. ⬜ Добавить модели `QuestionModel`, `QuestionCreate`
2. ⬜ Создать `QuestionsRepository` и `QuestionsProvider`
3. ⬜ Диалог создания вопроса
4. ⬜ Список вопросов в сессии
5. ⬜ AI-ответы на вопросы (выбор персоны)

**Файлы:**
- `lib/data/models/question.dart` (новый)
- `lib/data/repositories/questions_repository.dart` (новый)
- `lib/presentation/providers/questions_provider.dart` (новый)
- `lib/presentation/screens/solutions/solution_session_screen.dart`
- `lib/presentation/widgets/session/question_dialog.dart` (новый)

---

### Фаза 4: Подсказки (P1)
**Цель:** Система подсказок с AI-генерацией

1. ⬜ Добавить модели `HintModel`, `HintCreate`
2. ⬜ Создать `HintsRepository` и `HintsProvider`
3. ⬜ Диалог запроса подсказки
4. ⬜ AI-генерация подсказки (выбор персоны)
5. ⬜ Просмотр списка подсказок

**Файлы:**
- `lib/data/models/hint.dart` (новый)
- `lib/data/repositories/hints_repository.dart` (новый)
- `lib/presentation/providers/hints_provider.dart` (новый)
- `lib/presentation/screens/solutions/solution_session_screen.dart`
- `lib/presentation/widgets/session/hint_dialog.dart` (новый)

---

### Фаза 5: Концепции и анализ (P2)
**Цель:** Анализ знаний и навыков

1. ⬜ Расширить `ConceptsRepository` для анализа
2. ⬜ UI запуска анализа задачи/решения
3. ⬜ Отображение связанных концепций
4. ⬜ Граф зависимостей (визуализация)

**Файлы:**
- `lib/data/repositories/concepts_repository.dart`
- `lib/presentation/screens/concepts/` (новая папка)

---

### Фаза 6: Комьюнити (P2)
**Цель:** Комментарии, лайки, статьи

1. ⬜ Модели `CommentModel`, `VoteModel`, `ArticleModel`
2. ⬜ Репозитории и провайдеры
3. ⬜ UI комментариев
4. ⬜ UI лайков/дизлайков
5. ⬜ Просмотр статей

---

### Фаза 7: Финансы и профиль (P2)
**Цель:** Пополнение баланса, привязка email

1. ⬜ UI пополнения баланса
2. ⬜ Диалог привязки email
3. ⬜ Отображение транзакций

---

## Архитектурные заметки

### Структура провайдеров
```
lib/presentation/providers/
├── auth_provider.dart        # ✅ Авторизация
├── problems_provider.dart    # ✅ Задачи
├── solutions_provider.dart   # ✅ Решения
├── gamification_provider.dart # ✅ Геймификация
├── billing_provider.dart     # ✅ Финансы
├── ocr_provider.dart         # ✅ OCR
├── artifacts_provider.dart   # ✅ Озарения (частично)
├── questions_provider.dart   # ❌ Вопросы
├── hints_provider.dart       # ❌ Подсказки
├── comments_provider.dart    # ❌ Комментарии
└── concepts_provider.dart    # ❌ Концепции (только чтение)
```

### Виджеты сессии решения
```
lib/presentation/widgets/session/
├── session_timer.dart        # Таймер
├── epiphany_dialog.dart      # ❌ Диалог озарения
├── question_dialog.dart      # ❌ Диалог вопроса
├── hint_dialog.dart          # ❌ Диалог подсказки
└── session_actions.dart      # Панель действий
```

---

## Замеченные недостатки

### 1. Карточка задачи в Библиотеке ⚠️ ИСПРАВЛЯЕТСЯ
**Проблема:** Карточка показывает только источник, номер и теги. Нет превью текста/изображения.

**Решение:**
- Добавить 2-3 строки превью текста условия (если есть)
- Или показать миниатюру изображения (если есть только изображение)

---

## Ссылки

- CLI клиент: `mv_run_client.py`, `mv_screens.py`, `mv_api.py`
- API документация: `KODA.md`
- Flutter проект: `/lib`
