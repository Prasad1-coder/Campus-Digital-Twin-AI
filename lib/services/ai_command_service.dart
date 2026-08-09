import 'package:flutter/material.dart';
import '../user_role.dart'; // 👈 FIX: Added missing import for UserRole
import '../attendance_screen.dart';
import '../library_screen.dart';
import '../timetable_screen.dart';
import '../map_screen.dart';
import '../notice_screen.dart';
import '../events_screen.dart';
import '../digital_id_screen.dart';
import '../profile_screen.dart';

/// AICommandService detects navigation-intent commands typed by the user
/// and routes them to the correct screen, bypassing the Gemini API call.
class AICommandService {
  AICommandService._(); // prevent instantiation

  // 👇 Command keyword groups - order matters (checked top to bottom)
  static final Map<String, List<String>> _commandKeywords = {
    "attendance": ["attendance"],
    "library": ["library", "book"],
    "timetable": ["timetable", "time table", "schedule", "class today"],
    "map": ["campus map", "open map", "show map", "college map"],
    "notice": ["notice", "announcement"],
    "events": ["event", "events"],
    "digital_id": ["digital id", "id card", "my id"],
    "profile": ["profile", "my details"],
  };

  /// Returns true if [text] matches a known navigation command.
  /// Call this BEFORE sending the message to Gemini.
  static bool isCommand(String text) {
    return _matchCommandKey(text) != null;
  }

  /// Returns a short confirmation message for the matched command,
  /// e.g. "📚 Opening Library...". Show this in chat before navigating.
  static String getResponseMessage(String text) {
    final key = _matchCommandKey(text);
    switch (key) {
      case "attendance":
        return "✅ Opening Attendance...";
      case "library":
        return "📚 Opening Library...";
      case "timetable":
        return "🗓️ Opening Timetable...";
      case "map":
        return "🗺️ Opening Campus Map...";
      case "notice":
        return "📢 Opening Notice Board...";
      case "events":
        return "🎉 Opening Events...";
      case "digital_id":
        return "🪪 Opening Digital ID...";
      case "profile":
        return "👤 Opening Profile...";
      default:
        return "Opening...";
    }
  }

  /// Executes navigation for the matched command found in [message].
  /// Pass [userRole] and [currentUserName] from the calling screen
  /// (defaults to Student / "Prasad" if not provided).
  static void executeCommand(
    BuildContext context,
    String message, {
    UserRole userRole = UserRole.student,
    String currentUserName = "Prasad",
  }) {
    final key = _matchCommandKey(message);

    switch (key) {
      case "attendance":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceScreen(
              userRole: userRole,
              currentUserName: currentUserName,
            ),
          ),
        );
        return;

      case "library":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LibraryScreen()),
        );
        return;

      case "timetable":
        Navigator.push(
          // 👈 FIX: Added userRole parameter to TimetableScreen
          context,
          MaterialPageRoute(builder: (_) => TimetableScreen(userRole: userRole)),
        );
        return;

      case "map":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
        return;

      case "notice":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoticeScreen(userRole: userRole)),
        );
        return;

      case "events":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventsScreen(
              userRole: userRole,
              currentUserName: currentUserName,
            ),
          ),
        );
        return;

      case "digital_id":
        Navigator.push(
          // 👈 FIX: Removed userRole parameter because DigitalIdScreen now fetches it from AuthService
          context,
          MaterialPageRoute(builder: (_) => const DigitalIdScreen()),
        );
        return;

      case "profile":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(role: userRole)),
        );
        return;

      default:
        // Ye case normally kabhi nahi aayega kyunki isCommand() pehle
        // check ho chuka hota hai, lekin safety ke liye rakha hai.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sorry, I didn't understand that command.")),
        );
    }
  }

  /// Internal: matches [text] against keyword groups.
  /// Case-insensitive, "contains" match so natural phrasing works
  /// (e.g. "please open the library" still matches "library").
  static String? _matchCommandKey(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty) return null;

    for (final entry in _commandKeywords.entries) {
      for (final phrase in entry.value) {
        if (normalized.contains(phrase)) {
          return entry.key;
        }
      }
    }
    return null;
  }
}