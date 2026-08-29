class DriverSession {
  static String? busNumber;

  static bool get isLoggedIn => busNumber != null && busNumber!.isNotEmpty;

  static void login(String value) {
    busNumber = value;
  }

  static void logout() {
    busNumber = null;
  }
}
