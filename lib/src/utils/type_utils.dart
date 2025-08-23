extension RecordEntries<K, V> on Map<K, V> {
  /// Returns an [Iterable] of key-value pairs as records.
  ///
  /// Example:
  /// ```dart
  /// final map = {'a': 1, 'b': 2};
  /// for (final (key, value) in map.entriesRecord) {
  ///   print('$key: $value'); // Types are inferred: key as String, value as int
  /// }
  /// ```
  Iterable<(K, V)> get entriesRecord => entries.map((entry) => (entry.key, entry.value));
}