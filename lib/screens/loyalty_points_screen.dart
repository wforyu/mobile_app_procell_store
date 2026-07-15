import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../helpers/theme.dart';

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({super.key});

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  final ApiService _api = ApiService();
  int _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final balanceRes = await _api.getLoyaltyBalance();
      final historyRes = await _api.getLoyaltyHistory();
      if (!mounted) return;
      final data = historyRes['data'] as List? ?? [];
      final meta = historyRes['meta'] as Map<String, dynamic>?;
      setState(() {
        _balance = balanceRes['balance'] as int? ?? 0;
        _transactions = data.cast<Map<String, dynamic>>();
        _currentPage = meta?['current_page'] as int? ?? 1;
        _lastPage = meta?['last_page'] as int? ?? 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _api.getLoyaltyHistory(page: _currentPage + 1);
      if (!mounted) return;
      final data = res['data'] as List? ?? [];
      final meta = res['meta'] as Map<String, dynamic>?;
      setState(() {
        _transactions.addAll(data.cast<Map<String, dynamic>>());
        _currentPage = meta?['current_page'] as int? ?? _currentPage + 1;
        _lastPage = meta?['last_page'] as int? ?? _lastPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'earned_from_order': return 'Pembelian';
      case 'earned_from_refund': return 'Refund';
      case 'redeemed': return 'Penukaran';
      case 'referral_bonus': return 'Referral';
      case 'expired': return 'Kadaluarsa';
      case 'admin_adjustment': return 'Penyesuaian';
      default: return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'earned_from_order': return Icons.shopping_bag;
      case 'earned_from_refund': return Icons.replay;
      case 'redeemed': return Icons.redeem;
      case 'referral_bonus': return Icons.person_add;
      case 'expired': return Icons.timer_off;
      case 'admin_adjustment': return Icons.admin_panel_settings;
      default: return Icons.circle;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'earned_from_order':
      case 'earned_from_refund':
      case 'referral_bonus':
        return Colors.green;
      case 'redeemed':
      case 'expired':
        return Colors.red;
      case 'admin_adjustment':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poin Loyalitas'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.stars_rounded, size: 40, color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(height: 8),
                          Text(
                            '$_balance',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Poin Tersedia',
                            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '1.000 poin = Rp 1.000 diskon',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Riwayat Transaksi',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_transactions.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('Belum ada riwayat poin', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _transactions.length) {
                            if (_loadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          final t = _transactions[index];
                          final type = t['type'] as String? ?? '';
                          final amount = t['amount'] as int? ?? 0;
                          final desc = t['description'] as String? ?? '';
                          final date = t['created_at_formatted'] as String? ?? '';
                          final isPositive = type.startsWith('earned') || type == 'referral_bonus';
                          final color = _typeColor(type);

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_typeIcon(type), color: color, size: 20),
                            ),
                            title: Text(_typeLabel(type),
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            subtitle: desc.isNotEmpty ? Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isPositive ? '+' : '-'}$amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isPositive ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                              ],
                            ),
                          );
                        },
                        childCount: _transactions.length + (_currentPage < _lastPage ? 1 : 0),
                      ),
                    ),
                  if (_currentPage < _lastPage && !_loading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: TextButton(
                            onPressed: _loadMore,
                            child: const Text('Muat Lebih Banyak'),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
    );
  }
}
