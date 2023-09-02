import 'package:animated_line_through/animated_line_through.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

const _lorum =
    "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.";

enum _Tabs {
  simple,
  raw;
}

extension on _Tabs {
  String get format {
    switch (this) {
      case _Tabs.simple:
        return 'Simple';
      case _Tabs.raw:
        return 'Raw';
    }
  }

  Widget get tabView {
    switch (this) {
      case _Tabs.simple:
        return const _Simple();
      case _Tabs.raw:
        return const _Raw();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: _Tabs.values.length,
        child: const _Screen(),
      ),
    );
  }
}

class _Screen extends StatelessWidget {
  const _Screen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animated Line Through'),
        bottom: TabBar(
          controller: DefaultTabController.of(context),
          tabs: [
            for (final tab in _Tabs.values)
              Tab(
                child: Text(tab.format),
              ),
          ],
        ),
      ),
      body: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: TabBarView(
        children: [for (final tab in _Tabs.values) tab.tabView],
      ),
    );
  }
}

class _Simple extends StatefulWidget {
  const _Simple();

  @override
  State<_Simple> createState() => _SimpleState();
}

class _SimpleState extends State<_Simple> {
  bool _isCrossed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          value: _isCrossed,
          onChanged: (isCrossed) => setState(() {
            _isCrossed = isCrossed;
          }),
          title: const Text('Cross line'),
        ),
        const Divider(),
        AnimatedLineThrough(
          duration: const Duration(milliseconds: 500),
          isCrossed: _isCrossed,
          child: const Text(_lorum),
        ),
      ],
    );
  }
}

class _Raw extends StatefulWidget {
  const _Raw();

  @override
  State<_Raw> createState() => _RawState();
}

class _RawState extends State<_Raw> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Crossed value:'),
        Slider.adaptive(
          value: _controller.value,
          min: 0.0,
          max: 1.0,
          onChanged: (value) => setState(() {
            _controller.value = value;
          }),
        ),
        const Divider(),
        AnimatedLineThroughRaw(
          crossed: _controller,
          color: Colors.black,
          child: const Text(_lorum),
        ),
      ],
    );
  }
}
