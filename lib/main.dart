import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'presentation/providers/core_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 创建 ProviderContainer 并预初始化服务
  final container = ProviderContainer();

  // 等待初始化完成
  await container.read(appInitializationProvider.future);

  runApp(
    UncontrolledProviderScope(container: container, child: const BabyEmrApp()),
  );
}
