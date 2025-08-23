import 'package:flutter_test/flutter_test.dart';
import 'package:ranking_system/ranking_system.dart';

void main() {
  group('Ranking', () {
    test('Ranking is calculated correctly', () async {
      final testData = [
        RankingEntry(name: 'A', metrics: {'Health': 10, 'Environment': 5.5, 'Economy': 2.3}),
        RankingEntry(name: 'B', metrics: {'Health': 9, 'Environment': 5.5, 'Economy': 2.3}),
        RankingEntry(name: 'C', metrics: {'Health': 8, 'Environment': 5.5, 'Economy': 2.3}),
        RankingEntry(name: 'D', metrics: {'Health': 7, 'Environment': 5.5, 'Economy': 2.3}),
        RankingEntry(name: 'E', metrics: {'Health': 6, 'Environment': 5.5, 'Economy': 2.3}),
      ];

      final ranking = Ranking.calculate(entries: testData);
      print(ranking.copiedRanking());
      print(ranking.getLeaderboardRanking(ascending: false));
    });
    test('Ranking with groups is calculated correctly', () async {
      final testData = [
        RankingEntry(name: 'A', metrics: {'Health': 10, 'Environment': 5.5, 'Economy': 2.3}),
        RankingEntry(name: 'B', metrics: {'Health': 9, 'Environment': 5.5, 'Economy': 2.3}),
        RankingEntry(name: 'C', metrics: {'Health': 8, 'Environment': 5.5, 'Economy': 2.3}),
        RankingEntry(name: 'D', metrics: {'Health': 7, 'Environment': 5.5, 'Economy': 2.3}),
        RankingEntry(name: 'E', metrics: {'Health': 6, 'Environment': 5.5, 'Economy': 2.3}),
      ];

      final groups = [
        RankingGroup(
          name: 'EnvEco',
          groupFunction: (categories) =>
              categories.where((category) => ['Environment', 'Economy'].contains(category)).toSet(),
        ),
        RankingGroup(
          name: 'All',
          groupFunction: (_) => {'EnvEco', 'Health'},
        ),
      ];

      final ranking = Ranking.calculate(entries: testData, groups: groups);
      print(ranking.copiedRanking());
      print(ranking.verboseRankingByEntry("A"));
    });
  });
}
