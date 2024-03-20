import 'dart:io';
import 'dart:math';

import 'package:chalkdart/chalk.dart';
import 'package:process_run/shell.dart';

class CompressionResult {
  final String format;
  final int originalSize;
  final int compressedSize;
  final double ratio;
  final double duration;

  CompressionResult({
    required this.format,
    required this.originalSize,
    required this.compressedSize,
    required this.ratio,
    required this.duration,
  });
}

class CompressionComparator {
  static const List<String> defaultFormats = [
    'zip',
    'bzip2',
    'lzma2',
    'lz4',
    'lz5',
    'zstd',
  ];

  Future<void> compareCompression(String folderPath,
      {List<String>? formats}) async {
    formats ??= defaultFormats;

    if (!await Directory(folderPath).exists()) {
      print('The folder $folderPath does not exist.');
      return;
    }

    int originalSize = await calculateFolderSize(folderPath);
    List<CompressionResult> results = [];

    for (String level in ['min', 'normal', 'max']) {
      for (String format in formats) {
        results.add(await compressFolder(folderPath, level, format, originalSize));
      }
    }

    displayResults(results);
  }

  Future<CompressionResult> compressFolder(
      String folderPath, String level, String format, int originalSize) async {
    String compressedFilename = '$level.$format.7z';

    File compressedFile = File(compressedFilename);
    if (await compressedFile.exists()) await compressedFile.delete();

    Stopwatch stopwatch = Stopwatch()..start();
    await executeCompression(folderPath, compressedFilename, level, format);
    stopwatch.stop();

    int compressedSize = await getFileSize(compressedFile);

    if (await compressedFile.exists()) await compressedFile.delete();

    return CompressionResult(
      format: '$level.$format',
      originalSize: originalSize,
      compressedSize: compressedSize,
      ratio: compressedSize / originalSize * 100,
      duration: stopwatch.elapsedMilliseconds / 1000,
    );
  }

  Future<void> executeCompression(String folderPath, String compressedFile,
      String level, String format) async {
    final shell = Shell();

    String command = '7z a';
    if (format == 'zip') {
      command += ' -t$format';
      command += level == 'min' ? ' -mx=1' : (level == 'max' ? ' -mx=9' : '');
    } else {
      command += ' -t7z -m0="$format"';
      command += level == 'min' ? ' -mx=1' : (level == 'max' ? ' -mx=9' : '');
      if (format == 'zstd' && level == 'max') command += ' -mx=22';
    }
    command += ' "$compressedFile" "$folderPath"';

    await shell.run(command);
  }

  Future<int> calculateFolderSize(String path) async {
    int totalSize = 0;
    final dir = Directory(path);

    if (await dir.exists()) {
      await for (FileSystemEntity entity in dir.list(recursive: true)) {
        if (entity is File) totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  Future<int> getFileSize(File file) async => await file.exists() ? await file.length() : 0;

  String formatSize(int bytes) {
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  void displayResults(List<CompressionResult> results) {
    String header = 'Format'.padRight(14) +
        'Original'.padRight(11) +
        'Compressed'.padRight(14) +
        'Ratio'.padRight(8) +
        'Seconds'.padLeft(7);
    print(chalk.bold(header));

    int index = 0;
    for (var result in results) {
      String line = formatResult(result, results);
      print(index++ % 2 == 0 ? chalk.bgGrey(line) : line);
    }

    printBreakdown(results);
  }

  String formatResult(CompressionResult result, List<CompressionResult> results) {
    String format = result.format.padRight(12);
    String originalSize = formatSize(result.originalSize).padLeft(8);
    String compressedSize = formatSize(result.compressedSize).padLeft(13);
    String ratio = result.ratio.toStringAsFixed(0).padLeft(6);
    String duration = result.duration.toStringAsFixed(2).padLeft(9);

    originalSize = colorizeValue(result.compressedSize, results.map((r) => r.compressedSize), originalSize);
    compressedSize = colorizeValue(result.compressedSize, results.map((r) => r.compressedSize), compressedSize);
    ratio = colorizeValue(result.ratio, results.map((r) => r.ratio), ratio);
    duration = colorizeValue(result.duration, results.map((r) => r.duration), duration);

    return '${chalk.cyan(format)} $originalSize $compressedSize $ratio% ${duration}s';
  }

  String colorizeValue(num value, Iterable<num> values, String formattedValue) {
    num minValue = values.reduce(min);
    num maxValue = values.reduce(max);

    if (value == minValue) {
      return chalk.green(formattedValue);
    } else if (value == maxValue) {
      return chalk.red(formattedValue);
    } else {
      return formattedValue;
    }
  }

  void printBreakdown(List<CompressionResult> results) {
    print('');
    print('');

    String fastest = findExtreme(results, (a, b) => a.duration.compareTo(b.duration), (r) => r.format);
    double fastestTime = findExtreme(results, (a, b) => a.duration.compareTo(b.duration), (r) => r.duration);

    String slowest = findExtreme(results, (a, b) => b.duration.compareTo(a.duration), (r) => r.format);
    double slowestTime = findExtreme(results, (a, b) => b.duration.compareTo(a.duration), (r) => r.duration);

    String bestRatio = findExtreme(results, (a, b) => a.ratio.compareTo(b.ratio), (r) => r.format);
    double bestRatioValue = findExtreme(results, (a, b) => a.ratio.compareTo(b.ratio), (r) => r.ratio);

    String worstRatio = findExtreme(results, (a, b) => b.ratio.compareTo(a.ratio), (r) => r.format);
    double worstRatioValue = findExtreme(results, (a, b) => b.ratio.compareTo(a.ratio), (r) => r.ratio);

    String smallest = findExtreme(results, (a, b) => a.compressedSize.compareTo(b.compressedSize), (r) => r.format);
    String smallestSize = formatSize(findExtreme(results, (a, b) => a.compressedSize.compareTo(b.compressedSize), (r) => r.compressedSize));

    String biggest = findExtreme(results, (a, b) => b.compressedSize.compareTo(a.compressedSize), (r) => r.format);
    String biggestSize = formatSize(findExtreme(results, (a, b) => b.compressedSize.compareTo(a.compressedSize), (r) => r.compressedSize));

    print(chalk.green('Fastest: $fastest (${fastestTime.toStringAsFixed(2)}s)'));
    print(chalk.red('Slowest: $slowest (${slowestTime.toStringAsFixed(2)}s)'));
    print(chalk.green('Best ratio: $bestRatio (${bestRatioValue.toStringAsFixed(2)}%)'));
    print(chalk.red('Worst ratio: $worstRatio (${worstRatioValue.toStringAsFixed(2)}%)'));
    print(chalk.green('Smallest final size: $smallest ($smallestSize)'));
    print(chalk.red('Biggest final size: $biggest ($biggestSize)'));
  }

  T findExtreme<T>(List<CompressionResult> results, Comparator<CompressionResult> comparator, T Function(CompressionResult) selector) {
    results.sort(comparator);
    return selector(results.first);
  }
}
