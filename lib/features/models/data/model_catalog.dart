/// A second GGUF a vision model needs: the multimodal projector (mmproj)
/// that turns a photo into tokens the model can read.
class CatalogProjector {
  const CatalogProjector({
    required this.fileName,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
  });

  final String fileName;
  final Uri url;
  final int sizeBytes;
  final String sha256;
}

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
    this.minMemoryGb = 8,
    this.projector,
  });

  final String displayName;
  final String fileName;
  final Uri url;
  final int sizeBytes;
  final String sha256;
  final String license;
  final String summary;

  /// Phone memory the model needs with its context cache.
  final int minMemoryGb;

  /// Present when the model can see photos (downloaded alongside).
  final CatalogProjector? projector;

  bool get canSeeImages => projector != null;

  /// Bytes to download in all.
  int get totalBytes => sizeBytes + (projector?.sizeBytes ?? 0);
}

/// Built-in catalog. Size and SHA-256 come from the Hugging Face LFS
/// metadata; a download is installed only if both match. Every entry is
/// a plain GGUF under a permissive license; the user picks one (or
/// several) and switches between them on the AI model screen.
abstract final class ModelCatalog {
  static final models = <CatalogModel>[
    // Q4_0: llama.cpp repacks these weights for ARM dot-product kernels,
    // so prompt reading (the wait before the first word) is far faster
    // on a phone than Q4_K_M at a small cost in wording quality.
    CatalogModel(
      displayName: 'Qwen3 4B Instruct (fast)',
      fileName: 'Qwen3-4B-Instruct-2507-Q4_0.gguf',
      url: Uri.parse(
        'https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/'
        'main/Qwen3-4B-Instruct-2507-Q4_0.gguf',
      ),
      sizeBytes: 2375773280,
      sha256:
          'e0ba675d86ab277c61701c6793659b2ae801d95e3be791464c321e6fbf613be2',
      license: 'Apache-2.0',
      summary:
          'Best balance for most phones: the same 4B model in the build '
          'phone processors run fastest, so it starts answering sooner.',
    ),
    CatalogModel(
      displayName: 'Qwen3 VL 4B Instruct (vision)',
      fileName: 'Qwen3-VL-4B-Instruct-Q4_0.gguf',
      url: Uri.parse(
        'https://huggingface.co/unsloth/Qwen3-VL-4B-Instruct-GGUF/resolve/'
        'main/Qwen3-VL-4B-Instruct-Q4_0.gguf',
      ),
      sizeBytes: 2375774496,
      sha256:
          '09965766e92778b591ab9da5209463b843d000449b38d909055b399d8dbd3d76',
      license: 'Apache-2.0',
      summary:
          'Sees photos: snap a plant, a wound, a device or a label and ask '
          'about it. Same size and speed as the fast model for text, plus '
          'an 836 MB vision file; reading a photo adds time before the '
          'first word.',
      projector: CatalogProjector(
        fileName: 'Qwen3-VL-4B-mmproj-F16.gguf',
        url: Uri.parse(
          'https://huggingface.co/unsloth/Qwen3-VL-4B-Instruct-GGUF/resolve/'
          'main/mmproj-F16.gguf',
        ),
        sizeBytes: 836180640,
        sha256:
            '1b9f4e92f0fbda14d7d7b58baed86039b8a980fe503d9d6a9393f25c0028f1fc',
      ),
    ),
    CatalogModel(
      displayName: 'Qwen3 4B Instruct (standard)',
      fileName: 'Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
      url: Uri.parse(
        'https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/'
        'main/Qwen3-4B-Instruct-2507-Q4_K_M.gguf',
      ),
      sizeBytes: 2497281120,
      sha256:
          '3605803b982cb64aead44f6c1b2ae36e3acdb41d8e46c8a94c6533bc4c67e597',
      license: 'Apache-2.0',
      summary:
          'Slightly better wording than the fast build, but noticeably '
          'longer to start answering on a phone.',
    ),
    CatalogModel(
      displayName: 'Qwen3 1.7B (small)',
      fileName: 'Qwen3-1.7B-Q4_0.gguf',
      url: Uri.parse(
        'https://huggingface.co/unsloth/Qwen3-1.7B-GGUF/resolve/main/'
        'Qwen3-1.7B-Q4_0.gguf',
      ),
      sizeBytes: 1056782912,
      sha256:
          'c876f159707a4e4f70e045106c69db15bfc935a4981706fd4f65c6e7ea1e81c5',
      license: 'Apache-2.0',
      summary:
          'Only if a 4B model won\'t fit (6 GB phones). About half the wait, '
          'but answers are much thinner and tend to recite the library '
          'instead of advising. Use a 4B model whenever you can.',
      minMemoryGb: 6,
    ),
  ];

  static CatalogModel get recommended => models.first;

  /// Whether [installed] is this catalog entry (matched by file, or by
  /// the name used before the catalog had more than one model).
  static bool isInstalled(CatalogModel model, String fileName, String name) =>
      fileName == model.fileName ||
      name == model.displayName ||
      (name == 'Qwen3 4B Instruct' && model.fileName.contains('Q4_K_M'));
}
