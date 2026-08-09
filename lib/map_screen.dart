import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/auth_service.dart';
import 'user_model.dart';
import 'user_role.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final AuthService _authService = AuthService();
  late GoogleMapController _mapController;
  
  // ---------- Theme Constants ----------
  static const Color _primary = Color(0xFF1565C0);
  static const Color _primaryDark = Color(0xFF0D47A1);
  static const Color _lightBg = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFE3F2FD);
  static const Color _textDark = Color(0xFF1A237E);

  UserModel? get _currentUser => _authService.getCurrentUser();
  String get _role => _currentUser?.role.name ?? 'student';

  final LatLng _campusCenter = const LatLng(19.1383, 77.3210);
  final String _mapStyle = '[]'; // Add custom map style here if needed

  int _selectedCategoryIndex = 0;
  String _searchQuery = "";
  Map<String, dynamic>? _selectedLocation;

  final List<String> _categories = [
    "All", "Academic", "Administration", "Facilities", "Labs", "Sports", "Restricted"
  ];

  // ---------- Dummy Campus Data ----------
  final List<Map<String, dynamic>> _allLocations = [
    // Academic
    {"id": "acad_a", "name": "Academic Block A", "icon": Icons.school_outlined, "category": "Academic", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1383, 77.3210), "floors": 4, "desc": "Main classrooms for CSE & IT.", "emergency": false},
    {"id": "acad_b", "name": "Academic Block B", "icon": Icons.school_outlined, "category": "Academic", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1385, 77.3212), "floors": 3, "desc": "Classrooms for Mechanical & Civil.", "emergency": false},
    {"id": "exam_hall", "name": "Exam Hall", "icon": Icons.edit_note_outlined, "category": "Academic", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1384, 77.3208), "floors": 1, "desc": "Central examination hall.", "emergency": false},
    
    // Administration
    {"id": "admin", "name": "Admin Block", "icon": Icons.apartment_outlined, "category": "Administration", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1387, 77.3211), "floors": 2, "desc": "Administrative office & principal's cabin.", "emergency": false},
    {"id": "hod_office", "name": "HOD Office", "icon": Icons.chair_alt_outlined, "category": "Administration", "roles": ["teacher", "hod", "principal"], "point": const LatLng(19.1386, 77.3210), "floors": 1, "desc": "Head of Department cabins.", "emergency": false},
    {"id": "staff_room", "name": "Staff Room", "icon": Icons.groups_outlined, "category": "Administration", "roles": ["teacher", "hod", "principal"], "point": const LatLng(19.1388, 77.3213), "floors": 1, "desc": "Faculty common room.", "emergency": false},
    
    // Facilities
    {"id": "library", "name": "Central Library", "icon": Icons.menu_book_outlined, "category": "Facilities", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1385, 77.3215), "floors": 3, "desc": "Study halls & reading rooms.", "emergency": false},
    {"id": "canteen", "name": "Canteen", "icon": Icons.restaurant_outlined, "category": "Facilities", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1386, 77.3213), "floors": 1, "desc": "Campus food court.", "emergency": false},
    {"id": "medical", "name": "Medical Room", "icon": Icons.local_hospital_outlined, "category": "Facilities", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1382, 77.3209), "floors": 1, "desc": "First aid & medical assistance.", "emergency": true},
    
    // Labs
    {"id": "comp_lab", "name": "Computer Lab", "icon": Icons.computer_outlined, "category": "Labs", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1391, 77.3214), "floors": 2, "desc": "High-speed internet labs.", "emergency": false},
    {"id": "chem_lab", "name": "Chemistry Lab", "icon": Icons.science_outlined, "category": "Labs", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1389, 77.3209), "floors": 1, "desc": "Chemistry practical labs.", "emergency": true},
    
    // Sports
    {"id": "sports", "name": "Sports Ground", "icon": Icons.sports_soccer_outlined, "category": "Sports", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.1378, 77.3216), "floors": 0, "desc": "Outdoor sports arena.", "emergency": false},
    
    // Restricted (Principal/Security)
    {"id": "server", "name": "Server Room", "icon": Icons.dns_outlined, "category": "Restricted", "roles": ["principal"], "point": const LatLng(19.13875, 77.32115), "floors": 1, "desc": "Main campus server infrastructure.", "emergency": true},
    {"id": "security", "name": "Security Office", "icon": Icons.security_outlined, "category": "Restricted", "roles": ["principal"], "point": const LatLng(19.1382, 77.3215), "floors": 1, "desc": "Campus security & CCTV control.", "emergency": true},
  ];

  List<Map<String, dynamic>> get _visibleLocations {
    return _allLocations.where((loc) {
      // Role Filter
      bool hasRoleAccess = (loc['roles'] as List).contains(_role);
      if (!hasRoleAccess) return false;

      // Category Filter
      if (_selectedCategoryIndex != 0 && loc['category'] != _categories[_selectedCategoryIndex]) {
        return false;
      }

      // Search Filter
      if (_searchQuery.isNotEmpty) {
        return (loc['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return true;
    }).toList();
  }

  Set<Marker> _buildMarkers() {
    return _visibleLocations.map((loc) {
      final bool isSelected = _selectedLocation != null && _selectedLocation!['id'] == loc['id'];
      return Marker(
        markerId: MarkerId(loc['id'] as String),
        position: loc['point'] as LatLng,
        infoWindow: InfoWindow(title: loc['name'] as String, snippet: loc['desc'] as String),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          loc['emergency'] == true ? BitmapDescriptor.hueRed : (isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueAzure),
        ),
        onTap: () {
          setState(() => _selectedLocation = loc);
          _mapController.animateCamera(CameraUpdate.newLatLng(loc['point'] as LatLng));
        },
      );
    }).toSet();
  }

  void _goToCurrentLocation() {
    // Dummy Current Location
    _mapController.animateCamera(CameraUpdate.newLatLngZoom(const LatLng(19.1383, 77.3210), 18));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: Stack(
        children: [
          // ---------------- MAP ----------------
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _campusCenter, zoom: 17),
            markers: _buildMarkers(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            padding:EdgeInsets.only(top: 140, bottom: _selectedLocation != null ? 280 : 120),
            onMapCreated: (controller) {
              _mapController = controller;
              // controller.setMapStyle(_mapStyle); // Uncomment if using custom style
            },
            onTap: (_) => setState(() => _selectedLocation = null),
          ),

          // ---------------- TOP UI (Search & Categories) ----------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _lightBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Search buildings, rooms...",
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: _primary),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune_rounded, color: Colors.grey),
                            onPressed: () {},
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Categories
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          bool isSelected = _selectedCategoryIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategoryIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected ? const LinearGradient(colors: [_primaryDark, _primary]) : null,
                                color: isSelected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                              ),
                              child: Center(
                                child: Text(
                                  _categories[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : _textDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------------- FLOATING ACTION BUTTONS ----------------
          Positioned(
            right: 16,
            bottom: _selectedLocation != null ? 300 : 140,
            child: Column(
              children: [
                _buildFAB(Icons.add, () => _mapController.animateCamera(CameraUpdate.zoomIn())),
                const SizedBox(height: 10),
                _buildFAB(Icons.remove, () => _mapController.animateCamera(CameraUpdate.zoomOut())),
                const SizedBox(height: 10),
                _buildFAB(Icons.my_location, _goToCurrentLocation, isPrimary: true),
              ],
            ),
          ),

          // ---------------- BOTTOM LIST / DETAILS ----------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _selectedLocation == null ? _buildLocationList() : _buildLocationDetails(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  WIDGETS
  // ============================================================

  Widget _buildFAB(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return Material(
      color: isPrimary ? _primary : Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: isPrimary ? Colors.white : _primary, size: 20),
        ),
      ),
    );
  }

  Widget _buildLocationList() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_searchQuery.isEmpty ? "Quick Access" : "Search Results", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
              Text("${_visibleLocations.length} Locations", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: _visibleLocations.isEmpty 
              ? Center(child: Text("No locations found.", style: TextStyle(color: Colors.grey.shade400)))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _visibleLocations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final loc = _visibleLocations[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedLocation = loc);
                        _mapController.animateCamera(CameraUpdate.newLatLngZoom(loc['point'] as LatLng, 18));
                      },
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _lightBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _softBlue, width: 1.2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(loc['icon'] as IconData, color: _primary, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              loc['name'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _textDark),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetails() {
    final loc = _selectedLocation!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(loc['icon'] as IconData, color: _primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc['name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textDark)),
                    Text(loc['category'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (loc['emergency'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text("SOS", style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w900)),
                )
            ],
          ),
          const SizedBox(height: 14),
          Text(loc['desc'] as String, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
          const SizedBox(height: 16),
          
          // Floor Selector UI
          if ((loc['floors'] as int) > 0) ...[
            const Text("Select Floor", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _textDark)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (loc['floors'] as int) + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  String floorName = index == 0 ? "G" : "$index";
                  bool isSelected = index == 0; // Dummy logic
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : _lightBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Text(
                        floorName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : _textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedLocation = null),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Close", style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Calculating route... (UI Ready)")),
                    );
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text("Navigate", style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}