import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/platform_infos.dart';

enum SupportedIconFileTypesEnum {
  image,
  doc,
  excel,
  powerPoint,
  pdf,
  zip,
  video,
  audio,
  unknown;

  String get imagePath {
    switch (this) {
      case SupportedIconFileTypesEnum.image:
        return ImagePaths.icFileImage;
      case SupportedIconFileTypesEnum.doc:
        return ImagePaths.icFileDocx;
      case SupportedIconFileTypesEnum.excel:
        return ImagePaths.icFileXlsx;
      case SupportedIconFileTypesEnum.powerPoint:
        return ImagePaths.icFilePptx;
      case SupportedIconFileTypesEnum.pdf:
        return ImagePaths.icFilePdf;
      case SupportedIconFileTypesEnum.zip:
        return ImagePaths.icFileZip;
      case SupportedIconFileTypesEnum.video:
        return ImagePaths.icFileVideo;
      case SupportedIconFileTypesEnum.audio:
        return ImagePaths.icFileAudio;
      case SupportedIconFileTypesEnum.unknown:
      default:
        return ImagePaths.icFileUnknown;
    }
  }
}

class SupportedPreviewFileTypes {
  static const imageMimeTypes = [
    'image/bmp',
    'image/jpeg',
    'image/jpg',
    'image/gif',
    'image/png',
  ];

  static const imageMimeTypesAndroid = [
    ...imageMimeTypes,
    'image/webp',
  ];

  static const imageMimeTypesIOS = [
    ...imageMimeTypes,
    'image/heic',
    'image/heif',
  ];

  static List<String> get crossPlatformImageMimeTypes {
    if (PlatformInfos.isAndroid) {
      return imageMimeTypesAndroid;
    } else if (PlatformInfos.isIOS) {
      return imageMimeTypesIOS;
    } else {
      return imageMimeTypes;
    }
  }

  static const videoMimeTypes = [
    'video/mp4',
    'video/3gpp',
    'video/quicktime',
    'video/mov',
    'video/mpeg',
  ];

  static const audioMimeTypes = [
    'audio/mpeg',
    'audio/wav',
    'audio/x-ms-wmv',
  ];

  static const docMimeTypes = [
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.text-template',
    'application/vnd.oasis.opendocument.text-web',
    'application/vnd.oasis.opendocument.text-master',
    'application/msword',
    'application/vnd.ms-works',
    'docx',
  ];

  static const pdfMimeTypes = ['application/pdf', 'application/rtf'];

  static const apkMimeTypes = ['application/vnd.android.package-archive'];

  static const xlsMimeTypes = [
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/vnd.oasis.opendocument.spreadsheet-template',
    'application/vnd.oasis.opendocument.chart',
    'application/vnd.oasis.opendocument.formula',
    'application/vnd.ms-excel',
  ];

  static const pptMimeTypes = [
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.oasis.opendocument.presentation',
    'application/vnd.oasis.opendocument.presentation-template',
    'application/vnd.ms-powerpoint',
  ];

  static const zipMimeTypes = [
    'application/x-tar',
    'application/x-gtar',
    'application/x-gzip',
    'application/x-compressed',
    'application/x-zip-compressed',
    'application/java-archive',
    'application/zip',
  ];

  static const iOSSupportedTypes = {
    'text/plain': 'public.plain-text',
    'text/html': 'public.html',
    'video/x-msvideo': 'public.avi',
    'video/mpeg': 'public.mpeg',
    'video/mp4': 'public.mpeg-4',
    'video/3gpp': 'public.3gpp',
    'video/quicktime': 'public.mpeg-4',
    'audio/mpeg': 'public.mp3',
    'audio/wav': 'com.microsoft.waveform-​audio',
    'audio/x-ms-wmv': 'com.microsoft.windows-​media-wmv',
    'image/jpeg': 'public.jpeg',
    'image/png': 'public.png',
    'image/gif': 'com.compuserve.gif',
    'image/bmp': 'com.microsoft.bmp',
    'image/vnd.microsoft.icon': 'com.microsoft.ico',
    'application/zip': 'com.pkware.zip-archive',
    'application/rtf': 'public.rtf',
    'application/xml': 'public.xml',
    'application/x-tar': 'public.tar-archive',
    'application/gzip': 'org.gnu.gnu-zip-archive',
    'application/x-compressed': 'org.gnu.gnu-zip-tar-archive',
    'application/msword': 'com.microsoft.word.doc',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        'com.microsoft.word.doc',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        'com.microsoft.excel.xls',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        'com.microsoft.powerpoint.​ppt',
    'application/pdf': 'com.adobe.pdf',
  };

  static const androidSupportedTypes = [
    'image/bmp',
    'image/jpeg',
    'image/gif',
    'image/png',
    'text/plain',
    'text/html',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/msword',
    'application/vnd.ms-excel',
    'application/vnd.ms-powerpoint',
    'application/vnd.ms-outlook',
    'application/vnd.ms-works',
    'application/vnd.mpohun.certificate',
    'application/vnd.android.package-archive',
    'application/octet-stream',
    'application/x-tar',
    'application/x-gtar',
    'application/x-gzip',
    'application/x-javascript',
    'application/x-compressed',
    'application/x-zip-compressed',
    'application/java-archive',
    'application/pdf',
    'application/rtf',
    'audio/x-mpegurl',
    'video/x-m4v',
    'video/x-ms-asf',
    'video/x-msvideo',
    'audio/x-mpeg',
    'audio/mp4a-latm',
    'video/vnd.mpegurl',
    'video/quicktime',
    'video/mp4',
    'video/3gpp',
    'video/mpeg',
    'audio/mpeg',
    'audio/ogg',
    'audio/x-pn-realaudio',
    'audio/x-wav',
    'audio/x-ms-wma',
    'audio/x-ms-wmv',
  ];

  static const supportAnotherTypes = ['application/octet-stream'];

  static const docFileTypes = [
    'docx',
    'doc',
    'docx',
    'docm',
    'dot',
    'dotx',
    'dotm',
  ];

  static const pdfFileTypes = ['pdf'];

  static const xlsFileTypes = [
    'xls',
    'xlsx',
    'xslsm',
    'xlt',
    'xltx',
    'xltm',
  ];

  static const pptFileTypes = ['ppt', 'pptx', 'pps', 'ppsx', 'ppsm', 'pptm'];

  static const zipFileTypes = ['zip'];

  static const aviMineType = [
    'application/x-troff-msvideo',
    'video/avi',
    'video/msvideo',
    'video/x-msvideo',
  ];

  static const wmvMineType = [
    'video/x-ms-wmv',
    'video/x-ms-asf',
  ];
}
