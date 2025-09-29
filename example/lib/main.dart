import 'package:flutter/material.dart';
import 'package:ranking_system/ranking_system.dart';

void main() {
  runApp(LeaderboardApp());
}

class LeaderboardApp extends StatelessWidget {
  const LeaderboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Tournament Rankings',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: TournamentLeaderboard(),
    );
  }
}

class TournamentLeaderboard extends StatefulWidget {
  const TournamentLeaderboard({super.key});

  @override
  State<TournamentLeaderboard> createState() => _TournamentLeaderboardState();
}

class _TournamentLeaderboardState extends State<TournamentLeaderboard> {
  late Ranking ranking;

  @override
  void initState() {
    super.initState();
    ranking = createTournamentRanking();
  }

  Ranking createTournamentRanking() {
    // Create athletes with their performance metrics
    final athletes = [
      RankingEntry(
        name: "Alex Morgan",
        metrics: {
          "sprint_100m": 12.3, // seconds (lower is better)
          "long_jump": 6.2, // meters (higher is better)
          "shot_put": 14.8, // meters (higher is better)
          "high_jump": 1.75, // meters (higher is better)
          "pole_vault": 4.2, // meters (higher is better)
          "javelin": 52.3, // meters (higher is better)
          "discus": 45.6, // meters (higher is better)
          "hammer": 58.9, // meters (higher is better)
          "marathon": 158.5, // minutes (lower is better)
          "endurance_score": 87, // points (higher is better)
        },
      ),
      RankingEntry(
        name: "Mike Chen",
        metrics: {
          "sprint_100m": 11.8,
          "long_jump": 7.1,
          "shot_put": 16.2,
          "high_jump": 1.85,
          "pole_vault": 4.8,
          "javelin": 58.7,
          "discus": 48.3,
          "hammer": 62.1,
          "marathon": 142.3,
          "endurance_score": 92,
        },
      ),
      RankingEntry(
        name: "Emma Rodriguez",
        metrics: {
          "sprint_100m": 12.1,
          "long_jump": 7.1,
          "shot_put": 13.9,
          "high_jump": 1.82,
          "pole_vault": 4.5,
          "javelin": 54.1,
          "discus": 43.2,
          "hammer": 80.3,
          "marathon": 149.8,
          "endurance_score": 89,
        },
      ),
      RankingEntry(
        name: "David Kim",
        metrics: {
          "sprint_100m": 11.9,
          "long_jump": 6.9,
          "shot_put": 15.7,
          "high_jump": 1.78,
          "pole_vault": 4.6,
          "javelin": 56.2,
          "discus": 46.8,
          "hammer": 60.3,
          "marathon": 145.2,
          "endurance_score": 85,
        },
      ),
      RankingEntry(
        name: "Lisa Thompson",
        metrics: {
          "sprint_100m": 12.5,
          "long_jump": 6.1,
          "shot_put": 13.2,
          "high_jump": 1.72,
          "pole_vault": 4.0,
          "javelin": 49.8,
          "discus": 41.5,
          "hammer": 54.2,
          "marathon": 162.1,
          "endurance_score": 83,
        },
      ),
      RankingEntry(
        name: "Sarah Johnson",
        metrics: {
          "sprint_100m": 11.7,
          "long_jump": 7.3,
          "shot_put": 16.8,
          "high_jump": 1.88,
          "pole_vault": 5.1,
          "javelin": 61.2,
          "discus": 50.1,
          "hammer": 64.5,
          "marathon": 138.9,
          "endurance_score": 94,
        },
      ),
    ];

    // Group related events
    final groups = [
      RankingGroup(
        name: "Sprint & Jump",
        groupFunction: (categories) => {"sprint_100m", "long_jump", "high_jump", "pole_vault"},
      ),
      RankingGroup(name: "Throwing Events", groupFunction: (categories) => {"shot_put", "javelin", "discus", "hammer"}),
      RankingGroup(name: "Endurance", groupFunction: (categories) => {"marathon", "endurance_score"}),
    ];

    // Set initial weights (0-10 scale)
    final weights = {
      "Sprint & Jump": 7, // 1.7x multiplier - high importance
      "Throwing Events": 5, // 1.5x multiplier - medium importance
      "Endurance": 8, // 1.8x multiplier - highest importance
    };

    return Ranking.calculate(
      entries: athletes,
      groups: groups,
      weights: weights,
      isAscendingMetric: (metric) {
        // Lower times are better for sprint and marathon
        return metric == "sprint_100m" || metric == "marathon";
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Event Tournament'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                ranking = createTournamentRanking();
              });
            },
          ),
        ],
      ),
      body: LeaderboardView(
        ranking: ranking,
        title: const Text(
          '🏆 Decathlon Championship 2025',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        includeCategoryRanking: true,
        isReversedRanking: false,
        // Higher scores are better
        additionalInformation: Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tournament Information:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('📅 Date: March 15-17, 2024'),
                const Text('📍 Location: Olympic Stadium'),
                const Text('🌟 Prize Pool: \$50,000'),
                const SizedBox(height: 8),
                const Text('Scoring System:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• Sprint & Jump Events: 70% weight'),
                const Text('• Throwing Events: 50% weight'),
                const Text('• Endurance Events: 80% weight'),
                const SizedBox(height: 8),
                Text(
                  'Total Athletes: ${ranking.getLeaderboardRanking().length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
