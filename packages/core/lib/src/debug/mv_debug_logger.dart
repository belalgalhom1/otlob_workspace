import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Temporary end-to-end Multi-Vendor Order Debug Logger.
///
/// Captures every frontend step, HTTP request/response, and WebSocket event
/// related to multi-vendor / multi-stop orders and writes them continuously to
/// a `.txt` file on the phone (`otlob_mv_debug_trace.txt`), while also keeping
/// an in-memory buffer for one-tap viewing/copying on the device.
class MvDebugLogger {
  MvDebugLogger._();

  static const String _fileName = 'otlob_mv_debug_trace.txt';
  static const int _maxMemoryEntries = 800;

  static String _appTag = 'APP';
  static final List<String> _entries = <String>[];
  static final List<String> _resolvedPaths = <String>[];
  static List<File>? _targetFiles;
  static Future<void> _writeChain = Future<void>.value();

  /// Optional label (e.g. 'CUSTOMER', 'VENDOR', 'DRIVER') to tag log lines.
  static void setAppTag(String tag) {
    if (tag.trim().isNotEmpty) {
      _appTag = tag.trim().toUpperCase();
    }
  }

  static List<String> get entries => List<String>.unmodifiable(_entries);
  static List<String> get resolvedPaths =>
      List<String>.unmodifiable(_resolvedPaths);

  /// Records a step in the multi-vendor order lifecycle and appends it to the
  /// phone's `.txt` debug file.
  static void log(
    String step,
    String message, {
    Map<String, dynamic>? data,
    String? appTag,
  }) {
    final ts = DateTime.now().toIso8601String();
    final tag = (appTag ?? _appTag).toUpperCase();
    final payload = data != null && data.isNotEmpty
        ? ' | ${_safeJsonEncode(data)}'
        : '';
    final line = '[$ts] [$tag] [$step] $message$payload';

    _entries.add(line);
    if (_entries.length > _maxMemoryEntries) {
      _entries.removeRange(0, _entries.length - _maxMemoryEntries);
    }

    debugPrint('[MV-TRACE][$tag][$step] $message$payload');
    _enqueueFileAppend('$line\n');
  }

  static String _safeJsonEncode(Object? value) {
    try {
      return jsonEncode(_sanitize(value, depth: 0));
    } catch (e) {
      return value.toString();
    }
  }

  static Object? _sanitize(Object? value, {required int depth}) {
    if (depth > 5) return '<max_depth>';
    if (value == null || value is num || value is bool) return value;
    if (value is String) {
      return value.length > 600 ? '${value.substring(0, 600)}...(truncated)' : value;
    }
    if (value is Map) {
      final out = <String, Object?>{};
      for (final entry in value.entries) {
        final k = entry.key.toString();
        if (k.toLowerCase().contains('authorization') ||
            k.toLowerCase().contains('token') ||
            k.toLowerCase().contains('password')) {
          out[k] = '***';
        } else {
          out[k] = _sanitize(entry.value, depth: depth + 1);
        }
      }
      return out;
    }
    if (value is Iterable) {
      final list = value.take(25).map((e) => _sanitize(e, depth: depth + 1)).toList();
      if (value.length > 25) {
        list.add('...(+${value.length - 25} more)');
      }
      return list;
    }
    return value.toString();
  }

  static void _enqueueFileAppend(String text) {
    if (kIsWeb) return;
    _writeChain = _writeChain.then((_) async {
      try {
        final files = await _resolveTargetFiles();
        for (final file in files) {
          try {
            await file.writeAsString(text, mode: FileMode.append, flush: true);
          } catch (_) {
            // Ignore unwritable secondary path (e.g. Android scoped Download dir)
          }
        }
      } catch (_) {
        // Never crash app or unit tests if filesystem is unavailable
      }
    });
  }

  static Future<List<File>> _resolveTargetFiles() async {
    if (_targetFiles != null) return _targetFiles!;
    final files = <File>[];
    final seenPaths = <String>{};

    Future<void> tryAddDir(Future<Directory?> Function() getter) async {
      try {
        final dir = await getter();
        if (dir == null) return;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}${Platform.pathSeparator}$_fileName');
        if (seenPaths.add(file.path)) {
          await file.writeAsString(
            '=== Otlob Multi-Vendor Debug Trace (${DateTime.now().toIso8601String()}) ===\n',
            mode: FileMode.append,
            flush: true,
          );
          files.add(file);
          _resolvedPaths.add(file.path);
        }
      } catch (_) {}
    }

    // 1. Android External App Storage (/storage/emulated/0/Android/data/<pkg>/files/otlob_mv_debug_trace.txt)
    // Accessible via USB / Android file manager / adb pull without special permissions.
    if (!kIsWeb && Platform.isAndroid) {
      await tryAddDir(() => getExternalStorageDirectory());
      await tryAddDir(
        () async => Directory('/storage/emulated/0/Download'),
      );
    }

    // 2. Application Documents Directory
    await tryAddDir(() => getApplicationDocumentsDirectory());

    // 3. Fallback to system temp (also used during unit tests)
    if (files.isEmpty) {
      await tryAddDir(() async => Directory.systemTemp);
    }

    _targetFiles = files;
    return files;
  }

  /// Reads the full `.txt` log content from disk (or memory buffer fallback).
  static Future<String> readFullLogText() async {
    try {
      await _writeChain;
      final files = await _resolveTargetFiles();
      for (final file in files) {
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.trim().isNotEmpty) return content;
        }
      }
    } catch (_) {}
    return _entries.join('\n');
  }

  /// Clears both the on-disk `.txt` files and in-memory log buffer.
  static Future<void> clear() async {
    _entries.clear();
    try {
      await _writeChain;
      final files = await _resolveTargetFiles();
      for (final file in files) {
        try {
          await file.writeAsString(
            '=== Log Cleared at ${DateTime.now().toIso8601String()} ===\n',
            mode: FileMode.write,
            flush: true,
          );
        } catch (_) {}
      }
    } catch (_) {}
  }
}

/// Compact AppBar / Floating button that opens the on-device `.txt` log viewer.
class MvDebugLogIconButton extends StatelessWidget {
  final String? appTag;
  final Color? iconColor;

  const MvDebugLogIconButton({
    super.key,
    this.appTag,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (appTag != null) {
      MvDebugLogger.setAppTag(appTag!);
    }
    return IconButton(
      tooltip: 'Multi-Vendor Debug Log (.txt)',
      icon: Icon(
        Icons.bug_report_outlined,
        color: iconColor ?? Colors.orangeAccent,
      ),
      onPressed: () => showMvDebugLogSheet(context),
    );
  }
}

Future<void> showMvDebugLogSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _MvDebugLogSheetContent(),
  );
}

class _MvDebugLogSheetContent extends StatefulWidget {
  const _MvDebugLogSheetContent();

  @override
  State<_MvDebugLogSheetContent> createState() =>
      _MvDebugLogSheetContentState();
}

class _MvDebugLogSheetContentState extends State<_MvDebugLogSheetContent> {
  String _logText = 'Loading otlob_mv_debug_trace.txt...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final text = await MvDebugLogger.readFullLogText();
    if (!mounted) return;
    setState(() {
      _logText = text.isEmpty ? 'No logs recorded yet.' : text;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paths = MvDebugLogger.resolvedPaths;
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'otlob_mv_debug_trace.txt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _logText));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied full .txt log to clipboard'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16, color: Colors.greenAccent),
                  label: const Text(
                    'Copy .txt',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await MvDebugLogger.clear();
                    await _reload();
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (paths.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  'Saved on phone at:\n${paths.join('\n')}',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: SelectableText(
                          _logText,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
