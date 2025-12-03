// lib/models/setting.dart
import 'package:hive/hive.dart';

part 'setting.g.dart';

@HiveType(typeId: 3)
class Setting extends HiveObject {
  @HiveField(0)
  String theme; // 'light' or 'dark'

  @HiveField(1)
  String currency; // e.g., 'MMK', '$', '€'

  Setting({
    this.theme = 'light',
    this.currency = 'MMK',
  });
}
