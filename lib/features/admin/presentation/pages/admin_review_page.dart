import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/resources/supabase.dart';

@RoutePage()
class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key});

  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  static const String _kAdminPhone = '6266637123';

  bool _isAdmin() {
    final phone = supabase.auth.currentUser?.phone ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits == _kAdminPhone || digits.endsWith(_kAdminPhone);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAccess());
  }

  void _checkAccess() {
    if (!_isAdmin()) {
      context.router.maybePop();
    }
  }

  Future<void> approveRequest(String requestId) async {
    try {
      await supabase
          .from('vip_requests')
          .update({'status': 'approved'})
          .eq('id', requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('审批成功！VIP 已开通'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin()) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('老板专用 - 待审核名单'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('vip_requests')
            .stream(primaryKey: ['id'])
            .eq('status', 'pending')
            .order('created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!;

          if (requests.isEmpty) {
            return const Center(
              child: Text('目前没有待审核的申请，休息一下吧！☕'),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final item = requests[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    '转账备注：${item['account_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '申请时间：${item['created_at'].toString().substring(0, 16)}',
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => approveRequest(item['id']),
                    child: const Text('准了', style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
