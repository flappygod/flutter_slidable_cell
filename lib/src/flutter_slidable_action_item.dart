import 'package:flutter/cupertino.dart';

/// 排列方式
enum SlideableActionItemLayout {
  /// 上 icon，下 text
  iconTopTextBottom,

  /// 上 text，下 icon
  textTopIconBottom,

  /// 左 text，右 icon
  textLeftIconRight,

  /// 左 icon，右 text
  iconLeftTextRight,
}

/// 侧滑
class SlideableActionItem extends StatelessWidget {
  /// 扩展时候的颜色
  final Color? slideBackgroundColor;

  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Clip clipBehavior;

  /// 自定义 child
  final Widget? child;

  /// 图标
  final Widget? icon;

  /// 图标 padding
  final EdgeInsetsGeometry? iconPadding;

  /// 文本
  final String? text;

  /// 文本样式
  final TextStyle? textStyle;

  /// 排列方式
  final SlideableActionItemLayout layout;

  const SlideableActionItem({
    super.key,
    this.slideBackgroundColor,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.clipBehavior = Clip.none,
    this.child,
    this.icon,
    this.iconPadding,
    this.text,
    this.textStyle,
    this.layout = SlideableActionItemLayout.iconTopTextBottom,
  });

  bool get _hasIcon => icon != null;

  bool get _hasText => text != null && text!.isNotEmpty;

  Widget? _buildContent() {
    /// 优先使用外部传入 child
    if (child != null) return child;

    final Widget? iconWidget = _hasIcon
        ? Padding(
            padding: iconPadding ?? EdgeInsets.zero,
            child: icon!,
          )
        : null;

    final Widget? textWidget = _hasText
        ? Text(
            text!,
            style: textStyle,
            textAlign: TextAlign.center,
          )
        : null;

    /// 两个都没有，不占空间
    if (iconWidget == null && textWidget == null) {
      return null;
    }

    /// 只有 icon
    if (iconWidget != null && textWidget == null) {
      return iconWidget;
    }

    /// 只有 text
    if (iconWidget == null && textWidget != null) {
      return textWidget;
    }

    /// 两个都有
    switch (layout) {
      case SlideableActionItemLayout.iconTopTextBottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget!,
            textWidget!,
          ],
        );

      case SlideableActionItemLayout.textTopIconBottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            textWidget!,
            iconWidget!,
          ],
        );

      case SlideableActionItemLayout.textLeftIconRight:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            textWidget!,
            iconWidget!,
          ],
        );

      case SlideableActionItemLayout.iconLeftTextRight:
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget!,
            textWidget!,
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      child: _buildContent(),
    );
  }
}
