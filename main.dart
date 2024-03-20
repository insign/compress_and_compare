import 'compression_comparator.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('Please provide a folder path as an argument.');
    return;
  }

  String folderPath = arguments[0];
  CompressionComparator comparator = CompressionComparator();

  comparator.compareCompression(folderPath);
}
