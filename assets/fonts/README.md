# 字体文件占位符说明

此目录用于存放抖音美好体字体文件。

## 需要的字体文件

请将以下字体文件放置在此目录下：

1. DouyinSans-Regular.ttf (400字重 - 常规)
2. DouyinSans-Medium.ttf (500字重 - 中等)
3. DouyinSans-Bold.ttf (700字重 - 粗体)

## 获取方式

抖音美好体是字节跳动（抖音）官方字体，需要从官方渠道获取：
- 关注抖音官方开发者文档
- 或使用抖音官方提供的字体包下载链接

## 重要提示

- 确保获得的字体文件有合法使用授权
- 字体文件大小通常在 2-5MB 之间
- 放置字体文件后，请运行 `flutter pub get` 重新加载依赖

## 测试字体

字体文件放置完成后，可以通过以下命令测试：

```bash
flutter clean
flutter pub get
flutter run
```

如字体未生效，请检查：
1. 字体文件名称是否与 pubspec.yaml 中配置一致
2. 字体文件是否正确放置在 assets/fonts/ 目录下
3. 是否运行了 `flutter pub get`
