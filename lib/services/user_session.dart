/// Global singleton that stores live data from driver_stats API.
/// Populated once after successful login / dashboard load.
/// Screens that need redeemable points (catalog, profile, etc.) read from here.
class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  double redeemableLiters = 0;
  double totalLiters = 0;
  int totalTransactions = 0;
  String driverName = '';
  String driverPhone = '';
  String truckNumber = '';
  String memberSince = '';
  int currentLevel = 1;
  bool isLoaded = false;

  /// The outlet UUID most recently selected by the driver (outlet_selection_screen).
  /// Used as outlet_id when submitting a fuel claim.
  String? selectedOutletId;
  String? selectedOutletName;

  void update({
    required double redeemableLiters,
    required double totalLiters,
    required int totalTransactions,
    required String driverName,
    required String driverPhone,
    required int currentLevel,
    String truckNumber = '',
    String memberSince = '',
  }) {
    this.redeemableLiters = redeemableLiters;
    this.totalLiters = totalLiters;
    this.totalTransactions = totalTransactions;
    this.driverName = driverName;
    this.driverPhone = driverPhone;
    this.currentLevel = currentLevel;
    this.truckNumber = truckNumber;
    this.memberSince = memberSince;
    isLoaded = true;
  }

  /// Call this when a driver selects an outlet (outlet_selection_screen).
  void setOutlet({required String outletId, required String outletName}) {
    selectedOutletId = outletId;
    selectedOutletName = outletName;
  }

  void clear() {
    redeemableLiters = 0;
    totalLiters = 0;
    totalTransactions = 0;
    driverName = '';
    driverPhone = '';
    truckNumber = '';
    memberSince = '';
    currentLevel = 1;
    isLoaded = false;
  }

  String get levelLabel {
    switch (currentLevel) {
      case 1:
        return 'Level 1 — ब्रॉन्ज़';
      case 2:
        return 'Level 2 — सिल्वर';
      case 3:
        return 'Level 3 — गोल्ड';
      default:
        return 'Level $currentLevel';
    }
  }
}
