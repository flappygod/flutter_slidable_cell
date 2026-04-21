import 'package:flutter_slidable_cell/flutter_slidable_cell.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SlidableExampleApp());
}

/// 示例入口。
/// Example app entry.
class SlidableExampleApp extends StatelessWidget {
  const SlidableExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slidable Cell Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const SlidableExamplePage(),
    );
  }
}

/// 展示手势与控制器两种开关方式。
/// Demonstrates gesture and controller driven open/close.
class SlidableExamplePage extends StatefulWidget {
  const SlidableExamplePage({super.key});

  @override
  State<SlidableExamplePage> createState() => _SlidableExamplePageState();
}

class _SlidableExamplePageState extends State<SlidableExamplePage> {
  final SlideableCellController _controller = SlideableCellController();
  final List<int> _items = List<int>.generate(8, (index) => index);

  Future<void> _openFirstLeading() async {
    await _controller.openLeading(const ValueKey('cell_0'));
    setState(() {});
  }

  Future<void> _openSecondTrailing() async {
    await _controller.openTrailing(const ValueKey('cell_1'));
    setState(() {});
  }

  Future<void> _closeAll() async {
    await _controller.closeAllCells();
    setState(() {});
  }

  Color _statusColor(SlideableCellStatus status) {
    switch (status) {
      case SlideableCellStatus.closed:
        return Colors.grey;
      case SlideableCellStatus.leadingOpen:
        return Colors.green;
      case SlideableCellStatus.trailingOpen:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slidable Cell 示例')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _openFirstLeading, child: const Text('打开第1项左侧')),
                FilledButton(onPressed: _openSecondTrailing, child: const Text('打开第2项右侧')),
                OutlinedButton(onPressed: _closeAll, child: const Text('关闭全部')),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final key = ValueKey('cell_$index');
                final status = _controller.statusOf(key);
                return SlideableCellView(
                  key: key,
                  controller: _controller,
                  expandMode: SlideableCellExpandMode.adjustEdge,
                  openFactor: 0.3,
                  closeFactor: 0.3,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  leadingActions: [
                    Container(
                      width: 80,
                      color: Colors.blue,
                      alignment: Alignment.center,
                      child: const Text('置顶', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 96,
                      color: Colors.green,
                      alignment: Alignment.center,
                      child: const Text('标记已读', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  trailingActions: [
                    Container(
                      width: 92,
                      color: Colors.orange,
                      alignment: Alignment.center,
                      child: const Text('稍后处理', style: TextStyle(color: Colors.white)),
                    ),
                    Container(
                      width: 76,
                      color: Colors.red,
                      alignment: Alignment.center,
                      child: const Text('删除', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  child: ListTile(
                    tileColor: Colors.white,
                    title: Text('消息 #$index'),
                    subtitle: Text('status: ${status.name}'),
                    trailing: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
