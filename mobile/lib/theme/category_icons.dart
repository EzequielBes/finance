import 'package:flutter/material.dart';

IconData categoryIconFor(String? iconKey) {
  switch (iconKey) {
    case 'bank':
      return Icons.account_balance_outlined;
    case 'tag':
      return Icons.local_offer_outlined;
    case 'transactions':
      return Icons.swap_horiz;
    case 'wallet':
      return Icons.account_balance_wallet_outlined;
    case 'trending-up':
      return Icons.trending_up;
    default:
      return Icons.label_outline;
  }
}
