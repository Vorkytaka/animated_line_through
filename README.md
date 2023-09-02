# Animated Line Through

Very simple implementation of animated line through the text for Flutter.

This package was created because Flutter doesn't have any way to animate text decorations and
specifically line through.

<p align="center"><img src="https://github.com/Vorkytaka/animated_line_through/blob/media/gif/example.gif?raw=true" alt="Example"/></p>

### Usage

Package contain 2 widget that we can use: `AnimatedLineThrough` and `AnimatedLineThroughRaw`.

Both of them expect a `child` argument, that must be a widget that use either `RenderParagraph`
or `RenderEditable` as render object. Otherwise there will be no effect.

In most cases we will use `Text`, `RichText`, `TextField` or `TextFormField` widgets.

`AnimatedLineThrough` is the widget that can be used out-of-the-box like any other declarative
widget. It expect boolean `isCrossed` that indicates whenever is text should be crossed with line
and `duration`.

```dart
AnimatedLineThrough(
  duration: const Duration(milliseconds: 500),
  isCrossed: _isCrossed,
  child: const Text(_lorum),
)
```

On the other hand, `AnimatedLineThroughRaw` is widget that give you more control over line
animation. It expect `Animation<double>` that will used as a line progress and `color` of the line.

```dart
late final _controller = AnimationController();
late final _animation = Tween(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeInOut),
  ),
);

AnimatedLineThroughRaw(
  crossed: _animation,
  color: Colors.black,
  child: const Text(_lorum),
)
```