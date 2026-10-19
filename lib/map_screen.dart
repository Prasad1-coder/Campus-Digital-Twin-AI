import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/auth_service.dart';
import 'user_model.dart';

// ---------- Same colour palette (unchanged) ----------
const Color _primary = Color(0xFF1565C0);
const Color _primaryDark = Color(0xFF0D47A1);
const Color _accent = Color(0xFF42A5F5);
const Color _lightBg = Color(0xFFF5F9FF);
const Color _softBlue = Color(0xFFE3F2FD);
const Color _textDark = Color(0xFF1A237E);

// Helpers so light + dark mode both look good
Color _tintOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _primary.withOpacity(0.20) : _softBlue;

Color _iconOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? _accent : _primary;

Color _headingOf(ThemeData theme) =>
    theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : _textDark;

// Department photos follow this naming:  assets/campus/departments/<id>_1.jpg, _2.jpg, _3.jpg
List<String> _deptImages(String id) =>
    List.generate(3, (i) => 'assets/campus/departments/${id}_${i + 1}.jpg');

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // =====================================================================
  // 1. STATE
  // =====================================================================
  final AuthService _authService = AuthService();
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  UserModel? get _currentUser => _authService.getCurrentUser();
  String get _role => _currentUser?.role.name ?? 'student';

  // Science College Nanded reference: 19°10′29″ N, 77°18′01″ E (≈ 19.17472, 77.30028).
  // Building-level points below are app-level campus markers and should be refined with verified survey/GPS points later.
  final LatLng _campusCenter = const LatLng(19.17472, 77.30028);

  // Corner points of the campus. Replace with your real corners:
  // Google Maps -> long-press on the campus corner -> copy the coordinates.
  final List<LatLng> _campusBoundary = const [
    LatLng(19.17582, 77.29968),
    LatLng(19.17582, 77.30128),
    LatLng(19.17382, 77.30128),
    LatLng(19.17382, 77.29968),
  ];

  MapType _mapType = MapType.hybrid; // satellite + labels = you can actually SEE the college
  int _selectedCategoryIndex = 0;
  String _searchQuery = "";
  int _tab = 0; // 0 = Places, 1 = Departments, 2 = Gallery
  Map<String, dynamic>? _selectedLocation;
  Map<String, dynamic>? _selectedDepartment;
  int _selectedFloor = 0;
  int _photoIndex = 0;

  double _sheetExtent = 0.30; // how high the bottom sheet is (0..1)
  bool _extentUpdateScheduled = false;

  final List<String> _categories = [
    "All", "Academic", "Administration", "Facilities", "Labs", "Sports", "Restricted"
  ];

  // =====================================================================
  // 2. DATA  (dummy campus data - replace with your real data)
  //    Location cover photo:  assets/campus/locations/<id>.jpg
  // =====================================================================
  final List<Map<String, dynamic>> _allLocations = [
    // Academic
    {"id": "acad_a", "name": "Academic Block A", "icon": Icons.school_outlined, "category": "Academic", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17472, 77.30028), "floors": 4, "desc": "Main classrooms for CSE & IT.", "emergency": false},
    {"id": "acad_b", "name": "Academic Block B", "icon": Icons.school_outlined, "category": "Academic", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17492, 77.30048), "floors": 3, "desc": "Classrooms for Mechanical & Civil.", "emergency": false},
    {"id": "elec_block", "name": "Electrical Block", "icon": Icons.electrical_services_outlined, "category": "Academic", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17452, 77.30048), "floors": 2, "desc": "Electrical classrooms & machines lab.", "emergency": false},
    {"id": "exam_hall", "name": "Exam Hall", "icon": Icons.edit_note_outlined, "category": "Academic", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17482, 77.30008), "floors": 1, "desc": "Central examination hall.", "emergency": false},

    // Administration
    {"id": "admin", "name": "Admin Block", "icon": Icons.apartment_outlined, "category": "Administration", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17512, 77.30038), "floors": 2, "desc": "Administrative office & principal's cabin.", "emergency": false},
    {"id": "hod_office", "name": "HOD Office", "icon": Icons.chair_alt_outlined, "category": "Administration", "roles": ["teacher", "hod", "principal"], "point": const LatLng(19.17502, 77.30028), "floors": 1, "desc": "Head of Department cabins.", "emergency": false},
    {"id": "staff_room", "name": "Staff Room", "icon": Icons.groups_outlined, "category": "Administration", "roles": ["teacher", "hod", "principal"], "point": const LatLng(19.17522, 77.30058), "floors": 1, "desc": "Faculty common room.", "emergency": false},

    // Facilities
    {"id": "library", "name": "Central Library", "icon": Icons.menu_book_outlined, "category": "Facilities", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17492, 77.30078), "floors": 3, "desc": "Study halls & reading rooms.", "emergency": false},
    {"id": "canteen", "name": "Canteen", "icon": Icons.restaurant_outlined, "category": "Facilities", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17502, 77.30058), "floors": 1, "desc": "Campus food court.", "emergency": false},
    {"id": "medical", "name": "Medical Room", "icon": Icons.local_hospital_outlined, "category": "Facilities", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17462, 77.30018), "floors": 1, "desc": "First aid & medical assistance.", "emergency": true},

    // Labs
    {"id": "comp_lab", "name": "Computer Lab", "icon": Icons.computer_outlined, "category": "Labs", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17552, 77.30068), "floors": 2, "desc": "High-speed internet labs.", "emergency": false},
    {"id": "chem_lab", "name": "Chemistry Lab", "icon": Icons.science_outlined, "category": "Labs", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17532, 77.30018), "floors": 1, "desc": "Chemistry practical labs.", "emergency": true},

    // Sports
    {"id": "sports", "name": "Sports Ground", "icon": Icons.sports_soccer_outlined, "category": "Sports", "roles": ["student", "teacher", "hod", "principal"], "point": const LatLng(19.17422, 77.30088), "floors": 0, "desc": "Outdoor sports arena.", "emergency": false},

    // Restricted (Principal/Security)
    {"id": "server", "name": "Server Room", "icon": Icons.dns_outlined, "category": "Restricted", "roles": ["principal"], "point": const LatLng(19.17517, 77.30043), "floors": 1, "desc": "Main campus server infrastructure.", "emergency": true},
    {"id": "security", "name": "Security Office", "icon": Icons.security_outlined, "category": "Restricted", "roles": ["principal"], "point": const LatLng(19.17462, 77.30078), "floors": 1, "desc": "Campus security & CCTV control.", "emergency": true},
  ];

  // Departments (dummy numbers & names - replace with real ones)
  final List<Map<String, dynamic>> _departments = [
    {
      "id": "cse", "name": "Computer Engineering", "short": "CSE", "icon": Icons.computer_outlined, "color": Colors.blue,
      "locationId": "acad_a", "hod": "Dr. Sharma", "students": 480, "faculty": 24, "labs": 4,
      "about": "AI, app & web development with hands-on labs, hackathons and industry projects.",
      "facilities": ["Computer Lab", "AI Lab", "Project Lab", "Seminar Hall"],
      "images": _deptImages("cse"),
    },
    {
      "id": "it", "name": "Information Technology", "short": "IT", "icon": Icons.hub_outlined, "color": Colors.indigo,
      "locationId": "acad_a", "hod": "Prof. Singh", "students": 360, "faculty": 18, "labs": 3,
      "about": "Networks, cloud and cyber security with a strong placement record.",
      "facilities": ["Networking Lab", "Cyber Lab", "Smart Classroom"],
      "images": _deptImages("it"),
    },
    {
      "id": "mech", "name": "Mechanical Engineering", "short": "MECH", "icon": Icons.precision_manufacturing_outlined, "color": Colors.orange,
      "locationId": "acad_b", "hod": "Dr. Rao", "students": 300, "faculty": 20, "labs": 5,
      "about": "Design, thermal and manufacturing with a fully equipped workshop.",
      "facilities": ["Workshop", "CAD/CAM Lab", "Thermal Lab", "Fluid Lab"],
      "images": _deptImages("mech"),
    },
    {
      "id": "civil", "name": "Civil Engineering", "short": "CIVIL", "icon": Icons.foundation_outlined, "color": Colors.green,
      "locationId": "acad_b", "hod": "Dr. Mehta", "students": 240, "faculty": 16, "labs": 4,
      "about": "Structures, surveying and environment with live site visits.",
      "facilities": ["Survey Lab", "Concrete Lab", "Structural Lab"],
      "images": _deptImages("civil"),
    },
    {
      "id": "elec", "name": "Electrical Engineering", "short": "ELEC", "icon": Icons.bolt_outlined, "color": Colors.purple,
      "locationId": "elec_block", "hod": "Dr. Patil", "students": 260, "faculty": 17, "labs": 4,
      "about": "Power systems, machines and automation with modern labs.",
      "facilities": ["Machines Lab", "Power Systems Lab", "Automation Lab"],
      "images": _deptImages("elec"),
    },
  ];

  // Campus gallery (general photos of the college)
  final List<Map<String, dynamic>> _campusPhotos = [
    {"path": "assets/campus/gallery/main_gate.jpg", "caption": "Main Gate", "icon": Icons.account_balance_outlined, "color": Colors.blue},
    {"path": "assets/campus/gallery/academic_block.jpg", "caption": "Academic Block", "icon": Icons.school_outlined, "color": Colors.indigo},
    {"path": "assets/campus/gallery/library.jpg", "caption": "Central Library", "icon": Icons.menu_book_outlined, "color": Colors.purple},
    {"path": "assets/campus/gallery/computer_lab.jpg", "caption": "Computer Lab", "icon": Icons.computer_outlined, "color": Colors.teal},
    {"path": "assets/campus/gallery/sports_ground.jpg", "caption": "Sports Ground", "icon": Icons.sports_soccer_outlined, "color": Colors.orange},
    {"path": "assets/campus/gallery/canteen.jpg", "caption": "Canteen", "icon": Icons.restaurant_outlined, "color": Colors.green},
  ];

  // =====================================================================
  // 3. HELPERS & MAP LOGIC
  // =====================================================================
  Map<String, dynamic>? _locationById(String id) {
    for (final l in _allLocations) {
      if (l['id'] == id) return l;
    }
    return null;
  }

  String _photoFor(String locationId) => 'assets/campus/locations/$locationId.jpg';

  Color _categoryColor(String category) {
    switch (category) {
      case 'Academic':
        return Colors.blue;
      case 'Administration':
        return Colors.purple;
      case 'Facilities':
        return Colors.green;
      case 'Labs':
        return Colors.teal;
      case 'Sports':
        return Colors.orange;
      case 'Restricted':
        return Colors.pink;
      default:
        return _primary;
    }
  }

  double _hueFor(String category) {
    switch (category) {
      case 'Academic':
        return BitmapDescriptor.hueAzure;
      case 'Administration':
        return BitmapDescriptor.hueViolet;
      case 'Facilities':
        return BitmapDescriptor.hueGreen;
      case 'Labs':
        return BitmapDescriptor.hueCyan;
      case 'Sports':
        return BitmapDescriptor.hueYellow;
      case 'Restricted':
        return BitmapDescriptor.hueRose;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

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
      final double hue = isSelected
          ? BitmapDescriptor.hueOrange
          : (loc['emergency'] == true ? BitmapDescriptor.hueRed : _hueFor(loc['category'] as String));
      return Marker(
        markerId: MarkerId(loc['id'] as String),
        position: loc['point'] as LatLng,
        infoWindow: InfoWindow(title: loc['name'] as String, snippet: loc['desc'] as String),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () => _selectLocation(loc),
      );
    }).toSet();
  }

  // Blue outline + light fill around the whole campus so it stands out on the map
  Set<Polygon> get _polygons => {
        Polygon(
          polygonId: const PolygonId('campus'),
          points: _campusBoundary,
          fillColor: _primary.withOpacity(0.10),
          strokeColor: _accent,
          strokeWidth: 3,
        ),
      };

  void _animateSheet(double size) {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(size, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  void _selectLocation(Map<String, dynamic> loc) {
    setState(() {
      _selectedLocation = loc;
      _selectedDepartment = null;
      _selectedFloor = 0;
      _photoIndex = 0;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc['point'] as LatLng, 18.5));
    _animateSheet(0.55);
  }

  void _selectDepartment(Map<String, dynamic> d) {
    final loc = _locationById(d['locationId'] as String);
    setState(() {
      _selectedDepartment = d;
      _selectedLocation = loc; // highlights the department's building on the map
      _photoIndex = 0;
    });
    if (loc != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc['point'] as LatLng, 18.5));
    }
    _animateSheet(0.62);
  }

  void _clearSelection() {
    setState(() {
      _selectedLocation = null;
      _selectedDepartment = null;
    });
    _animateSheet(0.30);
  }

  // Collapse the sheet so the building can be seen properly on the map
  void _showOnMap() {
    final loc = _selectedLocation;
    if (loc != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc['point'] as LatLng, 19));
    }
    _animateSheet(0.20);
  }

  void _goToCurrentLocation() {
    // Dummy Current Location
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(const LatLng(19.17472, 77.30028), 18));
  }

  // Zoom so the whole campus fits on screen
  void _fitCampus() {
    double minLat = _campusBoundary.first.latitude, maxLat = minLat;
    double minLng = _campusBoundary.first.longitude, maxLng = minLng;
    for (final p in _campusBoundary) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        60,
      ),
    );
  }

  void _openPhotoViewer(List<Map<String, dynamic>> photos, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PhotoViewerPage(photos: photos, initialIndex: index)),
    );
  }

  // =====================================================================
  // CAMPUS PHOTO MANAGEMENT
  // Principal and HOD can manage photos for ALL campus locations.
  // Teachers and Students are view-only.
  // Department ownership is NOT used for campus-photo authorization.
  // =====================================================================
  bool _canManageLocationPhotos(Map<String, dynamic> loc) {
    // PRIORITY 3 FIX: Enforced via AuthService RBAC instead of hardcode role string.
    // HOD and Principal have 'canManage' true for campusMap in permission_model.dart
    return _authService.hasPermission('campusMap', 'canManage');
  }

  Future<List<Map<String, dynamic>>> _getLocationPhotos(String locationId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('campus_locations')
        .doc(locationId)
        .get();

    if (!snapshot.exists) return [];

    final data = snapshot.data() ?? <String, dynamic>{};
    final raw = data['photos'];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => (item['url']?.toString() ?? '').isNotEmpty)
        .toList();
  }

  Future<void> _uploadLocationPhotos(Map<String, dynamic> loc) async {
    if (!_canManageLocationPhotos(loc)) return;

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 82);
    if (picked.isEmpty || !mounted) return;

    final locationId = loc['id'].toString();
    final user = _currentUser;
    if (user == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uploaded = <Map<String, dynamic>>[];

      for (final image in picked) {
        final file = File(image.path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('campus_locations/$locationId/$fileName');

        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();

        uploaded.add({
          'url': url,
          'caption': loc['name']?.toString() ?? 'Campus Location',
          'uploadedBy': user.id,
          'uploadedByName': user.fullName,
          'uploadedByRole': _role,
          'uploadedAt': Timestamp.now(),
        });
      }

      final doc = FirebaseFirestore.instance
          .collection('campus_locations')
          .doc(locationId);

      await doc.set({
        'locationId': locationId,
        'locationName': loc['name']?.toString() ?? '',
        'photos': FieldValue.arrayUnion(uploaded),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.id,
        'updatedByName': user.fullName,
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${uploaded.length} photo(s) uploaded successfully.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo upload failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteLocationPhoto(
    Map<String, dynamic> loc,
    Map<String, dynamic> photo,
  ) async {
    if (!_canManageLocationPhotos(loc)) return;

    final url = photo['url']?.toString() ?? '';
    if (url.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This photo will be removed from this campus location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await FirebaseStorage.instance.refFromURL(url).delete();

      await FirebaseFirestore.instance
          .collection('campus_locations')
          .doc(loc['id'].toString())
          .update({
        'photos': FieldValue.arrayRemove([photo]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete photo: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _locationCloudPhotos(Map<String, dynamic> loc, Color color) {
    final theme = Theme.of(context);
    final canManage = _canManageLocationPhotos(loc);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getLocationPhotos(loc['id'].toString()),
      builder: (context, snapshot) {
        final photos = snapshot.data ?? <Map<String, dynamic>>[];
        final visiblePhotos = photos
            .map((p) => {
                  'path': p['url']?.toString() ?? '',
                  'caption': p['caption']?.toString() ?? loc['name'].toString(),
                  'icon': loc['icon'] as IconData,
                  'color': color,
                  'cloud': true,
                  'raw': p,
                })
            .where((p) => (p['path'] as String).isNotEmpty)
            .toList();

        final staticPhoto = {
          'path': _photoFor(loc['id'].toString()),
          'caption': loc['name'],
          'icon': loc['icon'],
          'color': color,
        };

        final gallery = <Map<String, dynamic>>[
          ...visiblePhotos,
          if (visiblePhotos.isEmpty) staticPhoto,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _openPhotoViewer(gallery, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _CampusImage(
                        path: gallery.first['path'] as String,
                        icon: loc['icon'] as IconData,
                        color: color,
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _frostedTag(loc['category'] as String, Icons.category_outlined),
                      ),
                      if (loc['emergency'] == true)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _tag('SOS', Colors.red, Colors.white),
                        ),
                      if (visiblePhotos.isNotEmpty)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: _frostedTag(
                            '${visiblePhotos.length} uploaded',
                            Icons.cloud_done_outlined,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(minHeight: 2),
            if (visiblePhotos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visiblePhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = visiblePhotos[index];
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _openPhotoViewer(visiblePhotos, index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 92,
                              height: 74,
                              child: _CampusImage(
                                path: p['path'] as String,
                                icon: loc['icon'] as IconData,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        if (canManage)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _deleteLocationPhoto(
                                loc,
                                p['raw'] as Map<String, dynamic>,
                              ),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
            if (canManage) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _uploadLocationPhotos(loc),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text(
                    'Manage Location Photos',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: BorderSide(color: _primary.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // =====================================================================
  // 4. BUILD (screen skeleton)
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool hideButtons = _sheetExtent > 0.7;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _mapType == MapType.hybrid ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.brightness == Brightness.dark ? theme.scaffoldBackgroundColor : _lightBg,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ---------------- MAP ----------------
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _campusCenter, zoom: 17.5),
              mapType: _mapType,
              markers: _buildMarkers(),
              polygons: _polygons,
              buildingsEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              padding: const EdgeInsets.only(top: 130, bottom: 110),
              onMapCreated: (controller) => _mapController = controller,
              onTap: (_) {
                if (_selectedLocation != null || _selectedDepartment != null) _clearSelection();
              },
            ),

            // ---------------- TOP: search + categories ----------------
            _buildTopOverlay(),

            // ---------------- BOTTOM SHEET ----------------
            Positioned.fill(child: _buildSheet()),

            // ---------------- MAP BUTTONS (ride above the sheet) ----------------
            Positioned(
              right: 14,
              bottom: screenHeight * _sheetExtent + 14,
              child: IgnorePointer(
                ignoring: hideButtons,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: hideButtons ? 0 : 1,
                  child: Column(
                    children: [
                      _mapButton(
                        _mapType == MapType.hybrid ? Icons.map_outlined : Icons.satellite_alt_outlined,
                        _mapType == MapType.hybrid ? "Map view" : "Satellite view",
                        () => setState(() {
                          _mapType = _mapType == MapType.hybrid ? MapType.normal : MapType.hybrid;
                        }),
                      ),
                      const SizedBox(height: 10),
                      _mapButton(Icons.zoom_out_map_rounded, "Show whole campus", _fitCampus),
                      const SizedBox(height: 10),
                      _mapButton(Icons.my_location, "My location", _goToCurrentLocation, primary: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // 5. TOP OVERLAY + MAP BUTTONS
  // =====================================================================
  Widget _buildTopOverlay() {
    final bool canGoBack = Navigator.of(context).canPop();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Column(
            children: [
              Row(
                children: [
                  if (canGoBack) ...[
                    _mapButton(Icons.arrow_back_ios_new_rounded, "Back", () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: _buildSearchPill()),
                ],
              ),
              const SizedBox(height: 10),
              _buildCategoryChips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapButton(IconData icon, String tooltip, VoidCallback onTap, {bool primary = false}) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: primary ? _primary : theme.cardColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: primary ? Colors.white : _iconOf(theme), size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPill() {
    final theme = Theme.of(context);
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            if (val.trim().isNotEmpty) {
              _selectedLocation = null;
              _selectedDepartment = null;
            }
          });
          if (val.trim().isNotEmpty && _sheetExtent < 0.45) _animateSheet(0.55);
        },
        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: "Search buildings, rooms, departments...",
          hintStyle: TextStyle(color: theme.hintColor, fontSize: 13.5),
          prefixIcon: Icon(Icons.search_rounded, color: _iconOf(theme), size: 22),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: "Clear",
                  icon: Icon(Icons.close_rounded, color: theme.hintColor, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                    : null,
                color: isSelected ? null : theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index > 0) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : _categoryColor(_categories[index]),
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : _headingOf(theme),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================================
  // 6. BOTTOM SHEET (Places / Departments / Gallery / Details)
  // =====================================================================
  Widget _buildSheet() {
    final theme = Theme.of(context);
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        // remember the sheet height so the map buttons can follow it
        if ((n.extent - _sheetExtent).abs() > 0.004) {
          _sheetExtent = n.extent;
          if (!_extentUpdateScheduled) {
            _extentUpdateScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _extentUpdateScheduled = false;
              if (mounted) setState(() {});
            });
          }
        }
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.30,
        minChildSize: 0.12,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.12, 0.30, 0.62, 0.92],
        builder: (context, scrollController) {
          final bool inDetail = _selectedDepartment != null || _selectedLocation != null;
          final bool searching = _searchQuery.trim().isNotEmpty;

          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, -4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // drag handle
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 12),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.hintColor.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        if (!inDetail && !searching) _buildTabs(),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 28),
                    sliver: SliverList(delegate: SliverChildListDelegate(_sheetChildren())),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _sheetChildren() {
    if (_selectedDepartment != null) return _departmentDetail(_selectedDepartment!);
    if (_selectedLocation != null) return _locationDetail(_selectedLocation!);
    if (_searchQuery.trim().isNotEmpty) return _searchResults();

    switch (_tab) {
      case 1:
        return _departmentsTab();
      case 2:
        return _galleryTab();
      default:
        return _placesTab();
    }
  }

  Widget _buildTabs() {
    final theme = Theme.of(context);
    const tabs = [
      {"label": "Places", "icon": Icons.place_outlined},
      {"label": "Departments", "icon": Icons.account_balance_outlined},
      {"label": "Gallery", "icon": Icons.photo_library_outlined},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final bool selected = _tab == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[i]["icon"] as IconData, size: 16, color: selected ? Colors.white : _iconOf(theme)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        tabs[i]["label"] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _iconOf(theme),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TAB 1: PLACES (Quick Access, grouped by category)
  // ---------------------------------------------------------------------
  List<Widget> _placesTab() {
    final theme = Theme.of(context);
    final locs = _visibleLocations;

    final List<Widget> widgets = [
      _sheetTitle("Quick Access", "${locs.length} locations"),
      const SizedBox(height: 14),
    ];

    if (locs.isEmpty) {
      widgets.add(_emptyNote(Icons.search_off_rounded, "No locations found."));
      return widgets;
    }

    for (final cat in _categories.skip(1)) {
      final items = locs.where((l) => l['category'] == cat).toList();
      if (items.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _categoryColor(cat)),
              ),
              const SizedBox(width: 8),
              Text(cat, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _headingOf(theme))),
              const Spacer(),
              Text("${items.length}", style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
      widgets.add(_groupedCard(items.map((l) => _placeRow(l)).toList()));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _placeRow(Map<String, dynamic> loc) {
    final theme = Theme.of(context);
    final Color c = _categoryColor(loc['category'] as String);
    final int floors = loc['floors'] as int;
    final String sub = floors == 0 ? "Outdoor" : (floors == 1 ? "1 floor" : "$floors floors");

    return InkWell(
      onTap: () => _selectLocation(loc),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(loc['icon'] as IconData, color: c, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _headingOf(theme)),
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
            ),
            if (loc['emergency'] == true) ...[
              _tag("SOS", Colors.red.withOpacity(0.12), Colors.red.shade700),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 22),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TAB 2: DEPARTMENTS
  // ---------------------------------------------------------------------
  List<Widget> _departmentsTab() {
    return [
      _sheetTitle("Departments", "${_departments.length} departments"),
      const SizedBox(height: 14),
      ..._departments.map((d) => _departmentCard(d)),
    ];
  }

  Widget _departmentCard(Map<String, dynamic> d) {
    final theme = Theme.of(context);
    final Color c = d['color'] as Color;
    final List<String> images = (d['images'] as List).cast<String>();
    final loc = _locationById(d['locationId'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: InkWell(
        onTap: () => _selectDepartment(d),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo header
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CampusImage(path: images.isNotEmpty ? images.first : '', icon: d['icon'] as IconData, color: c),
                  // dark fade at the bottom so badges stay readable
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(top: 10, left: 10, child: _frostedTag(d['short'] as String, Icons.school_outlined)),
                  Positioned(bottom: 10, right: 10, child: _frostedTag("${images.length} photos", Icons.photo_outlined)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _headingOf(theme)),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: theme.hintColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("HOD: ${d['hod']}", style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (loc != null) _iconTag(Icons.place_outlined, loc['name'] as String, _tintOf(theme), _iconOf(theme)),
                      _iconTag(Icons.groups_outlined, "${d['students']} students", theme.hintColor.withOpacity(0.12), theme.hintColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TAB 3: GALLERY
  // ---------------------------------------------------------------------
  List<Widget> _galleryTab() {
    return [
      _sheetTitle("Campus Gallery", "${_campusPhotos.length} photos"),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _campusPhotos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 130,
        ),
        itemBuilder: (context, index) {
          final p = _campusPhotos[index];
          return _photoTile(p, () => _openPhotoViewer(_campusPhotos, index));
        },
      ),
    ];
  }

  Widget _photoTile(Map<String, dynamic> p, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CampusImage(path: p['path'] as String, icon: p['icon'] as IconData, color: p['color'] as Color),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Text(
              p['caption'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SEARCH RESULTS (places + departments)
  // ---------------------------------------------------------------------
  List<Widget> _searchResults() {
    final theme = Theme.of(context);
    final String q = _searchQuery.trim().toLowerCase();
    final places = _visibleLocations;
    final depts = _departments.where((d) {
      return (d['name'] as String).toLowerCase().contains(q) || (d['short'] as String).toLowerCase().contains(q);
    }).toList();

    if (places.isEmpty && depts.isEmpty) {
      return [
        _sheetTitle("Search Results", "0 found"),
        const SizedBox(height: 14),
        _emptyNote(Icons.search_off_rounded, "Nothing found for \"${_searchQuery.trim()}\"."),
      ];
    }

    return [
      _sheetTitle("Search Results", "${places.length + depts.length} found"),
      const SizedBox(height: 14),
      if (places.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text("Places", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _headingOf(theme))),
        ),
        _groupedCard(places.map((l) => _placeRow(l)).toList()),
        const SizedBox(height: 16),
      ],
      if (depts.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text("Departments", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _headingOf(theme))),
        ),
        _groupedCard(depts.map((d) => _departmentRow(d)).toList()),
      ],
    ];
  }

  Widget _departmentRow(Map<String, dynamic> d) {
    final theme = Theme.of(context);
    final Color c = d['color'] as Color;

    return InkWell(
      onTap: () => _selectDepartment(d),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(d['icon'] as IconData, color: c, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _headingOf(theme)),
                  ),
                  const SizedBox(height: 2),
                  Text("HOD: ${d['hod']}", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 22),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // DEPARTMENT DETAIL
  // ---------------------------------------------------------------------
  List<Widget> _departmentDetail(Map<String, dynamic> d) {
    final theme = Theme.of(context);
    final Color c = d['color'] as Color;
    final List<String> images = (d['images'] as List).cast<String>();
    final loc = _locationById(d['locationId'] as String);

    final photos = List<Map<String, dynamic>>.generate(images.length, (i) {
      return {"path": images[i], "caption": "${d['name']} • Photo ${i + 1}", "icon": d['icon'], "color": c};
    });

    return [
      _detailTopBar("Departments"),
      const SizedBox(height: 14),
      _photoCarousel(d['id'] as String, photos, d['icon'] as IconData, c),
      const SizedBox(height: 14),
      if (loc != null) _locationCloudPhotos(loc, c),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Text(
              d['name'] as String,
              style: TextStyle(fontSize: 20, height: 1.2, fontWeight: FontWeight.w800, color: _headingOf(theme)),
            ),
          ),
          const SizedBox(width: 8),
          _tag(d['short'] as String, c.withOpacity(0.12), c),
        ],
      ),
      const SizedBox(height: 6),
      Text("HOD: ${d['hod']}", style: TextStyle(fontSize: 13, color: theme.hintColor, fontWeight: FontWeight.w600)),
      if (loc != null) ...[
        const SizedBox(height: 10),
        _iconTag(
          Icons.place_outlined,
          "${loc['name']}  •  ${(loc['floors'] as int)} floors",
          _tintOf(theme),
          _iconOf(theme),
        ),
      ],
      const SizedBox(height: 14),
      Text(d['about'] as String, style: TextStyle(fontSize: 13.5, height: 1.45, color: theme.hintColor)),
      const SizedBox(height: 16),
      Row(
        children: [
          _statTile("${d['students']}", "Students"),
          const SizedBox(width: 10),
          _statTile("${d['faculty']}", "Faculty"),
          const SizedBox(width: 10),
          _statTile("${d['labs']}", "Labs"),
        ],
      ),
      const SizedBox(height: 18),
      Text("Facilities", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _headingOf(theme))),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (d['facilities'] as List)
            .map((f) => _iconTag(Icons.check_circle_outline_rounded, f as String, Colors.green.withOpacity(0.12), Colors.green.shade700))
            .toList(),
      ),
      const SizedBox(height: 20),
      _actionButtons(primaryLabel: "Show on map", primaryIcon: Icons.map_outlined, onPrimary: _showOnMap),
    ];
  }

  Widget _statTile(String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _headingOf(theme))),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11.5, color: theme.hintColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LOCATION DETAIL
  // ---------------------------------------------------------------------
  List<Widget> _locationDetail(Map<String, dynamic> loc) {
    final theme = Theme.of(context);
    final Color c = _categoryColor(loc['category'] as String);
    final int floors = loc['floors'] as int;
    final deptsHere = _departments.where((d) => d['locationId'] == loc['id']).toList();

    return [
      _detailTopBar("Places"),
      const SizedBox(height: 14),

      // Cloud photos uploaded by Principal / eligible HOD.
      _locationCloudPhotos(loc, c),
      const SizedBox(height: 16),
      Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(15)),
            child: Icon(loc['icon'] as IconData, color: c, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc['name'] as String, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _headingOf(theme))),
                Text(loc['category'] as String, style: TextStyle(fontSize: 12.5, color: theme.hintColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Text(loc['desc'] as String, style: TextStyle(fontSize: 13.5, height: 1.45, color: theme.hintColor)),
      const SizedBox(height: 16),

      // Floor selector
      if (floors > 0) ...[
        Text("Select Floor", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _headingOf(theme))),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: floors + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final bool selected = _selectedFloor == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedFloor = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  decoration: BoxDecoration(
                    color: selected ? _primary : _tintOf(theme),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      index == 0 ? "G" : "$index",
                      style: TextStyle(
                        color: selected ? Colors.white : _iconOf(theme),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _selectedFloor == 0 ? "Ground floor" : "Floor $_selectedFloor",
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        const SizedBox(height: 16),
      ],

      // Departments in this building
      if (deptsHere.isNotEmpty) ...[
        Text("Departments here", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _headingOf(theme))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: deptsHere.map((d) {
            final Color dc = d['color'] as Color;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectDepartment(d),
              child: _iconTag(d['icon'] as IconData, d['short'] as String, dc.withOpacity(0.12), dc),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],

      _actionButtons(primaryLabel: "Navigate", primaryIcon: Icons.directions, onPrimary: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Calculating route... (UI Ready)")),
        );
      }),
    ];
  }

  // ---------------------------------------------------------------------
  // SHARED DETAIL PIECES
  // ---------------------------------------------------------------------
  Widget _detailTopBar(String backLabel) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _clearSelection,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
          decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _iconOf(theme)),
              const SizedBox(width: 6),
              Text(backLabel, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _iconOf(theme))),
            ],
          ),
        ),
      ),
    );
  }

  // Swipeable photos + dots
  Widget _photoCarousel(String keyId, List<Map<String, dynamic>> photos, IconData icon, Color color) {
    final theme = Theme.of(context);
    final int count = photos.isEmpty ? 1 : photos.length;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            key: ValueKey(keyId), // new department = carousel starts from photo 1
            itemCount: count,
            onPageChanged: (i) => setState(() => _photoIndex = i),
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: photos.isEmpty ? null : () => _openPhotoViewer(photos, i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _CampusImage(path: photos.isEmpty ? '' : photos[i]['path'] as String, icon: icon, color: color),
                        if (photos.isNotEmpty)
                          Positioned(top: 10, right: 10, child: _frostedTag("${i + 1}/${photos.length}", Icons.photo_outlined)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final bool active = i == _photoIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? _iconOf(theme) : theme.hintColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _actionButtons({required String primaryLabel, required IconData primaryIcon, required VoidCallback onPrimary}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearSelection,
            icon: const Icon(Icons.close, size: 18),
            label: const Text("Close", style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.hintColor,
              side: BorderSide(color: theme.dividerColor),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onPrimary,
            icon: Icon(primaryIcon, size: 18),
            label: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // 7. SHARED SMALL WIDGETS
  // =====================================================================
  Widget _sheetTitle(String title, String trailing) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _headingOf(theme))),
        const Spacer(),
        Text(trailing, style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _iconTag(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // small dark pill that stays readable on top of photos
  Widget _frostedTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _groupedCard(List<Widget> rows) {
    final theme = Theme.of(context);
    final List<Widget> items = [];
    for (int i = 0; i < rows.length; i++) {
      if (i > 0) {
        items.add(Divider(height: 1, indent: 68, color: theme.dividerColor.withOpacity(0.7)));
      }
      items.add(rows[i]);
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Material(color: Colors.transparent, child: Column(children: items)),
    );
  }

  Widget _emptyNote(IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.hintColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, height: 1.35, color: theme.hintColor)),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Photo widget: shows your photo (asset or http link).
// If the file is missing it shows a nice coloured placeholder instead,
// so the app never breaks while you are still adding photos.
// =====================================================================
class _CampusImage extends StatelessWidget {
  final String path;
  final IconData icon;
  final Color color;
  final BoxFit fit;

  const _CampusImage({
    required this.path,
    required this.icon,
    required this.color,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(icon, size: 40, color: Colors.white.withOpacity(0.85))),
    );

    if (path.isEmpty) return placeholder;

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
      );
    }

    return Image.asset(path, fit: fit, errorBuilder: (_, __, ___) => placeholder);
  }
}

// =====================================================================
// Full-screen photo viewer (swipe + pinch to zoom)
// =====================================================================
class _PhotoViewerPage extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const _PhotoViewerPage({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late final PageController _pageController = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final current = photos[_index];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final p = photos[i];
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox.expand(
                    child: _CampusImage(
                      path: p['path'] as String,
                      icon: p['icon'] as IconData,
                      color: p['color'] as Color,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            // top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context),
                        child: const SizedBox(width: 44, height: 44, child: Icon(Icons.close_rounded, color: Colors.white)),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        "${_index + 1} / ${photos.length}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // caption
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Text(
                    "${current['caption']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}