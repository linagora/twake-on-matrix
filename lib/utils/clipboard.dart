import 'dart:async';
import 'dart:io';

import 'package:fluffychat/presentation/model/clipboard/clipboard_image_info.dart';
import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';
import 'package:super_clipboard/super_clipboard.dart';

class Clipboard {
  static final _clipboard = Clipboard._();

  Clipboard._();

  ClipboardReader? _reader;

  static Clipboard get instance => _clipboard;

  static const allImageFormatsSupported = [
    Formats.png,
    Formats.jpeg,
    Formats.heic,
    Formats.heif,
    Formats.svg,
  ];

  Future<void> copyText(String text) async {
    final item = DataWriterItem();
    item.add(Formats.plainText(text));
    await ClipboardWriter.instance.write([item]);
  }

  Future<void> copyImageAsStream(File image, {String? mimeType}) async {
    final item = DataWriterItem(suggestedName: image.path);
    final imageStream = image.openRead();
    final mime = mimeType ?? lookupMimeType(image.path);
    await imageStream.forEach((data) {
      item.add(getFormatFrom(mime)(Uint8List.fromList(data)));
    });
    await ClipboardWriter.instance.write([item]);
  }

  Future<void> copyImageAsBytes(Uint8List data, {String? mimeType}) async {
    final item = DataWriterItem();
    item.add(getFormatFrom(mimeType)(data));
    await ClipboardWriter.instance.write([item]);
  }

  Future<void> initReader() async {
    _reader = await ClipboardReader.readClipboard();
  }

  Future<ClipboardImageInfo?> pasteImageUsingStream() async {
    _reader = await ClipboardReader.readClipboard();
    ClipboardImageInfo? imageInfo;

    final readableFormats = _reader!.getFormats(allImageFormatsSupported);
    if (readableFormats.isEmpty != false &&
        readableFormats.first is! SimpleFileFormat) {
      return imageInfo;
    }

    final c = Completer<ClipboardImageInfo?>();
    final progress = _reader!.getFile(
      readableFormats.first as SimpleFileFormat,
      (file) async {
        try {
          imageInfo = ClipboardImageInfo(
            stream: file.getStream(),
            fileName: file.fileName,
            fileSize: file.fileSize,
          );
          c.complete(imageInfo);
        } catch (e) {
          Logs().e('Clipboard::pasteImageUsingBytes(): $e');
          c.completeError(e);
        }
      },
      onError: (e) {
        Logs().e('Clipboard::pasteImageUsingBytes(): $e');
        c.completeError(e);
      },
    );
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }

  Future<Uint8List?>? pasteImageUsingBytes() async {
    _reader = await ClipboardReader.readClipboard();
    final readableFormats = _reader!.getFormats(allImageFormatsSupported);
    if (readableFormats.isEmpty != false &&
        readableFormats.first is! SimpleFileFormat) {
      return null;
    }

    final c = Completer<Uint8List?>();
    final progress = _reader!.getFile(
      readableFormats.first as SimpleFileFormat,
      (file) async {
        try {
          final all = await file.readAll();
          c.complete(all);
        } catch (e) {
          Logs().e('Clipboard::pasteImageUsingBytes(): $e');
          c.completeError(e);
        }
      },
      onError: (e) {
        Logs().e('Clipboard::pasteImageUsingBytes(): $e');
        c.completeError(e);
      },
    );
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
  }

  Future<bool> isReadableImageFormat() async {
    _reader = await ClipboardReader.readClipboard();
    return _reader!.canProvide(Formats.png) ||
        _reader!.canProvide(Formats.jpeg) ||
        _reader!.canProvide(Formats.heic) ||
        _reader!.canProvide(Formats.heif) ||
        _reader!.canProvide(Formats.svg);
  }

  Future<String?> pasteText() async {
    _reader = await ClipboardReader.readClipboard();
    String? copied;

    final readersFormat = _reader!.getFormats(Formats.standardFormats);
    if (readersFormat.isEmpty) {
      return copied;
    }

    final c = Completer<String?>();
    final progress = _reader!.getValue<String>(
      Formats.plainText,
      (value) {
        copied = value;
        c.complete(copied);
      },
      onError: (error) {
        Logs().e('Clipboard::readText(): $error');
        c.completeError(error);
      },
    );
    if (progress == null) {
      c.completeError('Clipboard::readText(): error');
    }
    return c.future;
  }

  SimpleFileFormat getFormatFrom(String? mimeType) {
    switch (mimeType) {
      case 'image/png':
        return Formats.png;
      case 'image/jpeg':
        return Formats.jpeg;
      case 'image/heic':
        return Formats.heic;
      case 'image/heif':
        return Formats.heif;
      default:
        return Formats.plainTextFile;
    }
  }
}
