import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/shared/adaptive_layout.dart';

/// Privacy Policy screen for RuStore compliance
class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Политика конфиденциальности'),
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: AdaptiveLayout(
              maxWidth: 800,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // 1. Общие положения
                  _buildSection(
                    context,
                    number: '1',
                    title: 'Общие положения',
                    content: 'Настоящая Политика конфиденциальности (далее — «Политика») определяет порядок обработки и защиты персональных данных пользователей мобильного приложения «Лежандр» (далее — «Приложение»). '
                        'Оператором персональных данных является Авдонин Никита. Использование Приложения означает безоговорочное согласие Пользователя с настоящей Политикой.',
                  ),

                  // 2. Информация о приложении
                  _buildSectionWithTable(
                    context,
                    number: '2',
                    title: 'Информация о приложении',
                    intro: 'Приложение «Лежандр» — это мобильный клиент системы MindVector, предназначенный для отслеживания прогресса решения математических и учебных задач с использованием искусственного интеллекта. Приложение предоставляет следующие функции:',
                    tableRows: [
                      ['Создание задач', 'Добавление условий задач в текстовом виде или путём фотографирования'],
                      ['Сессии решения', 'Отслеживание времени и прогресса решения задач'],
                      ['AI-ассистент', 'Получение подсказок и наводящих вопросов от искусственного интеллекта'],
                      ['Геймификация', 'Система XP, стриков, сердечек для мотивации обучения'],
                      ['Карта навыков', 'Отслеживание освоенных концепций и математических навыков'],
                    ],
                  ),

                  // 3. Собираемые данные
                  _buildSection(
                    context,
                    number: '3',
                    title: 'Собираемые и обрабатываемые данные',
                    content: '',
                  ),
                  _buildSubsection(
                    context,
                    title: '3.1. Данные, предоставляемые Пользователем',
                    content: 'При использовании Приложения Пользователь может предоставить следующие данные:',
                  ),
                  _buildDataTable(
                    context,
                    headers: ['Тип данных', 'Пример', 'Цель'],
                    rows: [
                      ['Текстовые условия задач', '«Решите уравнение...»', 'Хранение и анализ'],
                      ['Фотографии условий', 'Фото из учебника', 'Распознавание текста (OCR)'],
                      ['Записи озарений и вопросов', 'Текстовые заметки', 'История обучения'],
                      ['Время сессий решения', '15 минут, 1 час', 'Статистика и стрики'],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSubsection(
                    context,
                    title: '3.2. Данные, формируемые автоматически',
                    content: 'При работе Приложения автоматически формируются следующие данные:',
                  ),
                  _buildDataTable(
                    context,
                    headers: ['Тип данных', 'Цель обработки'],
                    rows: [
                      ['Уникальный идентификатор аккаунта', 'Аутентификация и привязка данных к пользователю'],
                      ['Токены авторизации', 'Поддержание сессии пользователя'],
                      ['Данные геймификации (XP, стрики)', 'Мотивация и отслеживание прогресса'],
                      ['Освоенные концепции и навыки', 'Персонализация обучения'],
                    ],
                    columnCount: 2,
                  ),

                  // 4. Разрешения
                  _buildSectionWithTable(
                    context,
                    number: '4',
                    title: 'Разрешения, запрашиваемые Приложением',
                    intro: 'Для полноценной работы Приложение запрашивает следующие разрешения:',
                    tableRows: [
                      ['Камера', 'Фотографирование условий задач из учебников и пособий', 'Фото не покидают устройство без согласия пользователя'],
                      ['Интернет', 'Синхронизация данных с сервером, получение AI-подсказок', 'Сервер расположен на территории РФ'],
                    ],
                    columnCount: 3,
                  ),

                  // 5. Хранение и защита
                  _buildSection(
                    context,
                    number: '5',
                    title: 'Хранение и защита данных',
                    content: '',
                  ),
                  _buildSubsection(
                    context,
                    title: '5.1. Локальное хранение',
                    content: 'Следующие данные хранятся локально на устройстве Пользователя с использованием шифрования (Android Keystore / iOS Keychain):',
                  ),
                  _buildBulletList([
                    'Токены авторизации (access token)',
                    'Уникальный ключ аккаунта',
                    'Временные фотографии до отправки на сервер',
                  ]),
                  _buildSubsection(
                    context,
                    title: '5.2. Серверное хранение',
                    content: 'Все данные, синхронизируемые с сервером, хранятся на серверах, расположенных на территории Российской Федерации (kreagenium.ru). Передача данных осуществляется по защищённому протоколу HTTPS.',
                  ),
                  _buildSubsection(
                    context,
                    title: '5.3. Меры защиты',
                    content: 'Оператор принимает следующие меры для защиты персональных данных:',
                  ),
                  _buildBulletList([
                    'Шифрование данных при передаче (TLS 1.2+)',
                    'Шифрование данных на устройстве (Android Keystore / iOS Keychain)',
                    'Аутентификация по токенам с ограниченным сроком действия',
                    'Регулярное обновление средств защиты',
                  ]),

                  // 6. Платные функции
                  _buildSection(
                    context,
                    number: '6',
                    title: 'Платные функции и платежи',
                    content: 'Приложение предоставляет платные функции через платёжную систему ЮKassa (ООО «ЮКасса»). При совершении платежей дополнительно обрабатываются следующие данные: сумма и дата платежа, статус транзакции. '
                        'Обработка платёжных данных осуществляется ЮKassa в соответствии с её политикой конфиденциальности. Оператор не хранит данные банковских карт.',
                  ),

                  // 7. Права пользователя
                  _buildSection(
                    context,
                    number: '7',
                    title: 'Права Пользователя',
                    content: 'Пользователь имеет право:',
                  ),
                  _buildBulletList([
                    'Получить информацию об обработке своих персональных данных',
                    'Требовать уточнения, блокирования или уничтожения персональных данных',
                    'Отозвать согласие на обработку персональных данных',
                    'Удалить свой аккаунт и все связанные данные',
                    'Обратиться в Роскомнадзор с жалобой',
                  ]),

                  // 8. Третьи лица
                  _buildSection(
                    context,
                    number: '8',
                    title: 'Передача данных третьим лицам',
                    content: 'Оператор не передаёт персональные данные третьим лицам, за исключением следующих случаев: '
                        'платёжная система ЮKassa — для обработки платежей; требования законодательства Российской Федерации. '
                        'Приложение не использует сторонние системы аналитики, краш-репортинга или рекламы.',
                  ),

                  // 9. Возрастные ограничения
                  _buildSection(
                    context,
                    number: '9',
                    title: 'Возрастные ограничения',
                    content: 'Возрастное ограничение Приложения: 6+. Приложение предназначено для использования детьми под контролем родителей (законных представителей). '
                        'При обработке персональных данных несовершеннолетних Оператор руководствуется статьёй 9 Федерального закона № 152-ФЗ.',
                  ),

                  // 10. Изменения
                  _buildSection(
                    context,
                    number: '10',
                    title: 'Изменение Политики',
                    content: 'Оператор вправе вносить изменения в настоящую Политику. Актуальная версия Политики доступна в Приложении. '
                        'Продолжение использования Приложения после внесения изменений означает согласие Пользователя с новой редакцией Политики.',
                  ),

                  // 11. Контакты
                  _buildSection(
                    context,
                    number: '11',
                    title: 'Контактная информация',
                    content: 'По всем вопросам, связанным с обработкой персональных данных, Пользователь может обратиться к Оператору:',
                  ),
                  _buildContactInfo(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.privacy_tip_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Политика конфиденциальности',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'мобильного приложения «Лежандр»',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'Дата последнего обновления: 05.03.2026',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                'Версия: 1.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '$number. $title',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubsection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithTable(
    BuildContext context, {
    required String number,
    required String title,
    required String intro,
    required List<List<String>> tableRows,
    int columnCount = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '$number. $title',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            intro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          _buildSimpleTable(context, tableRows, columnCount),
        ],
      ),
    );
  }

  Widget _buildSimpleTable(BuildContext context, List<List<String>> rows, int columnCount) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isEven = index % 2 == 0;

            return Container(
              color: isEven
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row.asMap().entries.map((cellEntry) {
                  final cellIndex = cellEntry.key;
                  final cellText = cellEntry.value;
                  final isHeader = index == 0;

                  return Expanded(
                    flex: columnCount == 3 && cellIndex == 0 ? 2 : 1,
                    child: Padding(
                      padding: EdgeInsets.only(right: cellIndex < row.length - 1 ? 8 : 0),
                      child: Text(
                        cellText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isHeader ? FontWeight.w600 : null,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataTable(
    BuildContext context, {
    required List<String> headers,
    required List<List<String>> rows,
    int? columnCount,
  }) {
    final allRows = [headers, ...rows];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: allRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isHeader = index == 0;
            final isEven = index % 2 == 0;

            return Container(
              color: isHeader
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : isEven
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row.asMap().entries.map((cellEntry) {
                  final cellIndex = cellEntry.key;
                  final cellText = cellEntry.value;
                  final colCount = columnCount ?? headers.length;

                  return Expanded(
                    flex: colCount == 3 && cellIndex == 0
                        ? 2
                        : colCount == 2 && cellIndex == 0
                            ? 2
                            : 1,
                    child: Padding(
                      padding: EdgeInsets.only(right: cellIndex < row.length - 1 ? 8 : 0),
                      child: Text(
                        cellText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: isHeader ? FontWeight.w600 : null,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactRow(context, 'Оператор:', 'Авдонин Никита'),
          const SizedBox(height: 8),
          _buildContactRow(context, 'Сайт:', 'kreagenium.ru'),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
