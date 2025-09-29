import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:input_quantity/input_quantity.dart';

import '../model/ranking.dart';

class LeaderboardView extends StatefulWidget {
  final Ranking ranking;
  final bool includeCategoryRanking;
  final bool isReversedRanking; // Highest Score => Worst

  final Widget? title;
  final Widget? additionalInformation;

  const LeaderboardView({
    required this.ranking,
    this.includeCategoryRanking = false,
    this.isReversedRanking = false,
    this.title,
    this.additionalInformation,
    super.key,
  });

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  static const String _globalRankingName = 'global';
  late Ranking _currentRanking;

  String _selectedRanking = _globalRankingName;

  final Map<String, int> _weights = {};

  @override
  void initState() {
    super.initState();

    _currentRanking = widget.ranking;

    _weights.addAll(Map.fromEntries(_currentRanking.rankingCategories.map((indicator) => MapEntry(indicator, 0))));
  }

  String getScoreHint() {
    return widget.isReversedRanking ? "Worst Score" : "Best Score";
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildTitle(),
                  if (widget.includeCategoryRanking) buildRankingSelection(_currentRanking),
                  if (_selectedRanking == _globalRankingName) buildInformation(_currentRanking),
                  if (_selectedRanking == _globalRankingName) buildWeightsSelection(),
                  if (_selectedRanking == _globalRankingName) buildLeaderboardVisualization(_currentRanking),
                  if (_selectedRanking != _globalRankingName)
                    buildCategoryVisualization(_selectedRanking, _currentRanking),
                  Tooltip(
                    message: "Copy Ranking",
                    child: Center(
                      child: IconButton(
                        onPressed: () async =>
                            await Clipboard.setData(ClipboardData(text: _currentRanking.copiedRanking())),
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTitle() {
    return widget.title ?? const Text('Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget buildInformation(Ranking ranking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        ExpansionTile(
          title: const Text("Information"),
          children: [
            widget.additionalInformation ?? Container(),
            Text(
              'Theoretical Highest Ranking Score: ${ranking.maximumRankingValue.toStringAsFixed(1)}\n',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.isReversedRanking
                  ? 'Higher ranking is worse (ascending)\n'
                  : 'Higher ranking is better (descending)\n',
            ),
            const Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...ranking.categories.map((dataKey) => Text(dataKey)),
          ],
        ),
      ],
    );
  }

  Widget buildWeightsSelection() {
    return ExpansionTile(
      title: const Text("Change weights"),
      children: _weights.entries
          .map(
            (entry) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${entry.key}:"),
                const SizedBox(width: 5),
                Tooltip(
                  message: "${Ranking.getScoreMultiplier(entry.value).toStringAsFixed(1)}x counted",
                  child: InputQty.int(
                    initVal: entry.value,
                    maxVal: 10,
                    minVal: 0,
                    steps: 1,
                    decimalPlaces: 0,
                    onQtyChanged: (dynamic qty) {
                      setState(() {
                        _weights[entry.key] = qty;
                        _currentRanking = _currentRanking.updateWeights(_weights);
                      });
                    },
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget buildRankingSelection(Ranking ranking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('Select ranking:'),
        DropdownButton<String>(
          value: _selectedRanking,
          items:
              ranking.rawCategories
                  .map((category) => DropdownMenuItem<String>(value: category, child: Text(category)))
                  .toList()
                ..add(DropdownMenuItem(value: _globalRankingName, child: Text(_globalRankingName))),
          onChanged: (String? value) {
            setState(() {
              _selectedRanking = value ?? _selectedRanking;
            });
          },
        ),
      ],
    );
  }

  Widget buildLeaderboardVisualization(Ranking ranking) {
    final leaderboardRanking = ranking.getLeaderboardRanking();
    return buildRankingVisualization(ranking, leaderboardRanking, (entry) => entry.$3.toStringAsFixed(1));
  }

  Widget buildCategoryVisualization(String category, Ranking ranking) {
    final categoryRanking = ranking.getCategoryRanking(category: category);

    if (categoryRanking == null) {
      return Text("ERROR: No ranking found for category $category!");
    }

    return buildRankingVisualization(ranking, categoryRanking, (entry) => entry.$2.metrics[category].toString());
  }

  Widget buildRankingVisualization(
    Ranking ranking,
    List<(Place, RankingEntry, Score)> rankingList,
    String Function((Place, RankingEntry, Score)) retrieveScoreFunction,
  ) {
    // Group entries by place to identify ties
    final Map<int, List<(Place, RankingEntry, Score)>> groupedByPlace = {};
    for (final entry in rankingList) {
      final place = entry.$1;
      groupedByPlace.putIfAbsent(place, () => []).add(entry);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ...groupedByPlace.entries.map((placeGroup) {
              final place = placeGroup.key;
              final entries = placeGroup.value;
              final isTied = entries.length > 1;

              // Build the list tiles for this place group
              final tiles = entries.map((entry) {
                final name = entry.$2.name;
                final score = retrieveScoreFunction(entry);

                return Tooltip(
                  message: ranking.verboseRankingByEntry(name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: _getRankColor(place), shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '$place',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontSize: 18)),
                      subtitle: place == 0
                          ? Text(getScoreHint(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400))
                          : null,
                      trailing: Text(
                        score.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList();

              // Wrap tied entries with a border
              if (isTied) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(children: tiles),
                );
              } else {
                // Single entry, no border needed
                return tiles.first;
              }
            }),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int place) {
    final zeroIndexed = place - 1;
    // Reversed (High is worse)
    if (widget.isReversedRanking) {
      return switch (zeroIndexed) {
        0 => Colors.red,
        1 => Colors.orange,
        2 => Colors.orangeAccent,
        3 => Colors.yellow,
        4 => Colors.yellow.shade300,
        _ => Colors.blue,
      };
    }
    // Standard (High is better)
    return switch (zeroIndexed) {
      0 => Colors.orange, // GOLD
      1 => Colors.grey, // SILVER
      2 => Colors.amber, // BRONZE
      _ => Colors.blue,
    };
  }
}
