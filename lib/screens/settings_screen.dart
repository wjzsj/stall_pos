import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFilePath = join(dbPath, 'stall_pos.db');

      final result = await Share.shareXFiles(
        [XFile(dbFilePath)],
        subject: '摆摊进销存数据备份',
        text: '数据备份时间: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );

      if (result.status == ShareResultStatus.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据已准备好分享')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(title: '数据管理'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('导出数据备份'),
            subtitle: const Text('将本地数据库文件分享'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(context),
          ),
          const Divider(),
          _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('摆摊进销存利润计算器'),
            subtitle: const Text('适用于地摊、商超、小店进货销售管理'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
    );
  }
}
