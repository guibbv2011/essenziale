import 'dart:io';
import 'dart:typed_data';
import 'package:googleapis/siteverification/v1.dart';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class GcsStorageService {
  final gcs.StorageApi _storage;
  final String _bucket;

  GcsStorageService(this._storage, this._bucket);

  Future<void> createFolder(String folderPath, bool recursive) async {
    String path = _normalizePath(folderPath);

    final bool fe = await folderExists(folderPath);

    if (!fe) {
      final folder = gcs.Folder()..name = path.endsWith('/') ? path : '$path/';
      try {
        await _storage.folders.insert(folder, _bucket, recursive: recursive);
        print('Folder created: $path');
      } catch (e) {
        print(e);
      }
    }
  }

    try {
      await _storage.folders.insert(folder, _bucket, recursive: recursive);
    } catch (e) {
      if (e ==
          DetailedApiRequestError(
            409,
            'The folder you tried to create already exists.',
          )) {
        hasAdm = true;
  Future<List<String>> listFiles(String folderPath) async {
    final path = _normalizePath(folderPath);
    final prefix = path.isEmpty ? '' : (path.endsWith('/') ? path : '$path/');

    try {
      final listing = await _storage.objects.list(
        _bucket,
        prefix: prefix,
        delimiter: '/',
      );

      final items = <String>[];

      if (listing.items != null) {
        for (var item in listing.items!) {
          final itemName = item.name!;
          if (itemName.startsWith(prefix)) {
            final relativeName = itemName.substring(prefix.length);
            if (relativeName.isNotEmpty && !relativeName.contains('/')) {
              items.add(relativeName);
            }
          }
        }
      }

      print('Listed files in: $prefix (${items.length} files)');
      print('Files found: $items');
      return items;
    } catch (e, stackTrace) {
      print('Error listing folder: $e');
      print('Stack trace: $stackTrace');
      print('Attempted path: $prefix');
      rethrow;
    }
  }

  Future<List<String>> listFolder(String folderPath) async {
    final path = _normalizePath(folderPath);
    final prefix = path.isEmpty ? '' : (path.endsWith('/') ? path : '$path/');

    try {
      final listing = await _storage.objects.list(
        _bucket,
        prefix: prefix,
        delimiter: '/',
        includeFoldersAsPrefixes: true,
      );

      final items = <String>[];

      if (listing.prefixes != null) {
        for (var subPrefix in listing.prefixes!) {
          final folderName = subPrefix.substring(prefix.length);
          if (folderName.isNotEmpty) {
            final cleanName = folderName.endsWith('/')
                ? folderName.substring(0, folderName.length - 1)
                : folderName;
            if (cleanName.isNotEmpty) {
              items.add(cleanName);
            }
          }
        }
      }

      return items;
    } catch (e, stackTrace) {
      print('Error listing folder: $e');
      print('Stack trace: $stackTrace');
      print('Attempted path: $prefix');
      rethrow;
    }
  }

  Future<void> uploadDirectory(
    String localDirPath,
    String remoteBasePath,
  ) async {
    final localDir = Directory(localDirPath);
    if (!await localDir.exists()) {
      throw FileSystemException(
        'Local directory does not exist: $localDirPath',
      );
    }

    final basePrefix = p.normalize(
      remoteBasePath.endsWith('/') ? remoteBasePath : '$remoteBasePath/',
    );

    await _uploadRecursive(localDir, basePrefix);
  }

  Future<void> _uploadRecursive(Directory dir, String remotePrefix) async {
    if (!hasAdm) {
      await createFolder(remotePrefix, recursive: true);
    }

    await for (final entity in dir.list(followLinks: false)) {
      print('entity: $entity');
      final relativePath = p.relative(entity.path, from: dir.path);
      final remotePath = p.join(remotePrefix, relativePath);

      if (entity is Directory) {
        await _uploadRecursive(entity, remotePath);
      } else if (entity is File) {
        print('file: $entity');
        final objectName = remotePath;
        final contentType = _guessContentType(p.extension(objectName));
        final content = await entity.readAsBytes();

        final object = gcs.Object()
          ..name = objectName
          ..contentType = contentType;

        await _storage.objects.insert(
          object,
          _bucket,
          uploadMedia: gcs.Media(
            http.ByteStream.fromBytes(content),
            content.length,
          ),
        );
      }
    }
  }

  String _guessContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.txt':
        return 'text/plain';
      case '.html':
      case '.htm':
        return 'text/html';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<Uint8List> readFile(String filePath) async {
    String? path;
    if (filePath.startsWith('/tmp/')) {
      path = p.normalize(filePath.substring(5));
    }

    path!.replaceAll(RegExp(r'/$'), '');
    final media =
        await _storage.objects.get(
              _bucket,
              path,
              downloadOptions: gcs.DownloadOptions.fullMedia,
            )
            as gcs.Media;
    final data = <int>[];
    await for (final chunk in media.stream) {
      data.addAll(chunk);
    }
    return Uint8List.fromList(data);
  }

  Future<List<String>> listFolder(String folderPath) async {
    String? path;
    if (folderPath.startsWith('/tmp/')) {
      path = p.normalize(folderPath.substring(5));
    }
    final listing = await _storage.objects.list(
      _bucket,
      prefix: path,
      delimiter: '/',
      includeFoldersAsPrefixes: true,
    );
    final items = <String>[];
    for (var item in listing.items ?? []) {
      items.add(p.basename(item.name!));
    }
    for (var subPrefix in listing.prefixes ?? []) {
      items.add(p.basename(subPrefix.substring(0, subPrefix.length - 1)));
    }
    return items;
  }

  Future<void> deleteFile(String filePath) async {
    String? path;
    if (filePath.startsWith('/tmp/')) {
      path = p.normalize(filePath.substring(5));
    }

    path!.replaceAll(RegExp(r'/$'), '');
    await _storage.objects.delete(_bucket, path);
  }

  Future<void> deleteFolder(String folderPath) async {
    String? path;
    if (folderPath.startsWith('/tmp/')) {
      path = p.normalize(folderPath.substring(5));
  /// Checks if a folder exists
  Future<bool> folderExists(String folderPath) async {
    try {
      final _ = await listFolder(folderPath);
      return true;
    } catch (e) {
      return false;
    }

    await _deleteRecursive(path!);
    await _storage.folders.delete(_bucket, path);
  }

  Future<void> _deleteRecursive(String prefix) async {
    String? nextPageToken;
    do {
      final listing = await _storage.objects.list(
        _bucket,
        prefix: prefix,
        delimiter: '/',
        includeFoldersAsPrefixes: true,
        pageToken: nextPageToken,
      );

      for (var item in listing.items ?? []) {
        await _storage.objects.delete(_bucket, item.name!);
      }

      for (var subPrefix in listing.prefixes ?? []) {
        await _deleteRecursive(subPrefix!);
      }

      nextPageToken = listing.nextPageToken;
    } while (nextPageToken != null);
  }
}
