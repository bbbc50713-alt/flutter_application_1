import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/webview_config.dart';

/// 3D 图表组件 - 使用 ECharts 渲染电池放电 3D 曲面图
class Graph3DWidget extends StatefulWidget {
  final List<List<double>> voltageData;
  final int cellCount;
  final int hourCount;
  final double minHeight;
  final bool enableInteraction;
  final VoidCallback? onGraphReady;
  
  const Graph3DWidget({
    Key? key,
    required this.voltageData,
    this.cellCount = 24,
    this.hourCount = 6,
    this.minHeight = 400,
    this.enableInteraction = true,
    this.onGraphReady,
  }) : super(key: key);

  @override
  Graph3DWidgetState createState() => Graph3DWidgetState();
}

class Graph3DWidgetState extends State<Graph3DWidget> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isWebViewReady = false;
  final Completer<void> _graphReadyCompleter = Completer<void>();
  final Map<String, Completer<String>> _pendingCaptures = {};

  @override
  void initState() {
    super.initState();
    _validateData();
  }

  /// 验证输入数据
  void _validateData() {
    // 确保数据格式正确：24 行 × 6 列
    if (widget.voltageData.isEmpty) {
      setState(() {
        _errorMessage = 'No data available';
        _isLoading = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: widget.minHeight,
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 3D 图表 WebView
            InAppWebView(
              initialFile: 'assets/graphs/3d_graph.html',
              initialSettings: _getWebViewSettings(),
              onWebViewCreated: (controller) {
                _webViewController = controller;

                // Register JavaScript handlers
                controller.addJavaScriptHandler(
                  handlerName: 'onGraphReady',
                  callback: (args) {
                    debugPrint('Graph ready callback received from JS');
                    if (!_graphReadyCompleter.isCompleted) {
                      _graphReadyCompleter.complete();
                    }
                  },
                );

                controller.addJavaScriptHandler(
                  handlerName: 'onGraphCaptureResult',
                  callback: (args) {
                    if (args.isEmpty) return;

                    final result = args[0] as Map<String, dynamic>;
                    final captureId = result['captureId'] as String?;

                    if (captureId == null) return;

                    final completer = _pendingCaptures[captureId];
                    if (completer != null && !completer.isCompleted) {
                      if (result['success'] == true) {
                        final data = result['data'] as String?;
                        if (data != null) {
                          debugPrint('Capture successful for $captureId');
                          completer.complete(data);
                        } else {
                          completer.completeError('No data in result');
                        }
                      } else {
                        final error = result['error'] as String? ?? 'Unknown error';
                        debugPrint('Capture failed for $captureId: $error');
                        completer.completeError(error);
                      }
                      _pendingCaptures.remove(captureId);
                    }
                  },
                );
              },
              onLoadStop: (controller, url) async {
                await _sendDataToWebView();
                setState(() {
                  _isLoading = false;
                  _isWebViewReady = true;
                });
                // Don't complete _graphReadyCompleter here - wait for JS onGraphReady callback
                widget.onGraphReady?.call();
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint('WebView Console: ${consoleMessage.message}');
              },
              onReceivedError: (controller, request, error) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = WebViewConfig.getErrorMessage(error);
                });
              },
              onReceivedHttpError: (controller, request, errorResponse) {
                debugPrint('HTTP Error: ${errorResponse.statusCode}');
              },
            ),
            
            // 加载指示器
            if (_isLoading) _buildLoadingIndicator(),
            
            // 错误提示
            if (_errorMessage != null) _buildErrorWidget(),
          ],
        ),
      ),
    );
  }

  /// 获取 WebView 设置
  InAppWebViewSettings _getWebViewSettings() {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useHybridComposition: true,
      cacheEnabled: true,
      cacheMode: CacheMode.LOAD_DEFAULT,
      useWideViewPort: true,
      loadWithOverviewMode: true,
      supportZoom: true,
      builtInZoomControls: true,
      displayZoomControls: false,
      allowFileAccess: true,
      allowContentAccess: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.white.withOpacity(0.9),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading 3D Graph...',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误提示
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.red.withOpacity(0.05),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Graph Loading Failed',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                    _webViewController?.reload();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 发送数据到 WebView
  Future<void> _sendDataToWebView() async {
    try {
      debugPrint('Sending 3D graph data: ${widget.cellCount} cells × ${widget.hourCount} hours');
      debugPrint('Data matrix size: ${widget.voltageData.length} × ${widget.voltageData.isNotEmpty ? widget.voltageData[0].length : 0}');

      List<List<Map<String, dynamic>>> data3D = [];

      for (int cell = 0; cell < widget.voltageData.length; cell++) {
        List<Map<String, dynamic>> cellData = [];
        for (int hour = 0; hour < widget.voltageData[cell].length; hour++) {
          double voltage = widget.voltageData[cell][hour];
          // Only include non-zero voltages (filter unused data points)
          if (voltage > 0) {
            cellData.add({
              'x': (hour + 1).toDouble(),
              'y': (cell + 1).toDouble(),  // Fixed: sequential cell numbering
              'z': voltage,
            });
          }
        }
        // Only add cells that have data
        if (cellData.isNotEmpty) {
          data3D.add(cellData);
        }
      }

      String jsonData = jsonEncode(data3D);

      await _webViewController?.evaluateJavascript(
        source: 'render3DGraph(\'$jsonData\', ${widget.cellCount}, ${widget.hourCount});',
      );

      debugPrint('3D graph data sent to WebView: ${data3D.length} cells, ${widget.cellCount} cells, ${widget.hourCount} hours');
    } catch (e) {
      debugPrint('Error sending data to WebView: $e');
      setState(() {
        _errorMessage = 'Data send failed: $e';
        _isLoading = false;
      });
    }
  }

  /// 更新图表数据（不重建 WebView）
  Future<void> updateData(List<List<double>> newData) async {
    if (!_isWebViewReady) {
      debugPrint('WebView not ready, skipping data update');
      return;
    }

    try {
      List<List<Map<String, dynamic>>> data3D = [];

      for (int cell = 0; cell < newData.length; cell++) {
        List<Map<String, dynamic>> cellData = [];
        for (int hour = 0; hour < newData[cell].length; hour++) {
          double voltage = newData[cell][hour];
          // Only include non-zero voltages (filter unused data points)
          if (voltage > 0) {
            cellData.add({
              'x': (hour + 1).toDouble(),
              'y': (cell + 1).toDouble(),  // Fixed: sequential cell numbering
              'z': voltage,
            });
          }
        }
        // Only add cells that have data
        if (cellData.isNotEmpty) {
          data3D.add(cellData);
        }
      }
      
      String jsonData = jsonEncode(data3D);
      
      await _webViewController?.evaluateJavascript(
        source: 'updateGraphData(\'$jsonData\');',
      );
      
      debugPrint('3D graph data updated: ${data3D.length} cells');
    } catch (e) {
      debugPrint('Error updating data: $e');
    }
  }

  /// Wait for graph to be fully ready (with timeout)
  Future<void> waitForGraphReady() async {
    try {
      await _graphReadyCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Graph ready timeout - proceeding anyway');
        },
      );
    } catch (e) {
      debugPrint('Error waiting for graph ready: $e');
    }
  }

  Future<Uint8List?> captureScreenshot({int alpha = 45, int beta = 45}) async {
    if (_webViewController == null || !_isWebViewReady) {
      debugPrint('WebView not ready for screenshot');
      return null;
    }

    final captureId = 'capture_${DateTime.now().millisecondsSinceEpoch}';
    try {
      // Generate unique capture ID
      final completer = Completer<String>();
      _pendingCaptures[captureId] = completer;

      // Request capture (returns immediately)
      await _webViewController!.evaluateJavascript(
        source: 'requestChartCapture("$captureId", {alpha: $alpha, beta: $beta})',
      );

      // Wait for callback with timeout
      final base64Str = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Capture timeout after 10 seconds'),
      );

      // Decode and validate
      String cleanBase64 = base64Str;
      if (cleanBase64.startsWith('data:image')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      final decoded = base64Decode(cleanBase64);

      // Validate PNG header (89 50 4E 47)
      if (decoded.length < 8 ||
          decoded[0] != 0x89 || decoded[1] != 0x50 ||
          decoded[2] != 0x4E || decoded[3] != 0x47) {
        debugPrint('Invalid PNG header');
        return null;
      }

      // Validate minimum size
      if (decoded.length < 1000) {
        debugPrint('Image too small: ${decoded.length} bytes');
        return null;
      }

      debugPrint('Valid PNG captured: ${decoded.length} bytes');
      return decoded;
    } catch (e) {
      debugPrint('Error capturing chart image: $e');
      _pendingCaptures.remove(captureId);
      return null;
    }
  }

  @override
  void dispose() {
    _webViewController?.dispose();
    // Clean up any pending captures
    for (var completer in _pendingCaptures.values) {
      if (!completer.isCompleted) {
        completer.completeError('Widget disposed');
      }
    }
    _pendingCaptures.clear();
    super.dispose();
  }
}
