import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/psychological_test.dart';
import '../providers/content_provider.dart';
import '../repositories/content_repository.dart';

class TestTakingScreen extends ConsumerStatefulWidget {
  final PsychologicalTest test;

  const TestTakingScreen({super.key, required this.test});

  @override
  ConsumerState<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends ConsumerState<TestTakingScreen> {
  int _currentQuestion = 0;
  final Map<int, int> _answers = {}; // questionIndex -> selectedOptionScore
  final Map<int, int> _selectedOptionIndex = {}; // questionIndex -> optionIndex
  bool _isSubmitting = false;
  bool _showResult = false;
  int _totalScore = 0;
  ScoringRange? _interpretation;

  PsychologicalTest get test => widget.test;
  int get totalQuestions => test.questions.length;
  double get progress => (_currentQuestion + 1) / totalQuestions;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(languageProvider).language;
    final isArabic = lang == AppLanguage.arabic;

    if (_showResult) {
      return _buildResultScreen(context, isDark, isArabic, s);
    }

    final question = test.questions[_currentQuestion];
    final questionText = isArabic ? question.text : question.textEn;
    final testTitle = isArabic ? test.title : test.titleEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          testTitle,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${s.questionN} ${_currentQuestion + 1} / $totalQuestions',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questionText,
                    style: AppTypography.headingSmall.copyWith(
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(question.options.length, (index) {
                    final option = question.options[index];
                    final isSelected =
                        _selectedOptionIndex[_currentQuestion] == index;
                    return _buildOptionTile(
                      context,
                      option,
                      index,
                      isSelected,
                      isDark,
                      isArabic,
                    );
                  }),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentQuestion > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _currentQuestion--);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                      child: Text(s.previous),
                    ),
                  ),
                if (_currentQuestion > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedOptionIndex
                            .containsKey(_currentQuestion)
                        ? () {
                            if (_currentQuestion < totalQuestions - 1) {
                              setState(() => _currentQuestion++);
                            } else {
                              _submitTest();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _currentQuestion < totalQuestions - 1
                                ? s.next
                                : s.finishTest,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    TestOption option,
    int index,
    bool isSelected,
    bool isDark,
    bool isArabic,
  ) {
    final optionText = isArabic ? option.text : option.textEn;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOptionIndex[_currentQuestion] = index;
            _answers[_currentQuestion] = option.score;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : (isDark ? const Color(0xFF1F2937) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.2)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.textSecondary,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  optionText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white : AppColors.textPrimary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTest() async {
    setState(() => _isSubmitting = true);

    _totalScore = _answers.values.fold(0, (sum, score) => sum + score);
    _interpretation = test.getInterpretation(_totalScore);

    final repo = ref.read(contentRepositoryProvider);
    await repo.saveTestResult(
      testId: test.id,
      testType: test.type,
      totalScore: _totalScore,
      interpretation: _interpretation?.level ?? 'unknown',
      answers: List.generate(
        totalQuestions,
        (i) => _answers[i] ?? 0,
      ),
    );

    // Invalidate test results cache
    ref.invalidate(testResultsProvider);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showResult = true;
      });
    }
  }

  Widget _buildResultScreen(
      BuildContext context, bool isDark, bool isArabic, S s) {
    final interpretationText = isArabic
        ? (_interpretation?.text ?? '')
        : (_interpretation?.textEn ?? '');
    final level = _interpretation?.level ?? '';

    Color levelColor;
    IconData levelIcon;
    switch (level) {
      case 'minimal':
        levelColor = Colors.green;
        levelIcon = Icons.sentiment_very_satisfied;
        break;
      case 'mild':
        levelColor = Colors.amber;
        levelIcon = Icons.sentiment_satisfied;
        break;
      case 'moderate':
        levelColor = Colors.orange;
        levelIcon = Icons.sentiment_neutral;
        break;
      case 'severe':
      case 'moderately_severe':
        levelColor = Colors.red;
        levelIcon = Icons.sentiment_dissatisfied;
        break;
      default:
        levelColor = AppColors.primary;
        levelIcon = Icons.info_outline;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.testResult,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(levelIcon, size: 64, color: levelColor),
            ),
            const SizedBox(height: 24),
            Text(
              s.yourScore,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_totalScore',
              style: AppTypography.displayLarge.copyWith(
                fontSize: 48,
                color: levelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    s.interpretationLabel,
                    style: AppTypography.headingSmall.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    interpretationText,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.testDisclaimer,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.amber.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(s.goBack),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
