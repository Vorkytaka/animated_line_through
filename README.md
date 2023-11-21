# Animated Line Through

A super simple package to add animated line through text in your Flutter app!

We created this package because Flutter currently lacks built-in support for animating text
decorations, particularly the line through effect.

![Example](https://github.com/Vorkytaka/animated_line_through/blob/media/gif/example.gif?raw=true)

### Usage

This package provides two widgets: `AnimatedLineThrough` and `AnimatedLineThroughRaw`.

Both widgets require a `child` argument, which must be a widget that uses either `RenderParagraph` or
`RenderEditable` as its render object. Without this, the line through effect won't work.

Typically, you'll use widgets like `Text`, `RichText`, `TextField`, or `TextFormField`.

#### AnimatedLineThrough

The `AnimatedLineThrough` widget is ready to use out-of-the-box, just like any other declarative
widget. It expects 3 arguments: `duration`, `isCrossed` and `strokeWidth`(optional). 

Here's an example using `Text` as the child widget:

```dart
AnimatedLineThrough(
  duration: const Duration(milliseconds: 500),
  isCrossed: _isCrossed,
  strokeWidth: 2,
  child: Text('Our text'),
);
```

- `duration` specifies the duration of the animation,
- `isCrossed` is a boolean that indicates whether the text should have a line through effect or not,
- `strokeWidth` defines the width of the line-through to paint over the text.

#### AnimatedLineThroughRaw

The `AnimatedLineThroughRaw` widget gives you more control over the line animation. It expects an
`Animation<double>` object for line progress and a `color` for the line.

Here's an example using `AnimationController` and `Tween` to control the line animation:

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
  strokeWidth: 2.5,
  child: Text('Our text'),
);
```

### Text Fields issues

The workaround for `TextField` (and `TextFormField`) is much more complex than the workaround for simple `Text` widget.
The problem is that those widgets doesn't use `RenderEditable` directly, but have many widget before that.

So, instead of simple get `RenderEditable` we need to find it through render-tree, try to find `RenderBox` above it and then count everything we need to draw a cross line.

But for you it's just that simple as use with simple `Text` widget, just wrap your `TextField` (or `TextFormField`) with `AnimatedLineThrough`:

```dart
AnimatedLineThrough(
  duration: const Duration(milliseconds: 500),
  isCrossed: _isCrossed,
  strokeWidth: 2,
  child: TextField(),
);
```

As the version 1.0.3 we fix main problem with editable widgets, so from now on it's count width of each line correctly.

I hope this helps! Let me know if you have any further questions or issues. 🧡