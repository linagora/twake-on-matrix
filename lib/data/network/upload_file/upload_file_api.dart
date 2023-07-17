import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' hide Client;
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

extension UploadFileAPI on MatrixApi {
  static const multiPartFileType = 'multipart/form-data';
  static const uploadContentEndpoint = '_matrix/media/v3/upload';

  Future<Uri> uploadContentByMultipartType({
    required File file,
    String? filename,
    String contentType = multiPartFileType,
  }) async {
    final requestUri = Uri(path: uploadContentEndpoint, queryParameters: {
      if (filename != null) 'filename': filename,
    });

    final request = MultipartRequest('POST', baseUri!.resolveUri(requestUri));
    request.headers[HttpHeaders.authorizationHeader] = 'Bearer ${bearerToken!}';
    request.headers[HttpHeaders.contentTypeHeader] = contentType;
    final multipartFile = await MultipartFile.fromPath(
      'file', 
      file.path,
      filename: filename,
    );
    request.files.add(multipartFile);

    final response = await httpClient.send(request);

    final responseBody = await response.stream.toBytes();
    if (response.statusCode != 200) unexpectedResponse(response, responseBody);
    final responseString = utf8.decode(responseBody);
    final json = jsonDecode(responseString);
    return Uri.parse(json['content_uri']);
  }
}

extension UploadFileAsMultipart on Client {
  
  Future<Uri> uploadContentAsMultipart(File file,
      {String? filename, String? contentType}) async {
    final mediaConfig = await getConfig();
    final maxMediaSize = mediaConfig.mUploadSize;
    final fileLength = await file.length();
    if (maxMediaSize != null && maxMediaSize < fileLength) {
      throw FileTooBigMatrixException(fileLength, maxMediaSize);
    }

    contentType ??= lookupMimeType(filename ?? '');
    final mxc = await uploadContentByMultipartType(
      file: file,
      filename: filename,      
    );
    return mxc;
  }
}