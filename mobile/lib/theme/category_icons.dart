import 'package:flutter/material.dart';

const _iconMap = {
  'bank': Icons.account_balance_outlined,
  'tag': Icons.local_offer_outlined,
  'transactions': Icons.swap_horiz,
  'wallet': Icons.account_balance_wallet_outlined,
  'trending-up': Icons.trending_up,
  'health': Icons.favorite_outline,
  'education': Icons.school_outlined,
  'leisure': Icons.sports_esports_outlined,
  'food': Icons.restaurant_outlined,
  'transport': Icons.directions_car_outlined,
  'home': Icons.home_outlined,
  'shopping': Icons.shopping_bag_outlined,
};

IconData categoryIconFor(String? iconKey) {
  return _iconMap[iconKey] ?? Icons.label_outline;
}

List<String> availableIconKeys() => _iconMap.keys.toList();
