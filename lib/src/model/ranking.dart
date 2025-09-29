import 'package:collection/collection.dart';
import 'package:ranking_system/src/utils/type_utils.dart';

typedef Score = num; // Score for RankingEntry, calculated from position for a given category
typedef Place = int; // Place for RankingEntry in List for LeaderboardRanking, can be tied

class RankingEntry {
  final String name;
  final Map<String, Comparable> metrics;

  RankingEntry({required this.name, required this.metrics});
}

class RankingGroup {
  final String name;
  final Set<String> Function(Set<String>) groupFunction;

  RankingGroup({required this.name, required this.groupFunction});
}

final class _RankingResult {
  final Map<String, Map<RankingEntry, Score>> categoryRankingMap;
  final Map<String, Map<RankingEntry, Score>>? groupRankingMap;
  final Map<RankingEntry, Score> leaderboard;

  final List<(Place, RankingEntry, Score)> calculatedLeaderboardRanking;

  _RankingResult.categoryRanking(this.categoryRankingMap)
    : groupRankingMap = null,
      leaderboard = {},
      calculatedLeaderboardRanking = [];

  _RankingResult.groupRanking(this.categoryRankingMap, this.groupRankingMap)
    : leaderboard = {},
      calculatedLeaderboardRanking = [];

  _RankingResult.leaderboard(this.categoryRankingMap, this.groupRankingMap, this.leaderboard)
    : calculatedLeaderboardRanking = calculateLeaderboardRanking(leaderboard);

  static List<(Place, RankingEntry, Score)> calculateLeaderboardRanking(final Map<RankingEntry, num> leaderboard) {
    // Sort by score descending (highest first)
    final sortedEntries = leaderboard.entries.sorted((e1, e2) => e1.value.compareTo(e2.value)).reversed.toList();

    final List<(Place, RankingEntry, num)> result = [];

    Place currentPlace = 1;
    num? previousScore;

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final currentScore = entry.value;

      // If score is different from previous, update place to current index + 1
      if (previousScore != null && currentScore != previousScore) {
        currentPlace = i + 1;
      }

      result.add((currentPlace, entry.key, currentScore));
      previousScore = currentScore;
    }

    return result;
  }

  int getPlace(String entryName) {
    return calculatedLeaderboardRanking.where((e) => e.$2.name == entryName).first.$1;
  }

  num getScore(String entryName) {
    return leaderboard.entries.where((entry) => entry.key.name == entryName).firstOrNull?.value ?? 0.0;
  }

  /// Get the actual ranking map that is used for the leaderboard calculation
  Map<String, Map<RankingEntry, Score>> get rankingMap => groupRankingMap != null ? groupRankingMap! : categoryRankingMap;

  int get numberCompetitors => leaderboard.keys.length;

  Set<String> get rankingCategories => rankingMap.keys.toSet();

  int get numberCategories => rankingCategories.length;
}

class Ranking {
  final _RankingResult _result;
  final Map<String, int> _appliedWeights;

  Ranking._(this._result, this._appliedWeights);

  factory Ranking.calculate({
    required List<RankingEntry> entries,
    List<RankingGroup>? groups,
    Map<String, int>? weights,
    bool Function(String)? isAscendingMetric,
  }) {
    // Set ascending to false by default
    isAscendingMetric ??= (_) => false;

    final categoryRankingResult = _calculateCategoryRanking(entries, isAscendingMetric);

    // Apply groups to calculated rankings
    final groupRankingResult = _calculateGroupRanking(groups, categoryRankingResult);

    // Set weights to 0 by default
    weights ??= Map.fromEntries(
      groupRankingResult.rankingMap.keys.map((categoryOrGroupName) => MapEntry(categoryOrGroupName, 0)),
    );

    // Calculate leaderboard from rankings with weights
    final leaderboardRankingResult = _calculateLeaderboardWithWeights(groupRankingResult, weights);

    return Ranking._(leaderboardRankingResult, weights);
  }

  static _RankingResult _calculateCategoryRanking(List<RankingEntry> entries, bool Function(String) isAscendingMetric) {
    // Get categories
    final Set<String> categories = {};
    for (final entry in entries) {
      categories.addAll(entry.metrics.keys);
    }
    // Validate that all entries have the same categories
    for (final category in categories) {
      for (final entry in entries) {
        if (!entry.metrics.containsKey(category)) {
          throw Exception('Found a category ($category) that is not existent in all ranking entries!');
        }
      }
    }

    // Calculate rankings for given categories
    final Map<String, Map<RankingEntry, Score>> categoryRanking = {};
    for (final category in categories) {
      categoryRanking[category] = _calculateRanking(category, entries, isAscendingMetric(category));
    }
    return _RankingResult.categoryRanking(categoryRanking);
  }

  static Map<RankingEntry, int> _calculateRanking(String category, List<RankingEntry> entries, bool isAscending) {
    List<RankingEntry> sorted = entries.sorted((e1, e2) => e1.metrics[category]!.compareTo(e2.metrics[category]!));

    if (isAscending) {
      sorted = sorted.reversed.toList();
    }

    final Map<RankingEntry, int> result = {};
    int currentRank = 1;
    int sameRankCount = 0;

    // Handle first entry
    Comparable previousScore = sorted.first.metrics[category]!;
    result[sorted.first] = currentRank;

    // Process remaining entries
    for (int i = 1; i < sorted.length; i++) {
      final currentScore = sorted[i].metrics[category]!;

      if (currentScore.compareTo(previousScore) == 0) {
        // Same score as previous entry, assign same rank
        result[sorted[i]] = currentRank;
        sameRankCount++;
      } else {
        // Different score, assign next rank (skip ranks for ties)
        currentRank += sameRankCount + 1;
        result[sorted[i]] = currentRank;
        sameRankCount = 0;
      }

      previousScore = currentScore;
    }

    return result;
  }

