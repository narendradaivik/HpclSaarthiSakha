import 'dart:convert';
import 'package:flutter/services.dart';

class AppData {
  static Map<String, dynamic>? _data;

  static Future<void> load() async {
    final String jsonString = await rootBundle.loadString('assets/data.json');
    _data = jsonDecode(jsonString);
  }

  static Map<String, dynamic> get user => _data?['user'] ?? {};
  static String get otp => _data?['otp'] ?? '123456';
  static List<dynamic> get rewardsCatalog => _data?['rewards_catalog'] ?? [];
  static List<dynamic> get redeemRequests => _data?['redeem_requests'] ?? [];
  static List<dynamic> get fuelClaims => _data?['fuel_claims'] ?? [];
  static List<dynamic> get outlets => _data?['outlets'] ?? [];
}

// For hardcoded mock data (no asset loading needed)
class MockData {
  static const String validPhone = '9876543210';
  static const String validOtp = '123456';

  static Map<String, dynamic> user = {
    "id": "USR001",
    "name": "Rajesh Kumar",
    "phone": "9876543210",
    "truck_number": "RJ-14-AB-1234",
    "level": "Level 2 — Bronze",
    "member_since": "December 2025",
    "total_points": 16750,
    "redeemable_points": 9750,
    "liters_filled": 16750,
    "transactions": 48,
  };

  static List<Map<String, dynamic>> rewardsCatalog = [
    {
      "id": "R001",
      "name": "T-Shirt",
      "name_hi": "टी-शर्ट",
      "points": 300,
      "icon": "👕",
    },
    {
      "id": "R002",
      "name": "Wall Clock",
      "name_hi": "दीवार घड़ी",
      "points": 500,
      "icon": "🕐",
    },
    {
      "id": "R003",
      "name": "Shopping Voucher",
      "name_hi": "शॉपिंग वाउचर",
      "points": 800,
      "icon": "🛍️",
    },
    {
      "id": "R004",
      "name": "Pressure Cooker",
      "name_hi": "प्रेशर कुकर",
      "points": 1000,
      "icon": "🍳",
    },
    {
      "id": "R005",
      "name": "Dinner Set",
      "name_hi": "डिनर सेट",
      "points": 1500,
      "icon": "🍽️",
    },
    {
      "id": "R006",
      "name": "Headphones",
      "name_hi": "हेडफ़ोन",
      "points": 2000,
      "icon": "🎧",
    },
    {
      "id": "R007",
      "name": "Radio",
      "name_hi": "रेडियो",
      "points": 2000,
      "icon": "📻",
    },
    {
      "id": "R008",
      "name": "Table Fan",
      "name_hi": "टेबल फ़ैन",
      "points": 2500,
      "icon": "🌀",
    },
    {
      "id": "R009",
      "name": "Smart Watch",
      "name_hi": "स्मार्ट वॉच",
      "points": 3000,
      "icon": "⌚",
    },
    {
      "id": "R010",
      "name": "Mobile Phone",
      "name_hi": "मोबाइल फ़ोन",
      "points": 5000,
      "icon": "📱",
    },
  ];

  static List<Map<String, dynamic>> redeemRequests = [
    {
      "id": "RR001",
      "reward_name": "टी-शर्ट",
      "reward_en": "T-Shirt",
      "date": "12 फ़रवरी 2026",
      "points": 300,
      "status": "delivered",
      "status_hi": "डिलीवर हो गया",
      "delivery_date": "12 फ़रवरी 2026",
      "outlet": "HPCL पंप, NH-44, KM 120, दिल्ली",
    },
    {
      "id": "RR002",
      "reward_name": "दीवार घड़ी",
      "reward_en": "Wall Clock",
      "date": "15 फ़रवरी 2026",
      "points": 500,
      "status": "processing",
      "status_hi": "प्रोसेसिंग",
      "ready_date": "20 फ़रवरी 2026",
      "ready_in_days": 5,
      "outlet": "HPCL पंप, NH-48, KM 85, जयपुर",
    },
    {
      "id": "RR003",
      "reward_name": "प्रेशर कुकर",
      "reward_en": "Pressure Cooker",
      "date": "18 फ़रवरी 2026",
      "points": 1000,
      "status": "pending",
      "status_hi": "पेंडिंग",
      "ready_date": "26 फ़रवरी 2026",
      "ready_in_days": 8,
      "outlet": "HPCL पंप, NH-8, KM 200, अहमदाबाद",
    },
  ];

  static List<Map<String, dynamic>> fuelClaims = [
    {
      "fuel_type": "डीज़ल",
      "liters": 380,
      "outlet": "HPCL Rajasthan Fuel Hub • NH-48",
      "date": "19 दिसं 2025",
      "amount": 36100,
      "status": "pending",
    },
    {
      "fuel_type": "डीज़ल",
      "liters": 350,
      "outlet": "HPCL Highway Outlet • NH44",
      "date": "18 दिसं 2025",
      "amount": 33250,
      "status": "verified",
    },
    {
      "fuel_type": "डीज़ल",
      "liters": 420,
      "outlet": "HPCL Rajasthan Fuel Hub • NH-48",
      "date": "17 दिसं 2025",
      "amount": 39900,
      "status": "pending",
    },
  ];

  static List<Map<String, dynamic>> outlets = [
    {
      "id": "O001",
      "name": "HPCL Highway Station",
      "highway": "NH44",
      "km": "KM 312",
      "lat": 28.60289999999999,
      "lng": 77.35870624999998,
    },
    {
      "id": "O002",
      "name": "HPCL Dhabha Point",
      "highway": "NH44",
      "km": "KM 356",
      "lat": 28.6100,
      "lng": 77.3650,
    },
    {
      "id": "O003",
      "name": "HPCL Express Fuel",
      "highway": "NH48",
      "km": "KM 89",
      "lat": 28.6200,
      "lng": 77.3720,
    },
    {
      "id": "O004",
      "name": "HPCL Highway Hub",
      "highway": "NH27",
      "km": "KM 156",
      "lat": 28.6300,
      "lng": 77.3800,
    },
    {
      "id": "O005",
      "name": "HPCL Rajasthan Fuel Hub",
      "highway": "NH-48",
      "km": "KM 245",
      "lat": 28.6400,
      "lng": 77.3900,
    },
    {
      "id": "O006",
      "name": "HPCL Gujarat Express",
      "highway": "NH-48",
      "km": "KM 380",
      "lat": 28.6500,
      "lng": 77.4000,
    },
    {
      "id": "O007",
      "name": "HPCL Maharashtra Pride",
      "highway": "NH-48",
      "km": "KM 520",
      "lat": 28.6600,
      "lng": 77.4100,
    },
  ];
}
