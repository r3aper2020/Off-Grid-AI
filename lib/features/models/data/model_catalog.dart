/// A model the app knows how to download and verify.
class CatalogModel {
  const CatalogModel({
    required this.displayName,
    required this.fileName,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
    required this.license,
    required this.summary,
  });

  final String displayName;
  final String fileName;
  final Uri url;
  final int sizeBytes;
  final String sha256;
  final String license;
  final String summary;
}

/// Built-in catalog. Size and SHA-256 come from the Hugging Face LFS
/// metadata; a download is installed only if both match.
abstract final class ModelCatalog {
  static final recommended = CatalogModel(
    displayName: 'Qwen3 4B Instruct',
    fileName: 'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
    url: Uri.parse(
      'https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/'
      'main/Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
    ),
    sizeBytes: 2497281120,
    sha256: '3605803b982cb64aead44f6c1b2ae36e3acdb41d8e46c8a94c6533bc4c67e597',
    license: 'Apache-2.0',
    summary: 'Strong general assistant for phones with 8 GB+ memory.',
  );
}
