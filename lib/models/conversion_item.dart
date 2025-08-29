import 'package:hive/hive.dart';

part 'conversion_item.g.dart'; // for Hive type adapter

@HiveType(typeId: 0)
class ConversionItem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String imagePath;

  @HiveField(2)
  late String recognizedText;

  @HiveField(3)
  late String title;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late DateTime lastModified;
}
