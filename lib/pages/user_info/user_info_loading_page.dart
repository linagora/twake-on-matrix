import 'dart:async';

import 'package:dartz/dartz.dart' as dartz;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:fluffychat/data/network/tom_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class UserInfoLoadingPage extends StatefulWidget {
  const UserInfoLoadingPage({super.key, required this.userId});

  final String? userId;

  @override
  State<UserInfoLoadingPage> createState() => _UserInfoLoadingPageState();
}

class _UserInfoLoadingPageState extends State<UserInfoLoadingPage> {
  StreamSubscription<dartz.Either<Failure, Success>>? subscription;
  @override
  void initState() {
    super.initState();
    subscription =
        getIt.get<GetUserInfoInteractor>().execute(widget.userId).listen(
      (state) => state.fold(
        (failure) async {
          if (failure is GetUserInfoFailure) {
            Matrix.of(context).userInfoState = dartz.Left(failure);
          }
          await LocalizationService.initializeLanguage(context);
        },
        (success) async {
          if (success is! GetUserInfoSuccess) return;

          if (widget.userId != null) {
            final interceptor = getIt.get<MatrixDioCacheInterceptor>(
              instanceName: NetworkDI.memCacheDioInterceptorName,
            );
            interceptor.addUriSupportsCache([
              TomEndpoint.userInfoServicePath.generateTomUserInfoEndpoint(
                widget.userId!,
              ),
            ]);
          }

          Matrix.of(context).userInfoState = dartz.Right(success);
          await LocalizationService.initializeLanguage(
            context,
            serverLanguage: success.userInfo.language,
          );
        },
      ),
      onDone: () {
        context.pushReplacement('/rooms');
      },
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinagoraSysColors.material().onPrimary,
      body: ProgressDialog(
        lottieSize: PlatformInfos.isWeb
            ? TwakeDialog.lottieSizeWeb
            : TwakeDialog.lottieSizeMobile,
      ),
    );
  }
}
