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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Slidable Cell 示例')),
      backgroundColor: Colors.grey,
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
              separatorBuilder: (_, __) => Container(height: 0.3, color: Colors.white70),
              itemBuilder: (context, index) {
                final key = ValueKey('cell_$index');
                return SlideableCellView(
                  key: key,
                  controller: _controller,
                  expandMode: SlideableCellExpandMode.adjustEdge,
                  openFactor: 0.3,
                  closeFactor: 0.3,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  color: Colors.grey,
                  leadingFullExpandable: true,
                  leadingActions: const [
                    SlideableActionItem(
                      width: 70,
                      slideBackgroundColor: Colors.blue,
                      alignment: Alignment.center,
                      icon: Icon(Icons.vertical_align_top, color: Colors.white, size: 18),
                      iconPadding: EdgeInsets.only(right: 4),
                      text: '置顶',
                      textStyle: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      layout: SlideableActionItemLayout.iconLeftTextRight,
                    ),
                    SlideableActionItem(
                      width: 85,
                      slideBackgroundColor: Colors.green,
                      alignment: Alignment.center,
                      icon: Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 18),
                      iconPadding: EdgeInsets.only(right: 4),
                      text: '标记已读',
                      textStyle: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      layout: SlideableActionItemLayout.iconLeftTextRight,
                    ),
                  ],
                  trailingActions: const [
                    SlideableActionItem(
                      width: 92,
                      slideBackgroundColor: Colors.orange,
                      alignment: Alignment.center,
                      icon: Icon(Icons.schedule_outlined, color: Colors.white, size: 18),
                      iconPadding: EdgeInsets.only(bottom: 4),
                      text: '稍后处理',
                      textStyle: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      layout: SlideableActionItemLayout.iconTopTextBottom,
                    ),
                    SlideableActionItem(
                      width: 76,
                      slideBackgroundColor: Colors.red,
                      alignment: Alignment.center,
                      icon: Icon(Icons.delete_outline, color: Colors.white, size: 18),
                      iconPadding: EdgeInsets.only(bottom: 4),
                      text: '删除',
                      textStyle: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      layout: SlideableActionItemLayout.iconTopTextBottom,
                    ),
                  ],
                  child: Container(
                    alignment: Alignment.center,
                    height: 65,
                    color: Colors.white,
                    width: double.infinity,
                    child: Text('消息 #$index'),
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
