import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path/path.dart' as path;

import '../models/sync_models.dart';

/// Kapselt alle HTTP-Aufrufe an die ASP.NET Sync-API.
class SyncApiService {
  SyncApiService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// Liefert die normalisierte Basis-URL für Log-Ausgaben.
  String describeBaseUrl(String apiBaseUrl) => _normalizeBaseUrl(apiBaseUrl);

  /// Sendet das lokale Manifest an die API.
  Future<List<SyncManifestResponse>> sendManifest({
    required String apiBaseUrl,
    required List<SyncFileDescriptor> manifest,
    bool allowInsecureTlsForLocalhost = false,
  }) async {
    final response = await _executeRequest(
      apiBaseUrl,
      allowInsecureTlsForLocalhost,
      (client) => client.post(
        _buildUri(apiBaseUrl, 'manifest'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(manifest.map((entry) => entry.toJson()).toList()),
      ),
    );

    _ensureSuccess(response, 'Manifest');

    final payload = jsonDecode(response.body);

    if (payload is! List) {
      throw Exception('Die Manifest-Antwort hat ein unerwartetes Format.');
    }

    return payload
        .whereType<Map<String, dynamic>>()
        .map(SyncManifestResponse.fromJson)
        .toList();
  }

  /// Lädt eine einzelne Datei auf den Server hoch.
  Future<void> uploadFile({
    required String apiBaseUrl,
    required String syncRootPath,
    required SyncFileDescriptor file,
    bool allowInsecureTlsForLocalhost = false,
  }) async {
    final absolutePath = path.join(syncRootPath, file.relativePath);
    final localFile = File(absolutePath);

    if (!await localFile.exists()) {
      throw Exception('Die Upload-Datei wurde lokal nicht gefunden.');
    }

    final basePath = path.posix.dirname(file.relativePath.replaceAll('\\', '/'));
    final uploadUri = _buildUri(
      apiBaseUrl,
      'upload',
      queryParameters: basePath == '.'
          ? null
          : <String, String>{'basePath': basePath},
    );

    final request = http.MultipartRequest('POST', uploadUri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          absolutePath,
          filename: file.fileName,
        ),
      );

    final response = await _executeRequest(
      apiBaseUrl,
      allowInsecureTlsForLocalhost,
      (client) async {
        final streamedResponse = await client.send(request);
        return http.Response.fromStream(streamedResponse);
      },
    );

    _ensureSuccess(response, 'Upload');
  }

  /// Lädt eine Datei vom Server herunter und speichert sie lokal.
  Future<void> downloadFile({
    required String apiBaseUrl,
    required String syncRootPath,
    required SyncManifestResponse file,
    bool allowInsecureTlsForLocalhost = false,
  }) async {
    final response = await _executeRequest(
      apiBaseUrl,
      allowInsecureTlsForLocalhost,
      (client) => client.get(
        _buildUri(
          apiBaseUrl,
          'download',
          queryParameters: {'filePath': file.relativePath},
        ),
      ),
    );

    _ensureSuccess(response, 'Download');

    final absolutePath = path.join(syncRootPath, file.relativePath);
    final localFile = File(absolutePath);

    try {
      await localFile.parent.create(recursive: true);
      await localFile.writeAsBytes(response.bodyBytes, flush: true);
      await localFile.setLastModified(file.lastModified.toLocal());
    } on FileSystemException catch (error) {
      throw Exception(
        _buildLocalWriteErrorMessage(
          syncRootPath: syncRootPath,
          absolutePath: absolutePath,
          details: error.message,
        ),
      );
    }
  }

  /// Meldet eine lokale Löschung an den Server.
  Future<void> deleteRemoteFile({
    required String apiBaseUrl,
    required String relativePath,
    bool allowInsecureTlsForLocalhost = false,
  }) async {
    final response = await _executeRequest(
      apiBaseUrl,
      allowInsecureTlsForLocalhost,
      (client) => client.delete(
        _buildUri(
          apiBaseUrl,
          'delete',
          queryParameters: {'filePath': relativePath},
        ),
      ),
    );

    _ensureSuccess(response, 'Delete');
  }

