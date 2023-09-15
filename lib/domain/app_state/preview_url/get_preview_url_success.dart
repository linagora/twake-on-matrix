import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/media/url_preview.dart';

class GetPreviewUrlInitial extends Success {
  @override
  List<Object?> get props => [];
}

class GetPreviewUrlSuccess extends Success {
  final UrlPreview urlPreview;

  const GetPreviewUrlSuccess({
    required this.urlPreview,
  });

  @override
  List<Object> get props => [urlPreview];
}
