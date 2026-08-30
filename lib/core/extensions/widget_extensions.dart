import 'package:flutter/material.dart';
import '../../app/theme/index.dart';

extension WidgetExtensions on Widget {
  Widget paddingAll(double value) => Padding(padding: EdgeInsets.all(value), child: this);
  Widget paddingHorizontal(double value) => Padding(padding: EdgeInsets.symmetric(horizontal: value), child: this);
  Widget paddingVertical(double value) => Padding(padding: EdgeInsets.symmetric(vertical: value), child: this);
  Widget paddingOnly({double left = 0, double top = 0, double right = 0, double bottom = 0}) =>
      Padding(padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom), child: this);
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical), child: this);

  Widget marginAll(double value) => Padding(padding: EdgeInsets.all(value), child: this);
  Widget marginHorizontal(double value) => Padding(padding: EdgeInsets.symmetric(horizontal: value), child: this);
  Widget marginVertical(double value) => Padding(padding: EdgeInsets.symmetric(vertical: value), child: this);
  Widget marginOnly({double left = 0, double top = 0, double right = 0, double bottom = 0}) =>
      Padding(padding: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom), child: this);

  Widget centered() => Center(child: this);
  Widget aligned(Alignment alignment) => Align(alignment: alignment, child: this);
  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) => Flexible(flex: flex, fit: fit, child: this);
  Widget positioned({double? left, double? top, double? right, double? bottom}) =>
      Positioned(left: left, top: top, right: right, bottom: bottom, child: this);

  Widget constrained({double? minWidth, double? maxWidth, double? minHeight, double? maxHeight}) =>
      ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0,
          maxWidth: maxWidth ?? double.infinity,
          minHeight: minHeight ?? 0,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: this,
      );

  Widget aspectRatio(double ratio) => AspectRatio(aspectRatio: ratio, child: this);
  Widget sizedBox({double? width, double? height}) => SizedBox(width: width, height: height, child: this);

  Widget clipRRect({BorderRadius? borderRadius}) => ClipRRect(borderRadius: borderRadius ?? BorderRadius.zero, child: this);
  Widget clipRect({Clip clipBehavior = Clip.antiAlias}) => ClipRect(clipBehavior: clipBehavior, child: this);
  Widget clipOval() => ClipOval(child: this);

  Widget decorated({
    Color? color,
    DecorationImage? image,
    BoxBorder? border,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    BlendMode? backgroundBlendMode,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          image: image,
          border: border,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
          gradient: gradient,
          backgroundBlendMode: backgroundBlendMode,
          shape: shape,
        ),
        child: this,
      );

  Widget material({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    double elevation = 0,
    BorderSide? border,
    bool shadowOnly = false,
  }) =>
      Material(
        color: color ?? Colors.transparent,
        borderRadius: borderRadius,
        elevation: elevation,
        shadowColor: shadows?.first.color ?? AppColors.shadowColor,
        child: this,
      );

  Widget animatedContainer({
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double? width,
    double? height,
    Color? color,
    Decoration? decoration,
    Decoration? foregroundDecoration,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry? alignment,
    Clip clipBehavior = Clip.none,
  }) =>
      AnimatedContainer(
        duration: duration,
        curve: curve,
        width: width,
        height: height,
        color: color,
        decoration: decoration,
        foregroundDecoration: foregroundDecoration,
        padding: padding,
        alignment: alignment,
        clipBehavior: clipBehavior,
        child: this,
      );

  Widget animatedOpacity({
    required Duration duration,
    required double opacity,
    Curve curve = Curves.easeInOut,
  }) =>
      AnimatedOpacity(duration: duration, opacity: opacity, curve: curve, child: this);

  Widget animatedScale({
    required Duration duration,
    required double scale,
    Curve curve = Curves.easeInOut,
    Alignment alignment = Alignment.center,
  }) =>
      AnimatedScale(duration: duration, scale: scale, curve: curve, alignment: alignment, child: this);

  Widget animatedRotation({
    required Duration duration,
    required double turns,
    Curve curve = Curves.easeInOut,
    Alignment alignment = Alignment.center,
  }) =>
      AnimatedRotation(duration: duration, turns: turns, curve: curve, alignment: alignment, child: this);

  Widget animatedPositioned({
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) =>
      AnimatedPositioned(
        duration: duration,
        curve: curve,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        width: width,
        height: height,
        child: this,
      );

  Widget withHero({required String tag, CreateRectTween? createRectTween}) =>
      Hero(tag: tag, createRectTween: createRectTween, child: this);

  Widget withTooltip(String message, {Duration? waitDuration, Duration? showDuration}) =>
      Tooltip(message: message, waitDuration: waitDuration, showDuration: showDuration, child: this);

  Widget withSemantics({String? label, String? hint, bool? button, bool? header, bool? liveRegion}) =>
      Semantics(label: label, hint: hint, button: button, header: header, liveRegion: liveRegion, child: this);

  Widget withGestureDetector({
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onLongPress,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragEndCallback? onPanEnd,
    GestureTapDownCallback? onTapDown,
    GestureTapCancelCallback? onTapCancel,
    HitTestBehavior? behavior,
  }) =>
      GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        onTapDown: onTapDown,
        onTapCancel: onTapCancel,
        behavior: behavior,
        child: this,
      );

  Widget withInkWell({
    required VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHighlightChanged,
    ValueChanged<bool>? onHover,
    Color? highlightColor,
    Color? splashColor,
    Color? hoverColor,
    Color? focusColor,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    bool enableFeedback = true,
    bool excludeFromSemantics = false,
  }) =>
      InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        onHighlightChanged: onHighlightChanged,
        onHover: onHover,
        highlightColor: highlightColor,
        splashColor: splashColor,
        hoverColor: hoverColor,
        focusColor: focusColor,
        borderRadius: borderRadius,
        customBorder: customBorder,
        radius: radius,
        enableFeedback: enableFeedback,
        excludeFromSemantics: excludeFromSemantics,
        child: this,
      );

  Widget visible(bool visible, {Widget? replacement, bool maintainState = false, bool maintainAnimation = false, bool maintainSize = false}) =>
      Visibility(visible: visible, replacement: replacement ?? const SizedBox.shrink(), maintainState: maintainState, maintainAnimation: maintainAnimation, maintainSize: maintainSize, child: this);

  Widget offlineFirst({required Widget child, required bool isOnline}) => isOnline ? this : child;

  Widget customAnimate({
    required Duration duration,
    Curve curve = Curves.easeOutCubic,
    double? delay,
    Offset? beginOffset,
    Offset? endOffset,
    double? beginScale,
    double? endScale,
    double? beginOpacity,
    double? endOpacity,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        Widget result = child!;
        if (beginOffset != null && endOffset != null) {
          result = Transform.translate(
            offset: Offset.lerp(beginOffset, endOffset, value)!,
            child: result,
          );
        }
        if (beginScale != null && endScale != null) {
          result = Transform.scale(
            scale: lerpDouble(beginScale, endScale, value)!,
            child: result,
          );
        }
        if (beginOpacity != null && endOpacity != null) {
          result = Opacity(
            opacity: lerpDouble(beginOpacity, endOpacity, value)!,
            child: result,
          );
        }
        return result;
      },
      child: this,
    );
  }

  Widget staggerAnimation({
    required Duration duration,
    required int index,
    required int itemCount,
    Curve curve = Curves.easeOutCubic,
    Offset? beginOffset,
    Offset? endOffset,
    double? beginScale,
    double? endScale,
    double? beginOpacity,
    double? endOpacity,
  }) {
    final delay = (duration.inMilliseconds / itemCount) * index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        final delayedValue = (value - delay / duration.inMilliseconds).clamp(0.0, 1.0);
        Widget result = child!;
        if (beginOffset != null && endOffset != null) {
          result = Transform.translate(
            offset: Offset.lerp(beginOffset, endOffset, delayedValue)!,
            child: result,
          );
        }
        if (beginScale != null && endScale != null) {
          result = Transform.scale(
            scale: lerpDouble(beginScale, endScale, delayedValue)!,
            child: result,
          );
        }
        if (beginOpacity != null && endOpacity != null) {
          result = Opacity(
            opacity: lerpDouble(beginOpacity, endOpacity, delayedValue)!,
            child: result,
          );
        }
        return result;
      },
      child: this,
    );
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;