import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/theme_constants.dart';
import 'grade_breakdown_screen.dart';

class SemesterResultsScreen extends StatefulWidget {
  const SemesterResultsScreen({super.key});

  @override
  State<SemesterResultsScreen> createState() => _SemesterResultsScreenState();
}

class _SemesterResultsScreenState extends State<SemesterResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primary,
              child: const Row(
                children: [
                  Icon(Icons.assessment_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Grade Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.primary,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Overall'),
                  Tab(text: 'By Semester'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.background,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverallTab(provider),
                    _buildSemesterTab(provider),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverallTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.gradientCard,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.cgpa.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Cumulative GPA',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${provider.grades.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Total Courses',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('All Courses', style: AppTextStyles.h3),
              Text(
                '${provider.grades.length} entries',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...provider.grades.map((grade) {
            final course = provider.getCourseInfo(grade.courseCode);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeBreakdownScreen(
                    grade: grade,
                    course: course,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.whiteCard,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.book_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(grade.courseCode,
                              style: AppTextStyles.body),
                          Text(course?.courseTitle ?? '',
                              style: AppTextStyles.caption),
                          Text(grade.semester,
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTextStyles.gradeBgColor(grade.letterGrade)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(grade.letterGrade,
                              style: AppTextStyles.gradeColor(grade.letterGrade)),
                          Text(
                            grade.totalScore.toStringAsFixed(1),
                            style: TextStyle(
                              color: AppTextStyles.gradeBgColor(grade.letterGrade)
                                  .withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSemesterTab(AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.outlinedCard,
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text('Select Semester',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: provider.semesters.isNotEmpty
                        ? provider.selectedSemester
                        : null,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.primary,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    items: provider.semesters.map((s) {
                      return DropdownMenuItem(
                          value: s, child: Text(s));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) provider.selectSemester(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        provider.selectedGPA.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Semester GPA',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        provider.cgpa.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('CGPA',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Semester Courses', style: AppTextStyles.h3),
              Text(
                '${provider.getGradesForSemester(provider.selectedSemester).length} courses',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...provider
              .getGradesForSemester(provider.selectedSemester)
              .map((grade) {
            final course = provider.getCourseInfo(grade.courseCode);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GradeBreakdownScreen(
                      grade: grade, course: course),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.whiteCard,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.book_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(grade.courseCode,
                              style: AppTextStyles.body),
                          Text(course?.courseTitle ?? '',
                              style: AppTextStyles.caption),
                          Text('${course?.creditHours ?? 0} Credits',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTextStyles.gradeBgColor(grade.letterGrade)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(grade.letterGrade,
                              style: AppTextStyles.gradeColor(grade.letterGrade)),
                          Text(
                            grade.totalScore.toStringAsFixed(1),
                            style: TextStyle(
                              color: AppTextStyles.gradeBgColor(grade.letterGrade)
                                  .withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
