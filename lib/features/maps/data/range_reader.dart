import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'map_store.dart';

/// Byte-range access to a (usually remote) archive.
abstract class RangeReader {
  Future<Uint8List> read(int offset, int length);
  Stream<List<int>> stream(int offset, int length);
  void close() {}
}

/// Thrown when the user cancels a region download.
class RegionDownloadCancelled implements Exception {
  const RegionDownloadCancelled();
}

/// Byte ranges of one URL over HTTP, with the same reconnect-and-resume
/// behaviour as the model downloader: a dropped connection continues
/// from the last byte received, up to [maxRetries] times in a row. The
/// default waits about half an hour for the network to come back (the
/// phone sleeping is the usual cause) before giving up.
class HttpRangeReader implements RangeReader {
  HttpRangeReader(
    this.url, {
    this.maxRetries = 60,
    Duration Function(int attempt)? retryDelay,
  }) : _retryDelay = retryDelay ?? _defaultDelay;

  final Uri url;
  final int maxRetries;
  final Duration Function(int attempt) _retryDelay;

  final _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..userAgent = 'offgrid-ai';
  bool _cancelled = false;
  bool _connected = false;
  final _cancelSignal = Completer<void>();

  static const _stallTimeout = Duration(seconds: 60);
  static const _maxRedirects = 5;

  static Duration _defaultDelay(int attempt) =>
      Duration(seconds: [2, 4, 8, 15, 30, 30][(attempt - 1).clamp(0, 5)]);

  @override
  Future<Uint8List> read(int offset, int length) async {
    final b = BytesBuilder(copy: false);
    await for (final chunk in stream(offset, length)) {
      b.add(chunk);
    }
    return b.takeBytes();
  }

  @override
  Stream<List<int>> stream(int offset, int length) async* {
    if (length == 0) return;
    var received = 0;
    var failures = 0;
    while (true) {
      try {
        final response = await _open(offset + received, offset + length - 1);
        await for (final chunk in response.timeout(_stallTimeout)) {
          _connected = true;
          received += chunk.length;
          failures = 0;
          if (received > length) {
            throw const HttpException('The server sent more than was asked');
          }
          yield chunk;
        }
        if (received >= length) return;
        throw const HttpException('Connection closed before the range ended');
      } on MapImportException {
        rethrow;
      } on Object catch (e) {
        // If the very first connection fails there is likely no internet,
        // so report it now rather than retrying for minutes.
        if (_cancelled ||
            !_connected ||
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

  /// Aborts any request in flight; the stream then throws.
  void cancel() {
    _cancelled = true;
    if (!_cancelSignal.isCompleted) _cancelSignal.complete();
    _client.close(force: true);
  }

  @override
  void close() => _client.close(force: true);

  /// GET bytes [from]–[to] inclusive. Redirects are followed by hand so
  /// the Range header reaches the final host.
  Future<HttpClientResponse> _open(int from, int to) async {
    var uri = url;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final request = await _client.getUrl(uri)
        ..followRedirects = false;
      request.headers.set(HttpHeaders.rangeHeader, 'bytes=$from-$to');
      final response = await request.close();
      if (response.isRedirect) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (location == null) break;
        uri = uri.resolve(location);
        continue;
      }
      if (response.statusCode != HttpStatus.partialContent) {
        await response.drain<void>().catchError((_) {});
        throw MapImportException(
          response.statusCode == HttpStatus.ok
              ? 'The map server doesn\'t support partial downloads. Try '
                    'again later.'
              : 'The map server returned an error '
                    '(HTTP ${response.statusCode}). Try again later.',
        );
      }
      return response;
    }
    throw const MapImportException(
      'The map server redirected too many times. Try again later.',
    );
  }

  static bool _isTransient(Object e) =>
      e is SocketException ||
      e is HttpException ||
      e is HandshakeException ||
      e is TimeoutException;
}

/// Protomaps publishes one planet archive a day (with gaps) at
/// https://build.protomaps.com/YYYYMMDD.pmtiles. Finds the newest one of
/// the last week with HEAD requests.
Future<Uri> latestPlanetBuild({
  Uri? base,
  HttpClient? client,
  DateTime? today,
}) async {
  final c = client ?? (HttpClient()..userAgent = 'offgrid-ai');
  final root = base ?? Uri.parse('https://build.protomaps.com/');
  final now = (today ?? DateTime.now()).toUtc();
  try {
    for (var back = 0; back < 8; back++) {
      final d = now.subtract(Duration(days: back));
      final name =
          '${d.year}${d.month.toString().padLeft(2, '0')}'
          '${d.day.toString().padLeft(2, '0')}.pmtiles';
      final uri = root.resolve(name);
      final response = await (await c.headUrl(uri)).close();
      await response.drain<void>().catchError((_) {});
      if (response.statusCode == HttpStatus.ok) return uri;
    }
    throw const MapImportException(
      'Couldn\'t find this week\'s map build on the server. Try again later.',
    );
  } on MapImportException {
    rethrow;
  } on Object catch (e) {
    throw MapImportException(networkMessage(e));
  } finally {
    if (client == null) c.close(force: true);
  }
}

String networkMessage(Object e) => switch (e) {
  SocketException() || HandshakeException() =>
    'Couldn\'t reach the map server. Check your internet connection and '
        'try again.',
  TimeoutException() =>
    'The download stalled. Check your connection and try again.',
  HttpException() =>
    'The connection kept dropping, so the download stopped. Check your '
        'connection and try again.',
  _ => 'Download failed: $e',
};
