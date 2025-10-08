import 'dart:io';
import 'dart:typed_data';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class GcsStorageService {
  final gcs.StorageApi _storage;
  final String _bucket;

  GcsStorageService(this._storage, this._bucket);

  // Helper: Normalize path to GCS prefix (strip /tmp/ and ensure trailing / for folders)
  String _toPrefix(String path) {
    if (!path.startsWith('/tmp/')) {
      throw ArgumentError('Path must start with /tmp/');
    }
    String prefix = p.normalize(path.substring(5)); // Strip /tmp/, normalize
    return prefix.endsWith('/') ? prefix : '$prefix/';
  }

  // CREATE: Folder using native HNS folders.insert (with recursive for parents)
  Future<void> createFolder(String folderPath, {bool recursive = true}) async {
    final prefix = _toPrefix(folderPath); // e.g., 'user1/1/'
    final folder = gcs.Folder()..name = prefix;
    await _storage.folders.insert(folder, _bucket, recursive: recursive);
  }

  // UPLOAD: Entire directory recursively (creates folders explicitly, uploads files)
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

    // Start recursive upload from base
    await _uploadRecursive(localDir, basePrefix);
  }

  Future<void> _uploadRecursive(Directory dir, String remotePrefix) async {
    // Create the current folder (recursive=true handles parents)
    await createFolder(
      '/tmp/$remotePrefix',
      recursive: true,
    ); // Prefix with /tmp/ for helper consistency

    // List non-recursively to handle subdirs properly
    await for (final entity in dir.list(followLinks: false)) {
      final relativePath = p.relative(entity.path, from: dir.path);
      final remotePath = p.join(remotePrefix, relativePath);

      if (entity is Directory) {
        // Recurse into subdir
        await _uploadRecursive(entity, remotePath);
      } else if (entity is File) {
        // Upload file
        final objectName = remotePath; // No trailing / for files
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

  // Simple MIME guesser (extend with 'mime' package if needed)
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

  // READ: File (download content as bytes)
  Future<Uint8List> readFile(String filePath) async {
    final objectName = _toPrefix(
      filePath,
    ).replaceAll(RegExp(r'/$'), ''); // Strip trailing /
    final media =
        await _storage.objects.get(
              _bucket,
              objectName,
              downloadOptions: gcs.DownloadOptions.fullMedia,
            )
            as gcs.Media;
    final data = <int>[];
    await for (final chunk in media.stream) {
      data.addAll(chunk);
    }
    return Uint8List.fromList(data);
  }

  // READ: List files/folders in path (optimized for HNS with includeFoldersAsPrefixes)
  Future<List<String>> listFolder(String folderPath) async {
    final prefix = _toPrefix(folderPath);
    final listing = await _storage.objects.list(
      _bucket,
      prefix: prefix,
      delimiter: '/',
      includeFoldersAsPrefixes: true, // Optimize for HNS
    );
    final items = <String>[];
    for (var item in listing.items ?? []) {
      items.add(p.basename(item.name!)); // File names
    }
    for (var subPrefix in listing.prefixes ?? []) {
      items.add(
        p.basename(subPrefix.substring(0, subPrefix.length - 1)),
      ); // Subfolder names (strip trailing /)
    }
    return items;
  }

  // DELETE: File
  Future<void> deleteFile(String filePath) async {
    final objectName = _toPrefix(
      filePath,
    ).replaceAll(RegExp(r'/$'), ''); // Strip trailing /
    await _storage.objects.delete(_bucket, objectName);
  }

  // DELETE: Folder (recursive: delete contents then folder)
  Future<void> deleteFolder(String folderPath) async {
    final prefix = _toPrefix(folderPath);

    // Recursively delete subfolders and objects
    await _deleteRecursive(prefix);

    // Finally, delete the folder itself (must be empty)
    await _storage.folders.delete(_bucket, prefix);
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

      // Delete objects
      for (var item in listing.items ?? []) {
        await _storage.objects.delete(_bucket, item.name!);
      }

      // Recurse into subfolders
      for (var subPrefix in listing.prefixes ?? []) {
        await _deleteRecursive(subPrefix!);
      }

      nextPageToken = listing.nextPageToken;
    } while (nextPageToken != null);
  }
}  // DELETE: File

