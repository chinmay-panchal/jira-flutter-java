import 'package:shared_preferences/shared_preferences.dart';

class FrequentProjectsService {
  static const String _keyPrefix = 'project_view_count_';
  static const int topCount = 2;

  /// Call this every time a project is opened.
  Future<void> recordView(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$projectId';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// Returns a set of project IDs for the top [topCount] most-viewed projects.
  Future<Set<int>> getFrequentProjectIds(List<int> allIds) async {
    final prefs = await SharedPreferences.getInstance();

    final counts = {
      for (final id in allIds) id: prefs.getInt('$_keyPrefix$id') ?? 0,
    };

    // Only consider projects that have been viewed at least once
    final viewed = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return viewed.take(topCount).map((e) => e.key).toSet();
  }

  /// Call this when a project is deleted so its count is cleaned up.
  Future<void> removeProject(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$projectId');
  }
}
