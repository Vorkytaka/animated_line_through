import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that animate line through text.
///
/// State os cross-line is controlled by [isCrossed] parameter.
///
/// @{template line_child}
/// The [child] must not be null.
///
/// The child must be a widget that use either [RenderParagraph]
/// or [RenderEditable] as render object.
///
/// In most cases it's just [Text], [RichText], [TextField] or [TextFormField].
///
/// If child is any other widget, then there is no effect.
/// @{endtemplate}
///
/// For cases, when you need more control over animation,
/// see [AnimatedLineThroughRaw] widget.
class AnimatedLineThrough extends StatefulWidget {
  /// Child that should be crossed.
  ///
  /// @{macro line_child}
  final Widget child;

  /// The color of cross-line itself.
  ///
  /// If null, then try to use [DefaultTextStyle] [TextStyle.color].
  /// If this is also null, then use theme's [ColorScheme.onSurface].
  final Color? color;

  /// Whenever is text should be crossed with line.
  final bool isCrossed;

  /// The curve to apply when animating cross-line in.
  ///
  /// Defaults to [Curves.linear].
  final Curve curve;

  /// The curve to apply when animating cross-line out.
  ///
  /// Defaults to null. In this case use [curve].
  final Curve? reverseCurve;

  /// The duration over which to animate cross-line.
  ///
  /// Must not be null.
  final Duration duration;

  /// The duration over which to animate cross-line when it's gone.
  ///
  /// Defaults to null. In this case use [duration].
  final Duration? reverseDuration;

  /// The width of the stroke to paint over the text
  ///
  /// If this is not provided, default value of 1.5 will be used.
  final double strokeWidth;

  /// Creates a animated line through.
  ///
  /// @{macro line_child}
  ///
  /// The values of [isCrossed] and [duration] must not be null.
  const AnimatedLineThrough({
    super.key,
    required this.child,
    required this.isCrossed,
    required this.duration,
    this.color,
    this.strokeWidth = 1.5,
    this.curve = Curves.linear,
    this.reverseCurve,
    this.reverseDuration,
  });

  @override
  State<AnimatedLineThrough> createState() => _AnimatedLineThroughState();
}

class _AnimatedLineThroughState extends State<AnimatedLineThrough>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    reverseDuration: widget.reverseDuration,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
    reverseCurve: widget.reverseCurve,
  );

  @override
  void initState() {
    super.initState();
    _controller.value = widget.isCrossed ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant AnimatedLineThrough oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCrossed != oldWidget.isCrossed) {
      _animateToValue();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;

    return AnimatedLineThroughRaw(
      crossed: _animation,
      color: color,
      strokeWidth: widget.strokeWidth,
      child: widget.child,
    );
  }

  void _animateToValue() {
    if (widget.isCrossed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }
}

/// Raw animated line through widget with given [Animation].
///
/// Useful for cases, when we need to clearly control state cross-line.
/// For example, when we use animated line through in [staggered animations](https://docs.flutter.dev/ui/animations/staggered-animations).
class AnimatedLineThroughRaw extends SingleChildRenderObjectWidget {
  /// State of cross line above the child.
  final Animation<double> crossed;

  /// The color of cross-line itself.
  final Color color;

  /// The width of the stroke to paint over the text
  ///
  /// If this is not provided, default value of 1.5 will be used.d
  final double strokeWidth;

  /// Creates a raw animated line through.
  ///
  /// @{macro line_child}
  const AnimatedLineThroughRaw({
    super.key,
    required this.crossed,
    required this.color,
    this.strokeWidth = 1.5,
    super.child,
  }) : assert(child != null);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final isAroundTextField = child is TextField || child is TextFormField;

    return _AnimatedLineThroughRenderObject(
      crossed: crossed,
      color: color,
      strokeWidth: strokeWidth,
      isAroundTextField: isAroundTextField,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    _AnimatedLineThroughRenderObject renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject.color = color;
    renderObject.strokeWidth = strokeWidth;
  }
}

/// Render proxy that draw line through the text.
///
/// This render object draw line on every line of text.
///
/// When animation is going, then we draw the crossline for each line
/// starting from the first one and so on one after another.
class _AnimatedLineThroughRenderObject extends RenderProxyBox {
  final Animation<double> crossed;

  /// Color that used as the color of the cross line.
  Color color;

