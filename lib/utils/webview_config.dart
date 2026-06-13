import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// WebView 配置工具类 - 为不同平台提供优化的 WebView 设置
class WebViewConfig {
  /// 获取当前平台的 WebView 设置
  static Future<InAppWebViewSettings> getPlatformSettings() async {
    if (Platform.isAndroid) {
      return _getAndroidSettings();
    } else if (Platform.isIOS) {
      return _getIOSSettings();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _getDesktopSettings();
    }
    return InAppWebViewSettings();
  }

  /// Android 平台特定设置
  static InAppWebViewSettings _getAndroidSettings() {
    return InAppWebViewSettings(
      // 基础设置
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      
      // 性能优化
      useHybridComposition: true,  // 混合渲染，提升性能
      
      // 缓存优化
      cacheEnabled: true,
      cacheMode: CacheMode.LOAD_DEFAULT,
      
      // 视图设置
      useWideViewPort: true,
      loadWithOverviewMode: true,
      supportZoom: true,
      builtInZoomControls: true,
      displayZoomControls: false,
      
      // 安全设置（用于本地文件访问）
      allowFileAccess: true,
      allowContentAccess: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      
      // Cookie 设置
      thirdPartyCookiesEnabled: true,
      
      // 滚动设置
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
      
      // 其他
      domStorageEnabled: true,
      databaseEnabled: true,
      
      // 文本大小
      textZoom: 100,
    );
  }

  /// iOS 平台特定设置
  static InAppWebViewSettings _getIOSSettings() {
    return InAppWebViewSettings(
      // 基础设置
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      
      // 性能优化
      useHybridComposition: true,
      
      // 缓存优化
      cacheEnabled: true,
      cacheMode: CacheMode.LOAD_DEFAULT,
      
      // 视图设置
      useWideViewPort: true,
      loadWithOverviewMode: true,
      supportZoom: true,
      builtInZoomControls: false,  // iOS 使用原生缩放
      displayZoomControls: false,
      
      // 滚动设置
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
      
      // 安全设置
      allowFileAccess: true,
      allowContentAccess: true,
      
      // iOS 14+ 特性
      limitsNavigationsToAppBoundDomains: false,
      
      // 其他
      domStorageEnabled: true,
      databaseEnabled: true,
    );
  }

  /// 桌面平台设置（Windows/macOS/Linux）
  static InAppWebViewSettings _getDesktopSettings() {
    return InAppWebViewSettings(
      // 基础设置
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      
      // 性能优化
      useHybridComposition: true,
      
      // 缓存优化
      cacheEnabled: true,
      cacheMode: CacheMode.LOAD_DEFAULT,
      
      // 视图设置
      useWideViewPort: true,
      loadWithOverviewMode: true,
      supportZoom: true,
      builtInZoomControls: true,
      displayZoomControls: false,
      
      // 安全设置
      allowFileAccess: true,
      allowContentAccess: true,
      
      // 其他
      domStorageEnabled: true,
      databaseEnabled: true,
      
      // 滚动设置
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
    );
  }

  /// 获取错误提示信息
  static String getErrorMessage(dynamic error) {
    if (error is WebViewException) {
      return 'WebView Error: ${error.message}';
    }
    return 'Loading failed: $error';
  }
}

/// WebView 异常类
class WebViewException implements Exception {
  final String message;
  WebViewException(this.message);
  
  @override
  String toString() => 'WebViewException: $message';
}