  static _RankingResult _calculateGroupRanking(List<RankingGroup>? groups, _RankingResult categoryRanking) {
    if (groups == null) {
      return categoryRanking;
    }

    final categories = categoryRanking.rankingCategories;
    final groupRanking = Map<String, Map<RankingEntry, Score>>.from(categoryRanking.categoryRankingMap);

    for (final group in groups) {
      final categoriesToGroup = group.groupFunction(categories);
      // Check that all categories exist
      for (final categoryToGroup in categoriesToGroup) {
        if (!groupRanking.containsKey(categoryToGroup)) {
          throw Exception('Did not find group $categoryToGroup in existing categories!');
        }
      }
      final averagedRanking = _getRankingsAverage(
        groupRanking.entries
            .where((entry) => categoriesToGroup.contains(entry.key))
            .map((entry) => entry.value)
            .toList(),
      );
      groupRanking[group.name] = averagedRanking;
      groupRanking.removeWhere((key, _) => categoriesToGroup.contains(key));
    }

    return _RankingResult.groupRanking(categoryRanking.categoryRankingMap, groupRanking);
  }

  /// Averages over all rankings within a group
  static Map<RankingEntry, double> _getRankingsAverage(List<Map<RankingEntry, Score>> rankings) {
    final Map<RankingEntry, double> result = {};
    final int numberRankings = rankings.length;
    for (final ranking in rankings) {
      for (final (rankingEntry, score) in ranking.entriesRecord) {
        result.putIfAbsent(rankingEntry, () => 0.0);
        final newValue = (result[rankingEntry] ?? 0.0) + score;
        result[rankingEntry] = newValue;
      }
    }
    return result.map((k, v) => MapEntry(k, v / numberRankings));
  }

  static _RankingResult _calculateLeaderboardWithWeights(_RankingResult groupRanking, Map<String, int> weights) {
    final rankingMap = groupRanking.rankingMap;

    final Map<RankingEntry, double> leaderboard = {};
    for (final (categoryOrGroupName, ranking) in rankingMap.entriesRecord) {
      for (final (rankingEntry, score) in ranking.entriesRecord) {
        leaderboard.putIfAbsent(rankingEntry, () => 0.0);
        final weightedScore = score * getScoreMultiplier(weights[categoryOrGroupName]!);

        final accumulatedScore = (leaderboard[rankingEntry] ?? 0.0) + weightedScore;
        leaderboard[rankingEntry] = accumulatedScore;
      }
    }
    return _RankingResult.leaderboard(groupRanking.categoryRankingMap, groupRanking.groupRankingMap, leaderboard);
  }

  static double getScoreMultiplier(int weight) {
    return 1 + (weight / 10);
  }

  Ranking updateWeights(Map<String, int> updatedWeights) {
    final newLeaderboardResult = _calculateLeaderboardWithWeights(_result, updatedWeights);
    return Ranking._(newLeaderboardResult, updatedWeights);
  }

  static String _formatRankingScore(Score value) {
    if (value == double.maxFinite) {
      return "Infinite";
    }
    return value.toStringAsFixed(1);
  }

  String? verboseRankingByEntry(String entryName) {
    final rankingEntry = _result.leaderboard.keys.where((entry) => entry.name == entryName).firstOrNull;
    if (rankingEntry == null) {
      return null;
    }

    final leaderboardPlace = _result.getPlace(entryName);
    final totalScore = _formatRankingScore(_result.getScore(entryName));
    final verboseRankString = _result.rankingMap.entries
        .map(
          (entry) =>
              '${entry.key}: '
              'Score: ${entry.value.entries.where((categoryEntry) => categoryEntry.key.name == entryName).first.value}'
              '${rankingEntry.metrics[entry.key] != null ? ' (Metric: ${rankingEntry.metrics[entry.key].toString()}))' : ' (Metric: combined)'}',
        )
        .join('\n');
    return '$entryName:\n'
        'Global Position: $leaderboardPlace. Place\n\n'
        'Categories: \n'
        '$verboseRankString\n'
        '\nNumber of competitors: ${_result.numberCompetitors}'
        '\nNumber of categories: ${_result.numberCategories}'
        '\nTotal score: $totalScore';
  }

  String copiedRanking() {
    String result = "";
    for (final entry in _result.leaderboard.keys) {
      result += "${verboseRankingByEntry(entry.name)}\n\n";
    }
    return result;
  }

  double get maximumRankingValue {
    final maxRankPerCategory = _result.numberCompetitors.toDouble();

    return _result.rankingCategories
        .map((category) => maxRankPerCategory * getScoreMultiplier(_appliedWeights[category] ?? 0))
        .sum;
  }

  List<String> get categories => _result.rankingMap.keys.toList();

  List<(Place, RankingEntry, Score)> getLeaderboardRanking({bool ascending = false}) {
    return ascending ? _result.calculatedLeaderboardRanking.reversed.toList() : _result.calculatedLeaderboardRanking;
  }

  List<(Place, RankingEntry, Score)>? getCategoryRanking({required String category, bool ascending = false}) {
    final categoryMap = _result.categoryRankingMap[category];
    if (categoryMap == null) {
      return null;
    }
    final categoryRanking = _RankingResult.calculateLeaderboardRanking(categoryMap);
    return ascending ? categoryRanking.reversed.toList() : categoryRanking;
  }

  Set<String> get rankingCategories => _result.rankingCategories;

  /// Categories before grouping was applied
  Set<String> get rawCategories => _result.categoryRankingMap.keys.toSet();
}