  /// A flag that indicates if child of the widget is [TextField] or [TextFormField].
  ///
  /// Without that we handle only cases, when child is [Text]
  /// or other widget that use [RenderParagraph] under the hood.
  ///
  /// If this is true, then we make some extra work to handle [TextField].
  /// We go through entire render tree from this node to the [RenderEditable] itself.
  /// Many hacks and possible bugs, but.. well.. ok. :)
  final bool isAroundTextField;

  /// The width of the stroke to paint over the text
  ///
  /// If this is not provided, default value of 1.5 will be used.
  double strokeWidth;

  /// Main paint object.
  /// Cache it here.
  late final Paint _paint = Paint();

  /// Metrics of the child's text.
  ///
  /// Count on the [performLayout] phase.
  List<ui.LineMetrics>? _metrics;

  /// A text direction of the child.
  ///
  /// We need it to handle RTL stroke.
  ui.TextDirection? _textDirection;

  /// A text align of the child.
  ///
  /// We need it to calculate Rtl adjustment
  ui.TextAlign _textAlign = ui.TextAlign.start;

  /// An offset of the [RenderEditable] that was set by it parent.
  ///
  /// We can get it not from the [RenderEditable] itself, but from [RenderObject] above it.
  /// The one that is direct child of [SlottedContainerRenderObjectMixin].
  Offset? _editableOffset;

  /// A size of the [RenderEditable] that we count before painting.
  Size? _editableSize;

  /// Full width of the text.
  ///
  /// Count as an sum of all lines width.
  double _fullTextWidth = 0;

  _AnimatedLineThroughRenderObject({
    required this.crossed,
    required this.color,
    required this.isAroundTextField,
    required this.strokeWidth,
    RenderBox? child,
  }) : super(child) {
    crossed.addListener(_onCrossedChanged);
  }

  /// Go through the render tree and try to find closest render object of the type [N].
  ///
  /// We trying to find [N] with recursive Depth-first search.
  ///
  /// ## `Text`
  ///
  /// Text widget can be wrapped with some extra render object, like semantics.
  /// In this case we still has [Text] as our child, but don't have [RenderParagraph] directly.
  ///
  /// ## `TextField`
  ///
  /// The problem with [TextField] is that it use `_RenderDecoration` class for handle position of input field.
  /// `_RenderDecoration` itself is private and also `_DecorationSlot` private.
  /// So, we can't get exactly render object that we need.
  ///
  /// At the september 2023, input is almost everytime first child.
  /// The only case, when input is second – when we have [InputDecoration.icon].
  ///
  /// Complexity of this method is `O(N)`, where `N` is count of tree-nodes.
  static N? _foundSpecificNode<N extends RenderObject>(RenderObject? object) {
    if (object is N) {
      return object;
    }

    if (object is RenderObjectWithChildMixin) {
      return _foundSpecificNode<N>(object.child);
    } else if (object is SlottedContainerRenderObjectMixin) {
      // ignore: invalid_use_of_protected_member
      for (final child in object.children) {
        final childObject = _foundSpecificNode<N>(child);
        if (childObject != null) {
          return _foundSpecificNode<N>(childObject);
        }
      }
    }

    return null;
  }

  @override
  void dispose() {
    crossed.removeListener(_onCrossedChanged);
    super.dispose();
  }

