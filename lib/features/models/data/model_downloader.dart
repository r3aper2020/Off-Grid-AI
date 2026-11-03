import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';
import 'model_catalog.dart';
import 'model_store.dart';

/// Thrown when the user cancels a download.
class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// One download of a catalog model, streamed straight into [ModelStore]
/// (which writes a `.part` file and verifies size and SHA-256 before
/// installing). This is the only code in the app that uses the network,
/// and it only runs when the user taps Download.
///
/// Dropped connections are common on multi-GB downloads, so when one drops
/// the download reconnects and asks for the remaining bytes with an HTTP
/// Range request. The store sees one continuous stream, and its SHA-256
/// check covers the stitched result.
class ModelDownload {
  ModelDownload(
    this._store,
    this.model, {
    this.maxRetries = 60,
    Duration Function(int attempt)? retryDelay,
  }) : _retryDelay = retryDelay ?? _defaultDelay;

  final ModelStore _store;
  final CatalogModel model;

  /// Consecutive failed reconnects allowed (reset whenever bytes arrive);
  /// the default waits about half an hour for the network to come back.
  final int maxRetries;
  final Duration Function(int attempt) _retryDelay;

  final _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..userAgent = 'offgrid-ai';
  bool _cancelled = false;
  final _cancelSignal = Completer<void>();

  /// Bytes stop arriving for this long → treat the connection as dead.
  static const _stallTimeout = Duration(seconds: 60);
  static const _maxRedirects = 5;

  static Duration _defaultDelay(int attempt) =>
      Duration(seconds: [2, 4, 8, 15, 30, 30][(attempt - 1).clamp(0, 5)]);

  /// Downloads the model and, for a vision model, its projector after it.
  /// [onProgress] counts bytes across both files (see
  /// [CatalogModel.totalBytes]). A failed projector download leaves the
  /// model installed as text-only and reports the error.
  Future<InstalledModel> run({void Function(int written)? onProgress}) async {
    try {
      final installed = await _store.import(
        originalName: model.fileName,
        displayName: model.displayName,
        bytes: _resumableBytes(model.url, model.sizeBytes),
        onProgress: onProgress,
        expectedSize: model.sizeBytes,
        expectedSha256: model.sha256,
      );
      final projector = model.projector;
      if (projector == null) return installed;
      final (fileName, _) = await _store.importFile(
        originalName: projector.fileName,
        bytes: _resumableBytes(projector.url, projector.sizeBytes),
        onProgress: (written) => onProgress?.call(model.sizeBytes + written),
        expectedSize: projector.sizeBytes,
        expectedSha256: projector.sha256,
      );
      await _store.setProjector(installed.id, fileName);
      return installed.copyWith(projectorFileName: Value(fileName));
    } on ModelImportException {
      if (_cancelled) throw const DownloadCancelled();
      rethrow;
    } on Object catch (e) {
      if (_cancelled) throw const DownloadCancelled();
      throw ModelImportException(_networkMessage(e));
    } finally {
      _client.close(force: true);
    }
  }

  /// Aborts the connection; [run] then cleans up and throws
  /// [DownloadCancelled].
  void cancel() {
    _cancelled = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
    _client.close(force: true);
  }

  Stream<List<int>> _resumableBytes(Uri url, int sizeBytes) async* {
    var received = 0;
    var failures = 0;
    while (true) {
      try {
        final response = await _open(url, from: received);
        await for (final chunk in response.timeout(_stallTimeout)) {
          received += chunk.length;
          failures = 0;
          yield chunk;
        }
        if (received >= sizeBytes) return;
        // The server ended the body early without an error.
        throw const HttpException('Connection closed before the file ended');
      } on ModelImportException {
        rethrow;
      } on Object catch (e) {
        // Only reconnect once the download has started; if the first
        // connection fails there is likely no internet, so report it now.
        if (_cancelled ||
            received == 0 ||
            !_isTransient(e) ||
            ++failures > maxRetries) {
          rethrow;
        }
        await Future.any([
          Future<void>.delayed(_retryDelay(failures)),
          _cancelSignal.future,
        ]);
        if (_cancelled) rethrow;
      }
    }
  }

  /// GET [url] starting at byte [from]. Redirects are followed by hand so
  /// the Range header is sent to the final (CDN) host too.
  Future<HttpClientResponse> _open(Uri url, {required int from}) async {
    var uri = url;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final request = await _client.getUrl(uri)
        ..followRedirects = false;
      if (from > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$from-');
      }
      final response = await request.close();

      if (response.isRedirect) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (location == null) break;
        uri = uri.resolve(location);
        continue;
      }

      final expected = from > 0 ? HttpStatus.partialContent : HttpStatus.ok;
      if (response.statusCode != expected) {
        await response.drain<void>().catchError((_) {});
        throw ModelImportException(
          from > 0 && response.statusCode == HttpStatus.ok
              ? 'The download server can\'t resume this file. Please try '
                    'again.'
              : 'The download server returned an error '
                    '(HTTP ${response.statusCode}). Try again later.',
        );
      }
      return response;
    }
    throw const ModelImportException(
      'The download server redirected too many times. Try again later.',
    );
  }

  static bool _isTransient(Object e) =>
      e is SocketException ||
      e is HttpException ||
      e is HandshakeException ||
      e is TimeoutException;

  static String _networkMessage(Object e) => switch (e) {
    SocketException() || HandshakeException() =>
      'Couldn\'t reach the download server. Check your internet '
          'connection and try again.',
    TimeoutException() =>
      'The download stalled. Check your connection and try again.',
    HttpException() =>
      'The connection kept dropping, so the download stopped. Check your '
          'connection and try again.',
    _ => 'Download failed: $e',
  };
}
