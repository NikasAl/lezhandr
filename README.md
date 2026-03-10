# Лежандр — MindVector Mobile Client

<div align="center">

**Кроссплатформенное мобильное приложение для отслеживания прогресса в решении математических задач с AI-ассистентом**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Linux-green)

</div>

---

## 🎯 О проекте

**Лежандр** — мобильный клиент системы MindVector, предназначенный для:
- Отслеживания прогресса решения задач
- Развития математических навыков
- Получения AI-помощи в процессе решения
- Анализа знаний и концептов

## ✨ Ключевые возможности

### 📚 Библиотека задач
- **Источники** — задачники и сборники с пагинацией
- **Поиск** — по тексту условия и номеру задачи
- **Теги** — классификация по темам и сложности
- **LaTeX** — полноценная поддержка математических формул
- **Zoom формул** — жесты масштабирования для длинных формул
- **Мои задачи** — фильтр по созданным задачам

### 🎯 Сессия решения
- **Таймер** — отслеживание времени решения
- **Озарения** — фиксация моментов инсайта с оценкой силы (⭐⭐⭐)
- **Вопросы** — запись вопросов с AI-ответами
- **Подсказки** — запрос подсказок от AI-персон
- **Фото** — съёмка условия и решения

### 📊 Мои решения
- **История** — все решения с группировкой по задачам
- **Статистика** — XP, время, количество решений
- **Фильтрация** — по статусу (в процессе, завершено, отложено)
- **Удаление** — долгое нажатие для удаления

### 🏆 Система XP (Experience Points)
- **Субъективная сложность** — привязана к решению, не к задаче
- **Время решения** — бонус за затраченное время
- **Озарения** — дополнительные очки за инсайты
- **Динамика XP** — одна задача может дать от 10 до 500+ XP

### 🤖 AI Персоны

| Персона | Модель | Цена | Особенности |
|---------|--------|------|-------------|
| 🐱 **Кот Базис** | basis | Бесплатно | 5 запросов/день, базовые подсказки |
| 🧹 **Петрович** | petrovich | 2 ₽ | Подробные объяснения |
| 🧐 **Лежандр** | legendre | 10 ₽ | Глубокий анализ, концепты |

### 📈 Статистика
- **XP прогресс** — общий и за период
- **Streak** — цепочка дней активности
- **Графики** — активность по дням
- **Время решения** — суммарное и среднее

### 🧠 Навыки и концепты
- **Карта навыков** — визуализация развитых навыков
- **Анализ концептов** — AI-выявление ключевых понятий
- **Трейс навыков** — какие навыки тренирует каждая задача

### 💰 Финансы
- **Баланс** — текущий баланс средств
- **Пополнение** — через ЮKassa
- **История** — транзакции и расходы

---

## 🏗️ Архитектура

```
lib/
├── main.dart                    # Точка входа
├── app.dart                     # MaterialApp конфигурация
├── core/
│   ├── config/                  # Конфигурация (API URL, env)
│   ├── theme/                   # Тёмная и светлая темы
│   ├── router/                  # GoRouter навигация
│   ├── services/                # Сервисы (image crop, OCR)
│   ├── motivation/              # Модуль мотивации
│   └── utils/                   # Утилиты (склонения, форматирование)
├── data/
│   ├── models/                  # DTO модели (Problem, Solution, User)
│   ├── repositories/            # Репозитории (API + локальное хранение)
│   ├── services/                # HTTP сервисы
│   └── storage/                 # SecureStorage, SharedPreferences
└── presentation/
    ├── providers/               # Riverpod providers
    ├── screens/                 # Экраны (17 модулей)
    └── widgets/                 # Переиспользуемые виджеты
```

---

## 📱 Экраны

| Экран | Маршрут | Описание |
|-------|---------|----------|
| **Splash** | `/` | Загрузка и проверка авторизации |
| **Home** | `/main/home` | Главная с быстрыми действиями |
| **Library** | `/main/library` | Библиотека задач |
| **My Solutions** | `/main/my-solutions` | История решений |
| **Statistics** | `/main/statistics` | Графики и статистика |
| **Skills** | `/main/skills` | Карта навыков |
| **Concepts** | `/main/concepts` | Анализ концептов |
| **Profile** | `/main/profile` | Профиль и настройки |
| **Problem Detail** | `/problems/:id` | Детали задачи |
| **Solution Session** | `/session/:id` | Интерактивная сессия |
| **Solution Detail** | `/solutions/:id` | Просмотр решения |
| **Camera** | `/camera` | Захват фото |
| **Billing** | `/billing` | Баланс и пополнение |
| **About** | `/about` | О приложении |

---

## 🛠️ Технологии

| Категория | Технология |
|-----------|------------|
| **UI Framework** | Flutter 3.x |
| **State Management** | Riverpod 2.x |
| **Navigation** | GoRouter 13.x |
| **HTTP Client** | Dio 5.x |
| **Secure Storage** | flutter_secure_storage |
| **LaTeX** | flutter_math_fork |
| **Charts** | fl_chart |
| **Animations** | flutter_animate, shimmer |
| **Camera** | camera, image_picker |

---

## 🚀 Запуск

### Требования
- Flutter SDK 3.x
- Dart 3.x
- Android SDK (для Android сборки)

### Разработка

```bash
# Клонировать репозиторий
git clone https://github.com/NikasAl/lezhandr.git
cd lezhandr

# Установить зависимости
flutter pub get

# Запустить в режиме разработки (локальный сервер)
flutter run -d linux --dart-define=env=dev

# Запустить в production режиме
flutter run -d linux
```

### Сборка release APK

```bash
# Создать android/key.properties (см. android/key.properties.example)
# Положить keystore в ../keystore/lezhandr.jks

# Сборка с разделением по архитектурам (рекомендуется)
flutter build apk --release --split-per-abi

# Результат:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  (~23 MB)
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (~22 MB)
```

### App Bundle для Google Play

```bash
flutter build appbundle --release
```

---

## 🎨 Адаптивный UI

Приложение поддерживает адаптивный интерфейс:
- **Телефоны** — полноэкранный режим
- **Планшеты/Desktop** — контент центрируется с max-width 900px
- **Wide screen** — в демо-видео показан переход от 9:16 к fullscreen

---

## 📦 Размер приложения

| Архитектура | Размер APK |
|-------------|------------|
| arm64-v8a | ~23.5 MB |
| armeabi-v7a | ~21.9 MB |
| x86_64 | ~25.1 MB |

---

## 🔐 Безопасность

- Токены хранятся в **SecureStorage** (Keychain/Keystore)
- Пароли в `.env` и `key.properties` исключены из git
- HTTPS для production API

---

## Обзоры / История

- [Лежандр: превращаем математику в RPG, а решение задач — в приключение и прокачку навыков](https://pikabu.ru/story/lezhandr_prevrashchaem_matematiku_v_rpg_a_reshenie_zadach__v_priklyuchenie_i_prokachku_navyikov_13764496)
- [OCR Тест Gemini, Claude и GPT 5.1 на рукописной математике](https://pikabu.ru/story/ocr_test_gemini_claude_i_gpt_51_na_rukopisnoy_matematike_13630534)
- [Прототип трекера времени для перерешивания задачников⁠](https://pikabu.ru/story/prototip_trekera_vremeni_dlya_perereshivaniya_zadachnikov_13607228)

---

## 📄 Лицензия

MIT

---

## 👨‍💻 Автор

**NikasAl** — [GitHub](https://github.com/NikasAl)

---

<div align="center">

*Математика — это не просто формулы, это способ мышления*

</div>
