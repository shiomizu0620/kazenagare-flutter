import 'package:shared_preferences/shared_preferences.dart';

class GardenSetupLocalData {
  final String? name;
  final String? seasonId;

  const GardenSetupLocalData({this.name, this.seasonId});
}

class GardenSetupLocalStorage {
  static const String _prefsKeyName = 'setup.garden.name';
  static const String _prefsKeySeasonId = 'setup.garden.seasonId';

  Future<GardenSetupLocalData> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GardenSetupLocalData(
      name: prefs.getString(_prefsKeyName),
      seasonId: prefs.getString(_prefsKeySeasonId),
    );
  }

  Future<void> save({required String name, required String seasonId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyName, name.trim());
    await prefs.setString(_prefsKeySeasonId, seasonId);
  }
}
