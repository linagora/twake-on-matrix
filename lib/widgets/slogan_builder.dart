import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A builder which builds a reusable slogan widget.
/// This contains the logo and the slogan text.
/// The elements are arranged in a column or row.

typedef OnTapCallback = void Function();

class SloganBuilder extends StatelessWidget {
  final bool arrangedByHorizontal;
  final String? text;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final String? logoSVG;
  final String? logo;
  final double? sizeLogo;
  final OnTapCallback? onTapCallback;
  final EdgeInsetsGeometry? paddingText;
  final EdgeInsetsGeometry? padding;
  final TextOverflow? overflow;
  final Color? hoverColor;
  final double? hoverRadius;
  final int? maxLines;
  final bool? softWrap;

  const SloganBuilder({
    super.key,
    this.arrangedByHorizontal = true,
    this.overflow,
    this.text,
    this.textStyle,
    this.textAlign,
    this.logoSVG,
    this.logo,
    this.sizeLogo,
    this.onTapCallback,
    this.padding,
    this.paddingText,
    this.hoverColor,
    this.hoverRadius,
    this.maxLines,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    if (!arrangedByHorizontal) {
      return InkWell(
        onTap: onTapCallback,
        hoverColor: hoverColor,
        borderRadius: BorderRadius.all(Radius.circular(hoverRadius ?? 8)),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Column(
            children: [
              _logoApp(),
              Padding(
                padding: paddingText ??
                    const EdgeInsetsDirectional.only(
                      top: 16,
                      start: 16,
                      end: 16,
                    ),
                child: Text(
                  text ?? '',
                  style: textStyle,
                  textAlign: textAlign,
                  overflow: overflow,
                  softWrap: softWrap,
                  maxLines: maxLines,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return InkWell(
        onTap: onTapCallback,
        hoverColor: hoverColor,
        radius: hoverRadius ?? 8,
        borderRadius: BorderRadius.all(Radius.circular(hoverRadius ?? 8)),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Row(
            children: [
              _logoApp(),
              Padding(
                padding:
                    paddingText ?? const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  text ?? '',
                  style: textStyle,
                  textAlign: textAlign,
                  overflow: overflow,
                  softWrap: softWrap,
                  maxLines: maxLines,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _logoApp() {
    if (logoSVG != null) {
      return SvgPicture.asset(
        logoSVG!,
        width: sizeLogo ?? 150,
        height: sizeLogo ?? 150,
      );
    } else if (logo != null) {
      return Image(
        image: AssetImage(logo!),
        fit: BoxFit.fill,
        width: sizeLogo ?? 150,
        height: sizeLogo ?? 150,
        alignment: Alignment.center,
      );
    }
    return const SizedBox.shrink();
  }
}
