import "package:shared_preferences/shared_preferences.dart";
class SharePrefsService{
  static SharedPreferences _prefs;

  static init() async{
    _prefs = await SharedPreferences.getInstance();
  }

  static setItem(String key, String value){
    _prefs.setString(key, value);
  }
  static String getItem(String key){
    return _prefs.getString(key);
  }

  static void removeItem(String key) {
    _prefs.remove(key);
  }
}