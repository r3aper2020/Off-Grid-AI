/// Turns a question into a meaning vector for semantic search. Returns
/// null when no embedder is available (search then uses keywords only).
abstract interface class TextEmbedder {
  Future<List<double>?> embedQuery(String text);
}

/// Keyword-only search (tests, or if the embedding model can't load).
class NoTextEmbedder implements TextEmbedder {
  const NoTextEmbedder();

  @override
  Future<List<double>?> embedQuery(String text) async => null;
}
