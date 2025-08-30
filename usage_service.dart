// lib/services/usage_service.dart
import 'dart:convert';
import 'package:usage_stats/usage_stats.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class UsageService {
  UsageService._();
  static final instance = UsageService._();

  
  Future<List<Map<String, dynamic>>> collectUsage(String researchId) async {
  DateTime endDate = DateTime.now();
  DateTime startDate = endDate.subtract(const Duration(hours: 24));

  // Ask permission if not granted
  bool granted = await UsageStats.checkUsagePermission() ?? false;
  if (!granted) {
    await UsageStats.grantUsagePermission();
    granted = await UsageStats.checkUsagePermission() ?? false;
    if (!granted) {
      throw Exception("Usage access not granted by user");
    }
  }

  List<UsageInfo> usageInfo =
      await UsageStats.queryUsageStats(startDate, endDate);

  return usageInfo.map((u) {
    return {
      "researchId": researchId,
      "packageName": u.packageName,
      "totalTimeInForeground": u.totalTimeInForeground,
      "lastTimeUsed": u.lastTimeUsed,
    };
  }).toList();
}
  

  
  Future<bool> sendUsageLogs(String researchId) async {
    final usageLogs = await collectUsage(researchId);

    if (usageLogs.isEmpty) return false;

    final url = "${ApiService.baseUrl}/api/v1/user/usage";
    final response = await http.post(
      Uri.parse(url),
      headers: ApiService.instance.headers,
      body: jsonEncode(usageLogs), // backend expects array, not wrapped in object
    );

    if (response.statusCode == 201) {
      print("Usage logs sent successfully");
      return true;
    } else {
      print("Failed to send usage logs: ${response.body}");
      return false;
    }
  }
}