import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../providers/baby_providers.dart';

/// 新增与当前宝宝绑定的记录前调用。若无当前宝宝则提示并返回 false。
bool ensureCurrentBabyForNewRecord(WidgetRef ref, BuildContext context) {
  if (ref.read(currentBabyIdProvider) != null) return true;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    const SnackBar(content: Text(AppConstants.addBabyBeforeRecordMessage)),
  );
  return false;
}