  /// Führt einen HTTP-Aufruf mit optionaler TLS-Ausnahme fuer lokale Ziele aus.
  Future<T> _executeRequest<T>(
    String apiBaseUrl,
    bool allowInsecureTlsForLocalhost,
    Future<T> Function(http.Client client) action,
  ) async {
    final targetUri = Uri.parse(_normalizeBaseUrl(apiBaseUrl));
    final client = _createClientForUri(
      targetUri,
      allowInsecureTlsForLocalhost: allowInsecureTlsForLocalhost,
    );

    try {
      return await action(client);
    } on HandshakeException catch (error) {
      throw Exception(_buildCertificateErrorMessage(targetUri, error.toString()));
    } on http.ClientException catch (error) {
      if (_looksLikeCertificateError(error.message)) {
        throw Exception(_buildCertificateErrorMessage(targetUri, error.message));
      }

      rethrow;
    } finally {
      if (!identical(client, _httpClient)) {
        client.close();
      }
    }
  }

  /// Baut die URI für einen API-Endpunkt.
  Uri _buildUri(
    String apiBaseUrl,
    String endpoint, {
    Map<String, String>? queryParameters,
  }) {
    final normalizedBaseUrl = _normalizeBaseUrl(apiBaseUrl);
    final baseUri = Uri.parse(normalizedBaseUrl);
    final normalizedEndpoint = endpoint.replaceFirst(RegExp(r'^/+'), '');
    final combinedPath = [
      ...baseUri.path.split('/').where((part) => part.isNotEmpty),
      normalizedEndpoint,
    ].join('/');

    return baseUri.replace(
      path: '/$combinedPath',
      queryParameters: queryParameters?.isEmpty ?? true ? null : queryParameters,
    );
  }

  /// Ergänzt fehlende API-Segmente an der Basis-URL.
  String _normalizeBaseUrl(String apiBaseUrl) {
    final trimmed = apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');

    if (trimmed.endsWith('/api/sync')) {
      return trimmed;
    }

    if (trimmed.endsWith('/api')) {
      return '$trimmed/sync';
    }

    return '$trimmed/api/sync';
  }

  /// Erstellt bei Bedarf einen Client mit lokaler Zertifikatsausnahme.
  http.Client _createClientForUri(
    Uri uri, {
    required bool allowInsecureTlsForLocalhost,
  }) {
    if (!allowInsecureTlsForLocalhost || !_isSupportedInsecureHttpsUri(uri)) {
      return _httpClient;
    }

    final httpClient = HttpClient()
      ..badCertificateCallback = (certificate, host, port) {
        return _isSupportedInsecureHost(host);
      };

    return IOClient(httpClient);
  }

  /// Erlaubt die TLS-Ausnahme nur fuer lokale HTTPS-Adressen.
  bool _isSupportedInsecureHttpsUri(Uri uri) {
    return uri.scheme == 'https' && _isSupportedInsecureHost(uri.host);
  }

  /// Begrenzt Zertifikatsausnahmen auf Loopback- und private LAN-Adressen.
  bool _isSupportedInsecureHost(String host) {
    final normalizedHost = host.trim().toLowerCase();
    if (normalizedHost == 'localhost') {
      return true;
    }

    final parsedAddress = InternetAddress.tryParse(normalizedHost);
    if (parsedAddress == null) {
      return false;
    }

    if (parsedAddress.isLoopback) {
      return true;
    }

    if (parsedAddress.type == InternetAddressType.IPv4) {
      return _isPrivateIpv4Address(parsedAddress.address);
    }

    return _isPrivateIpv6Address(parsedAddress.address);
  }

