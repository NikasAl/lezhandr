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
| Markdown с LaTeX | MathJax рендеринг (инлайн + display) | `markdown_with_math.dart` |
| Детали задачи | Просмотр, OCR, решения | `problem_detail_screen.dart` |
| Детали решения | Просмотр, OCR, редактирование текста | `solution_detail_screen.dart` |
| Редактирование текста решения | update_solution_text | `solutions_repository.dart`, `solution_detail_screen.dart` |
| **Озарения (API)** | create, get, модели | `artifacts_repository.dart`, `artifacts.dart` |
| **Вопросы (API)** | create, get, update, generate AI answer | `artifacts_repository.dart`, `artifacts.dart` |
| **Подсказки (API)** | create draft, get, update, generate AI | `artifacts_repository.dart`, `artifacts.dart` |
| Просмотр озарений | Список, развертывание текста | `solution_detail_screen.dart` |
| Просмотр вопросов | Список, ответы, развертывание | `solution_detail_screen.dart` |
| Просмотр подсказок | Список, AI-текст, развертывание | `solution_detail_screen.dart` |

### ❌ Не реализовано (из CLI)

| Приоритет | Функция | API Endpoint | Описание | API готов | UI готов |
|-----------|---------|--------------|----------|-----------|----------|
| 🔴 P0 | update_problem_text | PATCH /problems/{id} | Редактирование условия | ⬜ | ⬜ |
| 🟡 P1 | **create_epiphany в сессии** | POST /epiphanies | Создание озарения во время решения | ✅ | ⬜ |
| 🟡 P1 | **create_question в сессии** | POST /questions | Создание вопроса во время решения | ✅ | ⬜ |
| 🟡 P1 | **answer_question в сессии** | PATCH /questions/{id} | Ответ на вопрос вручную | ✅ | ⬜ |
| 🟡 P1 | **generate_question_answer** | POST /questions/{id}/generate | AI ответ на вопрос | ✅ | ⬜ |
| 🟡 P1 | **create_hint_draft в сессии** | POST /hints/draft | Создание черновика подсказки | ✅ | ⬜ |
| 🟡 P1 | **generate_hint** | POST /hints/{id}/generate | AI генерация подсказки | ✅ | ⬜ |
| 🟢 P2 | analyze_problem | POST /concepts/analyze/problem/{id} | Анализ знаний в задаче | ⬜ | ⬜ |
| 🟢 P2 | analyze_solution | POST /concepts/analyze/solution/{id} | Трейс навыков решения | ⬜ | ⬜ |
| 🟢 P2 | get_concepts_by_solution | GET /concepts/by-solution/{id} | Связи решение-концепт | ⬜ | ⬜ |
| 🟢 P2 | create_topup | POST /billing/top-up | Пополнение баланса | ⬜ | ⬜ |
| 🟢 P2 | get_comments_by_* | GET /comments/by-* | Комментарии | ⬜ | ⬜ |
| 🟢 P2 | create_comment | POST /comments | Создание комментария | ⬜ | ⬜ |
| 🟢 P2 | get_vote_summary | GET /votes/summary | Лайки/дизлайки | ⬜ | ⬜ |
| 🟢 P2 | create_or_update_vote | POST /votes | Голосование | ⬜ | ⬜ |
| 🟢 P2 | get_articles | GET /articles | Статьи | ⬜ | ⬜ |
| 🟢 P2 | link_email | PATCH /users/me/convert | Привязка email к device-аккаунту | ⬜ | ⬜ |
| 🟢 P2 | merge_tags | POST /tags/merge | Объединение тегов (admin) | ⬜ | ⬜ |

---

## Приоритетные задачи

### 🔴 P0: Редактирование текста задачи
**API уже есть в problems_repository (updateProblemText не реализован)**

1. ⬜ Добавить `updateProblemText` в `ProblemsRepository`
2. ⬜ Добавить UI редактирования в `ProblemDetailScreen`

---

### 🟡 P1: Артефакты в сессии решения ⭐ ВЫСОКИЙ ПРИОРИТЕТ
**API уже полностью реализован! Нужно только UI в сессии.**

#### Озарения в сессии
- [x] API: `createEpiphany`, `getEpiphanies` в `ArtifactsRepository`
- [x] Модели: `EpiphanyModel`, `EpiphanyCreate`
- [ ] **UI: Диалог создания озарения в `SolutionSessionScreen`**
- [ ] **UI: Кнопка "Озарение" в панели действий сессии**

#### Вопросы в сессии
- [x] API: `createQuestion`, `getQuestions`, `updateQuestion`, `generateQuestionAnswer`
- [x] Модели: `QuestionModel`, `QuestionCreate`, `QuestionUpdate`
- [ ] **UI: Диалог создания вопроса в `SolutionSessionScreen`**
- [ ] **UI: Диалог ответа на вопрос**
- [ ] **UI: AI-ответ на вопрос (выбор персоны)**

#### Подсказки в сессии
- [x] API: `createHintDraft`, `getHints`, `updateHint`, `generateHint`
- [x] Модели: `HintModel`, `HintCreateDraft`, `HintUpdate`
- [ ] **UI: Диалог запроса подсказки в `SolutionSessionScreen`**
- [ ] **UI: AI-генерация подсказки (выбор персоны)**

**Файлы для UI:**
- `lib/presentation/screens/solutions/solution_session_screen.dart` - добавить кнопки
- `lib/presentation/widgets/session/epiphany_dialog.dart` - новый
- `lib/presentation/widgets/session/question_dialog.dart` - новый
- `lib/presentation/widgets/session/hint_dialog.dart` - новый

---

### 🟢 P2: Концепции и анализ
**Цель:** Анализ знаний и навыков

1. ⬜ Расширить `ConceptsRepository` для анализа
2. ⬜ UI запуска анализа задачи/решения
3. ⬜ Отображение связанных концепций

---

### 🟢 P2: Комьюнити
**Цель:** Комментарии, лайки, статьи

1. ⬜ Модели `CommentModel`, `VoteModel`, `ArticleModel`
2. ⬜ Репозитории и провайдеры
3. ⬜ UI комментариев
4. ⬜ UI лайков/дизлайков

---

### 🟢 P2: Финансы и профиль
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
├── artifacts_provider.dart   # ✅ Озарения/Вопросы/Подсказки (API готов)
├── questions_provider.dart   # ⬜ Не нужен - в artifacts
├── hints_provider.dart       # ⬜ Не нужен - в artifacts
├── comments_provider.dart    # ❌ Комментарии
└── concepts_provider.dart    # ❌ Концепции (только чтение)
```

### Виджеты сессии решения
```
lib/presentation/widgets/session/
├── session_timer.dart        # ❓ Таймер (если есть)
├── epiphany_dialog.dart      # ❌ Диалог озарения
├── question_dialog.dart      # ❌ Диалог вопроса
├── hint_dialog.dart          # ❌ Диалог подсказки
└── session_actions.dart      # ❌ Панель действий (кнопки h/e/q)
```

---

## Ссылки

- CLI клиент: `mv_run_client.py`, `mv_screens.py`, `mv_api.py`
- API документация: `KODA.md`
- Flutter проект: `/lib`