  void _onCrossedChanged() => markNeedsPaint();

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    final metrics = _metrics;
    if (metrics != null && metrics.isNotEmpty) {
      // Editable can have it's own offset
      // e.g. if text field had a prefix widget
      if (_editableOffset != null) {
        offset += _editableOffset!;
      }

      _paint.color = color;
      _paint.strokeWidth = strokeWidth;

      double currentWidth = _fullTextWidth * crossed.value;
      double currentHeight = offset.dy;

      for (int i = 0; i < metrics.length; i++) {
        // We don't need to count everything, because we won't draw it
        if (currentWidth <= 0) {
          break;
        }

        final metric = metrics[i];
        double xStart = metric.left + offset.dx;
        double xEnd = (metric.left + currentWidth.clamp(0, metric.width)) + offset.dx;

        if (_textDirection == ui.TextDirection.rtl) {
          final adjustedDxOffset =  _adjustLeftForRtl(metric, _textAlign) + offset.dx;
          xStart = metric.width + adjustedDxOffset;
          xEnd = ( metric.width - currentWidth.clamp(0, metric.width)) + adjustedDxOffset;
        }

        currentWidth -= metric.width;

        final double y = currentHeight + metric.height * 0.55;
        currentHeight += metric.height;

        context.canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), _paint);
      }
    }
  }

  @override
  void performLayout() {
    super.performLayout();

    final RenderParagraph? paragraph = _foundTextRenderer();
    final RenderEditable? editable = _foundTextFieldRenderer();

    final InlineSpan? text;
    final TextAlign? textAlign;
    final TextDirection? textDirection;
    final TextScaler? textScaler;
    final int? maxLines;
    final String? ellipsis;
    final Locale? locale;
    final StrutStyle? strutStyle;
    final TextWidthBasis? textWidthBasis;
    final TextHeightBehavior? textHeightBehavior;
    final double maxWidth;
    if (paragraph != null) {
      text = paragraph.text;
      textAlign = paragraph.textAlign;
      textDirection = paragraph.textDirection;
      textScaler = paragraph.textScaler;
      maxLines = paragraph.maxLines;
      ellipsis = paragraph.overflow == TextOverflow.ellipsis ? '\u2026' : null;
      locale = paragraph.locale;
      strutStyle = paragraph.strutStyle;
      textWidthBasis = paragraph.textWidthBasis;
      textHeightBehavior = paragraph.textHeightBehavior;
      maxWidth = paragraph.textSize.width;
    } else if (editable != null && _editableSize != null) {
      text = editable.text;
      textAlign = editable.textAlign;
      textDirection = editable.textDirection;
      textScaler = editable.textScaler;
      maxLines = editable.maxLines;
      ellipsis = null; // Editable have no ellipsis
      locale = editable.locale;
      strutStyle = editable.strutStyle;
      textWidthBasis = editable.textWidthBasis;
      textHeightBehavior = editable.textHeightBehavior;

      // This is copy of width compute logic from `_RenderEditable`
      // With some literal, because values is private
      final availableMaxWidth =
          max(0.0, _editableSize!.width - 1 - editable.cursorWidth);
      final textMaxWidth =
          editable.maxLines != 1 ? availableMaxWidth : double.infinity;

      maxWidth = textMaxWidth;
    } else {
      return;
    }

    final painter = TextPainter(
      text: text,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
      ellipsis: ellipsis,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
    painter.layout(maxWidth: maxWidth);

    final metrics = painter.computeLineMetrics();
    _metrics = metrics;
    _textDirection = textDirection;
    _textAlign = textAlign;
    _fullTextWidth = metrics.fold<double>(0, (p, metric) => p + metric.width);
  }

  /// The method that we use when the child of current widget is [TextField] or [TextFormField].
  /// Trying to find the [RenderEditable] that has almost everything that we need.
  RenderEditable? _foundTextFieldRenderer() {
    if (!isAroundTextField) {
      return null;
    }

    final editable = _foundSpecificNode<RenderEditable>(child);
    if (editable != null) {
      final renderBox = _findRenderBoxAroundEditable(editable);
      if (renderBox != null) {
        _editableOffset = (renderBox.parentData as BoxParentData).offset;
        _editableSize = renderBox.computeDryLayout(renderBox.constraints);
      }
      return editable;
    }

    return null;
  }

  /// Go up in the render tree and try to find closest [RenderBox].
  ///
  /// We need the closest [RenderBox], so we can get both [Offset] and [Size].
  /// [Offset] is used for cases, when [TextField] have anything before input.
  /// [Size] is used for count line metrics.
  RenderBox? _findRenderBoxAroundEditable(RenderObject? object) {
    while (object != null) {
      ParentData? data = object.parentData;
      if (data is BoxParentData) {
        return object as RenderBox;
      } else if (object is _AnimatedLineThroughRenderObject) {
        // If we reach our main render object,
        // then there is no `BoxParentData`
        return null;
      }

      object = object.parent;
    }

    return null;
  }

  /// The method that we use when the child of current widget is the [Text].
  /// Or any other widget that use [RenderParagraph] under the hood.
  ///
  /// Funny, but [Icon] widget is also use [RenderParagraph], because each icon is some char in specific font.
  /// So, because of that, we can animate line through [Icon] widget.
  RenderParagraph? _foundTextRenderer() {
    if (isAroundTextField) {
      // If our child is `RenderEditable` then we will find it later.
      return null;
    } else if (child != null && child is RenderParagraph) {
      // Check if current child is already what we are looking for.
      return child as RenderParagraph;
    } else {
      // Otherwise let's try find it with.
      return _foundSpecificNode<RenderParagraph>(child);
    }
  }

  double _adjustLeftForRtl(ui.LineMetrics metric, ui.TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return (size.width - metric.width) / 2;
      case TextAlign.right:
      case TextAlign.start:
        return size.width - metric.width;
      default:
        return 0;
    }
  }
}
