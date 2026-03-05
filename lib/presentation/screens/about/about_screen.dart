import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/shared/adaptive_layout.dart';

/// About screen - app description and welcome page
/// Shows on first launch or when user taps app icon/version info
class AboutScreen extends ConsumerStatefulWidget {
  final bool isFirstLaunch;

  const AboutScreen({
    super.key,
    this.isFirstLaunch = false,
  });

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar - only show if not first launch
            if (!widget.isFirstLaunch)
              AppBar(
                title: const Text('О приложении'),
              )
            else
              // Close button for first launch
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _closeScreen(),
                  ),
                ),
              ),

            // Scrollable content
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: AdaptiveLayout(
                    maxWidth: 800,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      // Hero image
                      _buildHeroImage(),
                      const SizedBox(height: 32),

                      // Title
                      _buildTitle(context),
                      const SizedBox(height: 24),

                      // Introduction
                      _buildSection(
                        context,
                        title: 'Добро пожаловать!',
                        content: 'Лежандр — это ваш персональный спутник в мире интеллектуальных задач. '
                            'Приложение создано для тех, кто видит ценность в развитии своего ума через решение '
                            'задач по математике, физике, химии и другим областям знаний. Каждая решённая задача — '
                            'это шаг вперёд, маленькая победа над собой и расширение границ ваших возможностей.',
                      ),
                      const SizedBox(height: 24),

                      // Illustration placeholder
                      _buildIllustrationPlaceholder(context, 1),
                      const SizedBox(height: 24),

                      // Philosophy
                      _buildSection(
                        context,
                        title: 'Философия развития',
                        content: 'Мы верим, что способность преодолевать трудности — развивается путем решения сложных задач. '
                            'Её можно и нужно развивать всем кто желает улучшить свое понимание устройства Мира и достигать любых, '
                            'поставленных перед собой целей. Решение сложных задач тренирует не только '
                            'логическое мышление, но и волю, терпение, умение не сдаваться перед трудностями и '
                            'неизвестностью. Каждая задача — это возможность стать лучше, ментально сильнее и увереннее в своих способностях.',
                      ),
                      const SizedBox(height: 24),

                      // Features section
                      _buildFeaturesSection(context),
                      const SizedBox(height: 24),

                      // Illustration placeholder
                      _buildIllustrationPlaceholder(context, 2),
                      const SizedBox(height: 24),

                      // Motivation
                      _buildSection(
                        context,
                        title: 'Мотивация и поддержка',
                        content: 'Приложение не оставит вас наедине с трудностями. Персональные помощники — '
                            'Кот Базис, Дворник Петрович и Адриен-Мари Лежандр — всегда готовы подсказать, направить и '
                            'поддержать. Система мотивации отслеживает ваш прогресс, напоминает о занятиях '
                            'и празднует ваши достижения. Стрики, XP, достижения — всё это превращает '
                            'учёбу в увлекательный процесс.',
                      ),
                      const SizedBox(height: 24),

                      // Target audience
                      _buildAudienceSection(context),
                      const SizedBox(height: 24),

                      // Illustration placeholder
                      _buildIllustrationPlaceholder(context, 3),
                      const SizedBox(height: 24),

                      // Knowledge map
                      _buildSection(
                        context,
                        title: 'Карта знаний',
                        content: 'Каждая задача связана с концептами — фундаментальными идеями и методами. '
                            'Решая задачи, вы не просто получаете ответы — вы строите свою личную карту знаний. '
                            'Приложение анализирует ваши решения и показывает, какие концепты вы освоили, '
                            'а над какими ещё стоит поработать. Это помогает видеть прогресс и планировать '
                            'дальнейшее развитие.',
                      ),
                      const SizedBox(height: 24),

                      // Call to action
                      _buildCallToAction(context),
                      const SizedBox(height: 32),

                      // Version info
                      _buildVersionInfo(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/lezhandr.webp',
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        Text(
          'Лежандр',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Ваш путь к мастерству',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final features = [
      ('📖', 'Учёт задач', 'Отслеживайте все решённые задачи, время, затраченное на каждую, и свой прогресс'),
      ('🧠', 'Карта концептов', 'Стройте персональную карту знаний и отслеживайте освоенные методы'),
      ('💡', 'Подсказки', 'Получайте помощь от AI-ассистентов, когда застряли на сложном месте'),
      ('🏆', 'Мотивация', 'Стрики, достижения, XP — превращайте учёбу в игру'),
      ('📸', 'Фото задач', 'Фотографируйте условия и решения — приложение распознает текст'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Возможности',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.$1,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.$2,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          feature.$3,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildAudienceSection(BuildContext context) {
    final audiences = [
      ('Школьники', 'Подготовка к олимпиадам, экзаменам, углубление школьной программы'),
      ('Студенты', 'Освоение университетских курсов, подготовка к сессиям'),
      ('Самообразование', 'Непрерывное развитие, изучение новых областей знаний'),
      ('Исследователи', 'Развитие аналитического мышления, освоение методов познания'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Для кого',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: audiences.map((audience) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      audience.$1,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      audience.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )).toList(),
        ),
      ],
    );
  }

  Widget _buildIllustrationPlaceholder(BuildContext context, int index) {
    // Placeholder for future illustrations
    if (index == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 180,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Путь к знаниям',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (index == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 150,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Развитие мышления',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 150,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Откройте новые горизонты',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildCallToAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 12),
          Text(
            'Готовы начать?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Каждая решённая задача делает вас лучше. '
            'Продолжите путь к мастерству сегодня!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
            textAlign: TextAlign.center,
          ),
          if (widget.isFirstLaunch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _closeScreen,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Начать решать'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                foregroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Лежандр v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'MindVector Client \n kreagenium.ru',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.push('/privacy'),
            icon: const Icon(Icons.privacy_tip_outlined, size: 18),
            label: const Text('Политика конфиденциальности'),
          ),
        ],
      ),
    );
  }

  void _closeScreen() {
    if (widget.isFirstLaunch) {
      // Mark welcome as seen and navigate to home
      ref.read(hasSeenWelcomeProvider.notifier).setSeen();
      context.go('/main/home');
    } else {
      Navigator.pop(context);
    }
  }
}

/// Provider to track if user has seen the welcome screen
final hasSeenWelcomeProvider = StateNotifierProvider<HasSeenWelcomeNotifier, bool>((ref) {
  return HasSeenWelcomeNotifier();
});

class HasSeenWelcomeNotifier extends StateNotifier<bool> {
  static const _key = 'has_seen_welcome';

  HasSeenWelcomeNotifier() : super(false);

  Future<bool> checkSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setSeen() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