  /// Erkennt RFC1918- und Link-Local-Adressen im lokalen Netz.
  bool _isPrivateIpv4Address(String address) {
    final octets = address.split('.').map(int.tryParse).toList();
    if (octets.length != 4 || octets.any((octet) => octet == null)) {
      return false;
    }

    final first = octets[0]!;
    final second = octets[1]!;

    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168) ||
        (first == 169 && second == 254);
  }

  /// Erkennt lokale IPv6-Bereiche fuer Entwicklung im Heim- oder Firmennetz.
  bool _isPrivateIpv6Address(String address) {
    final normalizedAddress = address.toLowerCase();

    return normalizedAddress.startsWith('fc') ||
        normalizedAddress.startsWith('fd') ||
        normalizedAddress.startsWith('fe80:');
  }

  /// Erkennt typische TLS-Fehler von lokalen Entwicklungszertifikaten.
  bool _looksLikeCertificateError(String message) {
    final normalizedMessage = message.toLowerCase();

    return normalizedMessage.contains('handshake exception') ||
        normalizedMessage.contains('certificate verify failed') ||
        normalizedMessage.contains('local issuer certificate');
  }

  /// Baut eine handlungsorientierte Meldung fuer Zertifikatsprobleme.
  String _buildCertificateErrorMessage(Uri uri, String details) {
    if (_isSupportedInsecureHttpsUri(uri)) {
      return 'Das HTTPS-Zertifikat fuer ${uri.host} wird auf diesem Geraet '
          'nicht vertraut. Bei lokalen Entwicklungs- oder LAN-Adressen kannst '
          'du in den Einstellungen die Zertifikatsausnahme aktivieren oder '
          'eine vertrauenswuerdige CA verwenden. Details: $details';
    }

    return 'TLS-Verbindung zur API fehlgeschlagen. Details: $details';
  }

  /// Baut eine verständliche Fehlermeldung fuer lokale Schreibprobleme.
  String _buildLocalWriteErrorMessage({
    required String syncRootPath,
    required String absolutePath,
    required String details,
  }) {
    if (Platform.isAndroid) {
      return 'Android darf nicht in jeden Ordner unter /storage/emulated/0 '
          'schreiben. Richte das Sync-Verzeichnis in den Einstellungen neu ein, '
          'damit die App ihren beschreibbaren App-Ordner nutzt. '
          'Ziel: $absolutePath | Aktuelles Sync-Verzeichnis: $syncRootPath | '
          'Details: $details';
    }

    return 'Datei konnte lokal nicht gespeichert werden. '
        'Ziel: $absolutePath | Details: $details';
  }

  /// Prüft den HTTP-Status und erzeugt bei Bedarf eine verständliche Fehlermeldung.
  void _ensureSuccess(http.Response response, String operationLabel) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (_looksLikeWrongWebServerResponse(response)) {
      throw Exception(
        '$operationLabel fehlgeschlagen (${response.statusCode}): '
        'Die konfigurierte URL zeigt nicht auf die Sync-API, sondern auf '
        'einen anderen Webserver oder den falschen Port. Pruefe Host, Port '
        'und Reverse-Proxy-Konfiguration.',
      );
    }

    final responseBody = response.body.trim();
    final details = responseBody.isEmpty ? 'Keine weiteren Details.' : responseBody;

    throw Exception(
      '$operationLabel fehlgeschlagen (${response.statusCode}): $details',
    );
  }

  /// Erkennt typische HTML-Fehlerseiten fremder Webserver statt einer API-Antwort.
  bool _looksLikeWrongWebServerResponse(http.Response response) {
    final contentType =
        response.headers[HttpHeaders.contentTypeHeader]?.toLowerCase() ?? '';
    final responseBody = response.body.toLowerCase();

    return contentType.contains('text/html') ||
        responseBody.contains('<!doctype html') ||
        responseBody.contains('<html') ||
        responseBody.contains('apache/');
  }
}
