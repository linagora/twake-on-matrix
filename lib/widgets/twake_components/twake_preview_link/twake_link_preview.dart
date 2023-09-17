import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/domain/usecase/preview_url/get_preview_url_interactor.dart';
import 'package:fluffychat/presentation/extensions/media/url_preview_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_link_text/link_text.dart';

class TwakeLinkPreview extends StatefulWidget {
  final Uri uri;
  final int? preferredPointInTime;
  final String text;
  final Widget childWidget;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final LinkTapHandler? onLinkTap;
  final int? maxLines;
  final double? fontSize;
  final bool ownMessage;
  final TextSpanBuilder? textSpanBuilder;

  const TwakeLinkPreview({
    super.key,
    required this.uri,
    this.preferredPointInTime,
    required this.text,
    required this.childWidget,
    required this.ownMessage,
    this.textStyle,
    this.linkStyle,
    this.textAlign,
    this.onLinkTap,
    this.maxLines,
    this.fontSize,
    this.textSpanBuilder,
  });

  @override
  State<TwakeLinkPreview> createState() => TwakeLinkPreviewController();
}

class TwakeLinkPreviewController extends State<TwakeLinkPreview> {
  static const int _defaultPreferredPointInTime = 2000;

  final GetPreviewURLInteractor _getPreviewURLInteractor =
      getIt.get<GetPreviewURLInteractor>();

  final getPreviewUrlStateNotifier =
      ValueNotifier<Either<Failure, Success>>(Right(GetPreviewUrlInitial()));

  String? get firstValidUrl => widget.text.getFirstValidUrl();

  @override
  void initState() {
    if (firstValidUrl != null) {
      _getPreviewUrlAction();
    }

    super.initState();
  }

  void _getPreviewUrlAction() {
    _getPreviewURLInteractor
        .execute(
          uri: widget.uri,
          preferredPreviewTime:
              widget.preferredPointInTime ?? _defaultPreferredPointInTime,
        )
        .listen(
          (event) => _handleGetPreviewUrlOnData(event),
          onError: _handleGetPreviewUrlOnError,
          onDone: _handleGetPreviewUrlOnDone,
        );
  }

  void _handleGetPreviewUrlOnData(Either<Failure, Success> event) {
    Logs().d('TwakeLinkPreviewController::_handleGetPreviewUrlOnData()');
    getPreviewUrlStateNotifier.value = event;
  }

  void _handleGetPreviewUrlOnDone() {
    Logs().d(
      'TwakeLinkPreviewController::_handleGetPreviewUrlOnDone() - done',
    );
  }

  void _handleGetPreviewUrlOnError(
    dynamic error,
    StackTrace? stackTrace,
  ) {
    Logs().e(
      'TwakeLinkPreviewController::_handleGetPreviewUrlOnError() - error: $error | stackTrace: $stackTrace',
    );
  }

  @override
  Widget build(BuildContext context) {
    return TwakeLinkView(
      text: widget.text,
      textStyle: widget.textStyle,
      linkStyle: widget.linkStyle,
      childWidget: widget.childWidget,
      firstValidUrl: firstValidUrl,
      onLinkTap: (url) => UrlLauncher(context, url.toString()).launchUrl(),
      textSpanBuilder: widget.textSpanBuilder,
      previewItemWidget: ValueListenableBuilder(
        valueListenable: getPreviewUrlStateNotifier,
        builder: (context, state, _) {
          return state.fold(
            (failure) => const SizedBox.shrink(),
            (success) {
              if (success is GetPreviewUrlSuccess) {
                final previewLink = success.urlPreview.toPresentation();
                return TwakeLinkPreviewItem(
                  ownMessage: widget.ownMessage,
                  urlPreviewPresentation: previewLink,
                  textStyle: widget.textStyle,
                );
              }
              return const SizedBox();
            },
          );
        },
      ),
    );
  }
}
