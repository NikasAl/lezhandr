# План реализации Flutter клиента (на основе CLI)

## Статус функционала

### ✅ Реализовано
- Авторизация (device_login, get_me)
- Просмотр источников/задач/тегов
- Создание решения, сессия
- Завершение решения (finish_solution)
- Геймификация (XP, hearts, streak, activity)
- Просмотр профиля

### ❌ Не реализовано (из CLI)

| Приоритет | Функция | API Endpoint | Описание |
|-----------|---------|--------------|----------|
| 🔴 P0 | upload_image | POST /uploads/{category}/{entity_id} | Загрузка фото |
| 🔴 P0 | trigger_problem_ocr | POST /content/process-image/problem/{id} | OCR условия |
| 🔴 P0 | trigger_solution_ocr | POST /content/process-image/solution/{id} | OCR решения |
| 🟡 P1 | create_problem | POST /problems | Создание задачи |
| 🟡 P1 | create_epiphany | POST /epiphanies | Озарения |
| 🟡 P1 | create_question | POST /questions | Вопросы |
| 🟡 P1 | get_questions | GET /questions/by-solution/{id} | Список вопросов |
| 🟡 P1 | generate_question_answer | POST /questions/{id}/generate | AI ответ на вопрос |
| 🟡 P1 | create_hint_draft | POST /hints/draft | Создание подсказки |
| 🟡 P1 | generate_hint | POST /hints/{id}/generate | AI подсказка |
| 🟡 P1 | get_hints | GET /hints/by-solution/{id} | Список подсказок |
| 🟢 P2 | analyze_problem | POST /concepts/analyze/problem/{id} | Анализ знаний |
| 🟢 P2 | analyze_solution | POST /concepts/analyze/solution/{id} | Трейс навыков |
| 🟢 P2 | create_topup | POST /billing/top-up | Пополнение баланса |

## Порядок реализации

### Фаза 1: Загрузка изображений (P0)
1. Создать `UploadsRepository` и `UploadsProvider`
2. Реализовать multipart/form-data загрузку
3. Интегрировать в CameraScreen

### Фаза 2: OCR (P0)
1. Создать `OcrRepository` и `OcrProvider`
2. Добавить UI для запуска OCR
3. Показывать результат и давать редактировать

### Фаза 3: Артефакты сессии (P1)
1. EpiphanyModel + Repository + Provider
2. QuestionModel + Repository + Provider  
3. HintModel + Repository + Provider
4. UI диалоги в SolutionSessionScreen

### Фаза 4: AI интеграция (P1)
1. Выбор персоны (Basis/Petrovich/Legendre)
2. Генерация ответов на вопросы
3. Генерация подсказок

### Фаза 5: Концепции (P2)
1. ConceptModel + Repository
2. Экран анализа знаний
3. Граф концепций
