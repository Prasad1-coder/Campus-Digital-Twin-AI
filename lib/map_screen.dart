import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'services/auth_service.dart';
import 'user_model.dart';

// ======================= THEME / CONSTANTS =======================
const _primary = Color(0xFF1565C0);
const _primaryDark = Color(0xFF0D47A1);
const _accent = Color(0xFF42A5F5);
const _lightBg = Color(0xFFF5F9FF);
const _softBlue = Color(0xFFE3F2FD);
const _textDark = Color(0xFF1A237E);
const _grad = LinearGradient(colors: [_primary, _primaryDark], begin: Alignment.topCenter, end: Alignment.bottomCenter);

bool _dark(ThemeData t) => t.brightness == Brightness.dark;
Color _tintOf(ThemeData t) => _dark(t) ? _primary.withOpacity(0.20) : _softBlue;
Color _iconOf(ThemeData t) => _dark(t) ? _accent : _primary;
Color _headingOf(ThemeData t) => _dark(t) ? t.colorScheme.onSurface : _textDark;

TextStyle _ts(double size, FontWeight w, Color c, {double? h}) => TextStyle(fontSize: size, fontWeight: w, color: c, height: h);

// Department photos: assets/campus/departments/<id>_1.jpg, _2.jpg, _3.jpg
List<String> _deptImages(String id) => List.generate(3, (i) => 'assets/campus/departments/${id}_${i + 1}.jpg');

// category -> (list colour, map marker hue)
final _catStyle = <String, (Color, double)>{
  'Academic': (Colors.blue, BitmapDescriptor.hueAzure),
  'Administration': (Colors.purple, BitmapDescriptor.hueViolet),
  'Facilities': (Colors.green, BitmapDescriptor.hueGreen),
  'Labs': (Colors.teal, BitmapDescriptor.hueCyan),
  'Sports': (Colors.orange, BitmapDescriptor.hueYellow),
  'Restricted': (Colors.pink, BitmapDescriptor.hueRose),
};
Color _catColor(String c) => _catStyle[c]?.$1 ?? _primary;
double _catHue(String c) => _catStyle[c]?.$2 ?? BitmapDescriptor.hueAzure;

// ======================= DATA (dummy campus data - replace with real) =======================
const _everyone = ['student', 'teacher', 'hod', 'principal'];
const _staff = ['teacher', 'hod', 'principal'];
const _principalOnly = ['principal'];

Map<String, dynamic> _loc(String id, String name, IconData icon, String cat, String desc, double lat, double lng, int floors,
        {bool sos = false, List<String> roles = _everyone}) =>
    {"id": id, "name": name, "icon": icon, "category": cat, "roles": roles, "point": LatLng(lat, lng), "floors": floors, "desc": desc, "emergency": sos};

Map<String, dynamic> _dept(String id, String name, String short, IconData icon, Color color, String locationId, String hod, int students,
        int faculty, int labs, String about, List<String> facilities) =>
    {
      "id": id, "name": name, "short": short, "icon": icon, "color": color, "locationId": locationId, "hod": hod,
      "students": students, "faculty": faculty, "labs": labs, "about": about, "facilities": facilities, "images": _deptImages(id),
    };

final _allLocations = [
  _loc("acad_a", "Academic Block A", Icons.school_outlined, "Academic", "Main classrooms for CSE & IT.", 19.17472, 77.30028, 4),
  _loc("acad_b", "Academic Block B", Icons.school_outlined, "Academic", "Classrooms for Mechanical & Civil.", 19.17492, 77.30048, 3),
  _loc("elec_block", "Electrical Block", Icons.electrical_services_outlined, "Academic", "Electrical classrooms & machines lab.", 19.17452, 77.30048, 2),
  _loc("exam_hall", "Exam Hall", Icons.edit_note_outlined, "Academic", "Central examination hall.", 19.17482, 77.30008, 1),
  _loc("admin", "Admin Block", Icons.apartment_outlined, "Administration", "Administrative office & principal's cabin.", 19.17512, 77.30038, 2),
  _loc("hod_office", "HOD Office", Icons.chair_alt_outlined, "Administration", "Head of Department cabins.", 19.17502, 77.30028, 1, roles: _staff),
  _loc("staff_room", "Staff Room", Icons.groups_outlined, "Administration", "Faculty common room.", 19.17522, 77.30058, 1, roles: _staff),
  _loc("library", "Central Library", Icons.menu_book_outlined, "Facilities", "Study halls & reading rooms.", 19.17492, 77.30078, 3),
  _loc("canteen", "Canteen", Icons.restaurant_outlined, "Facilities", "Campus food court.", 19.17502, 77.30058, 1),
  _loc("medical", "Medical Room", Icons.local_hospital_outlined, "Facilities", "First aid & medical assistance.", 19.17462, 77.30018, 1, sos: true),
  _loc("comp_lab", "Computer Lab", Icons.computer_outlined, "Labs", "High-speed internet labs.", 19.17552, 77.30068, 2),
  _loc("chem_lab", "Chemistry Lab", Icons.science_outlined, "Labs", "Chemistry practical labs.", 19.17532, 77.30018, 1, sos: true),
  _loc("sports", "Sports Ground", Icons.sports_soccer_outlined, "Sports", "Outdoor sports arena.", 19.17422, 77.30088, 0),
  _loc("server", "Server Room", Icons.dns_outlined, "Restricted", "Main campus server infrastructure.", 19.17517, 77.30043, 1, sos: true, roles: _principalOnly),
  _loc("security", "Security Office", Icons.security_outlined, "Restricted", "Campus security & CCTV control.", 19.17462, 77.30078, 1, sos: true, roles: _principalOnly),
];

final _departments = [
  _dept("cse", "Computer Engineering", "CSE", Icons.computer_outlined, Colors.blue, "acad_a", "Dr. Sharma", 480, 24, 4,
      "AI, app & web development with hands-on labs, hackathons and industry projects.", ["Computer Lab", "AI Lab", "Project Lab", "Seminar Hall"]),
  _dept("it", "Information Technology", "IT", Icons.hub_outlined, Colors.indigo, "acad_a", "Prof. Singh", 360, 18, 3,
      "Networks, cloud and cyber security with a strong placement record.", ["Networking Lab", "Cyber Lab", "Smart Classroom"]),
  _dept("mech", "Mechanical Engineering", "MECH", Icons.precision_manufacturing_outlined, Colors.orange, "acad_b", "Dr. Rao", 300, 20, 5,
      "Design, thermal and manufacturing with a fully equipped workshop.", ["Workshop", "CAD/CAM Lab", "Thermal Lab", "Fluid Lab"]),
  _dept("civil", "Civil Engineering", "CIVIL", Icons.foundation_outlined, Colors.green, "acad_b", "Dr. Mehta", 240, 16, 4,
      "Structures, surveying and environment with live site visits.", ["Survey Lab", "Concrete Lab", "Structural Lab"]),
  _dept("elec", "Electrical Engineering", "ELEC", Icons.bolt_outlined, Colors.purple, "elec_block", "Dr. Patil", 260, 17, 4,
      "Power systems, machines and automation with modern labs.", ["Machines Lab", "Power Systems Lab", "Automation Lab"]),
];

Map<String, dynamic> _photo(String file, String caption, IconData icon, Color color) =>
    {"path": "assets/campus/gallery/$file.jpg", "caption": caption, "icon": icon, "color": color};

final _campusPhotos = [
  _photo("main_gate", "Main Gate", Icons.account_balance_outlined, Colors.blue),
  _photo("academic_block", "Academic Block", Icons.school_outlined, Colors.indigo),
  _photo("library", "Central Library", Icons.menu_book_outlined, Colors.purple),
  _photo("computer_lab", "Computer Lab", Icons.computer_outlined, Colors.teal),
  _photo("sports_ground", "Sports Ground", Icons.sports_soccer_outlined, Colors.orange),
  _photo("canteen", "Canteen", Icons.restaurant_outlined, Colors.green),
];

Map<String, dynamic>? _locationById(String id) {
  for (final l in _allLocations) {
    if (l['id'] == id) return l;
  }
  return null;
}

// ======================= SCREEN =======================
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _authService = AuthService();
  final _searchController = TextEditingController();
  final _sheetController = DraggableScrollableController();
  GoogleMapController? _mapController;

  UserModel? get _currentUser => _authService.getCurrentUser();
  String get _role => _currentUser?.role.name ?? 'student';

  // Science College Nanded (≈ 19.17472, 77.30028). Replace boundary with real survey corners.
  final _campusCenter = const LatLng(19.17472, 77.30028);
  final _campusBoundary = const [LatLng(19.17582, 77.29968), LatLng(19.17582, 77.30128), LatLng(19.17382, 77.30128), LatLng(19.17382, 77.29968)];
  final _categories = const ["All", "Academic", "Administration", "Facilities", "Labs", "Sports", "Restricted"];

  MapType _mapType = MapType.hybrid;
  int _selectedCategoryIndex = 0, _tab = 0, _selectedFloor = 0, _photoIndex = 0;
  String _searchQuery = "";
  Map<String, dynamic>? _selectedLocation, _selectedDepartment;
  double _sheetExtent = 0.30;
  bool _extentUpdateScheduled = false;
  final _photoCache = <String, Future<List<Map<String, dynamic>>>>{}; // avoids re-fetching on every rebuild

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ======================= MAP LOGIC =======================
  List<Map<String, dynamic>> get _visibleLocations => _allLocations.where((l) {
        if (!(l['roles'] as List).contains(_role)) return false;
        if (_selectedCategoryIndex != 0 && l['category'] != _categories[_selectedCategoryIndex]) return false;
        return _searchQuery.isEmpty || (l['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

  Set<Marker> _buildMarkers() => _visibleLocations.map((l) {
        final selected = _selectedLocation?['id'] == l['id'];
        final hue = selected ? BitmapDescriptor.hueOrange : (l['emergency'] == true ? BitmapDescriptor.hueRed : _catHue(l['category'] as String));
        return Marker(
          markerId: MarkerId(l['id'] as String),
          position: l['point'] as LatLng,
          infoWindow: InfoWindow(title: l['name'] as String, snippet: l['desc'] as String),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () => _selectLocation(l),
        );
      }).toSet();

  Set<Polygon> get _polygons => {
        Polygon(polygonId: const PolygonId('campus'), points: _campusBoundary, fillColor: _primary.withOpacity(0.10), strokeColor: _accent, strokeWidth: 3),
      };

  void _animateSheet(double size) {
    if (_sheetController.isAttached) _sheetController.animateTo(size, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _zoomTo(Map<String, dynamic>? loc, double zoom) {
    if (loc != null) _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc['point'] as LatLng, zoom));
  }

  void _selectLocation(Map<String, dynamic> loc) {
    setState(() {
      _selectedLocation = loc;
      _selectedDepartment = null;
      _selectedFloor = 0;
      _photoIndex = 0;
    });
    _zoomTo(loc, 18.5);
    _animateSheet(0.55);
  }

  void _selectDepartment(Map<String, dynamic> d) {
    final loc = _locationById(d['locationId'] as String);
    setState(() {
      _selectedDepartment = d;
      _selectedLocation = loc; // highlights the department's building
      _photoIndex = 0;
    });
    _zoomTo(loc, 18.5);
    _animateSheet(0.62);
  }

  void _clearSelection() {
    setState(() => _selectedLocation = _selectedDepartment = null);
    _animateSheet(0.30);
  }

  void _showOnMap() {
    _zoomTo(_selectedLocation, 19);
    _animateSheet(0.20);
  }

  void _fitCampus() {
    final lats = _campusBoundary.map((p) => p.latitude), lngs = _campusBoundary.map((p) => p.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(lats.reduce(min), lngs.reduce(min)), northeast: LatLng(lats.reduce(max), lngs.reduce(max))), 60));
  }

  void _openPhotoViewer(List<Map<String, dynamic>> photos, int index) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => _PhotoViewerPage(photos: photos, initialIndex: index)));

  void _toast(String m, [Color? bg]) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: bg, behavior: SnackBarBehavior.floating));

  // ======================= CAMPUS PHOTO MANAGEMENT (Firebase) =======================
  // Only roles with campusMap.canManage (HOD / Principal) can upload or delete.
  bool get _canManage => _authService.hasPermission('campusMap', 'canManage');

  DocumentReference<Map<String, dynamic>> _locDoc(String id) => FirebaseFirestore.instance.collection('campus_locations').doc(id);

  Future<List<Map<String, dynamic>>> _getLocationPhotos(String id) async {
    final snap = await _locDoc(id).get();
    final raw = snap.data()?['photos'];
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).where((e) => (e['url']?.toString() ?? '').isNotEmpty).toList();
  }

  Future<void> _uploadLocationPhotos(Map<String, dynamic> loc) async {
    final user = _currentUser;
    if (!_canManage || user == null) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 82);
    if (picked.isEmpty || !mounted) return;

    final id = loc['id'].toString(), name = loc['name']?.toString() ?? 'Campus Location';
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final uploaded = <Map<String, dynamic>>[];
      for (final img in picked) {
        final ref = FirebaseStorage.instance.ref().child('campus_locations/$id/${DateTime.now().millisecondsSinceEpoch}_${img.name}');
        await ref.putFile(File(img.path));
        uploaded.add({
          'url': await ref.getDownloadURL(), 'caption': name,
          'uploadedBy': user.id, 'uploadedByName': user.fullName, 'uploadedByRole': _role, 'uploadedAt': Timestamp.now(),
        });
      }
      await _locDoc(id).set({
        'locationId': id, 'locationName': name, 'photos': FieldValue.arrayUnion(uploaded),
        'updatedAt': FieldValue.serverTimestamp(), 'updatedBy': user.id, 'updatedByName': user.fullName,
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _photoCache.remove(id));
      _toast('${uploaded.length} photo(s) uploaded successfully.', Colors.green.shade700);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _toast('Photo upload failed: $e', Colors.red.shade700);
    }
  }

  Future<void> _deleteLocationPhoto(Map<String, dynamic> loc, Map<String, dynamic> photo) async {
    final url = photo['url']?.toString() ?? '';
    if (!_canManage || url.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This photo will be removed from this campus location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final id = loc['id'].toString();
      await FirebaseStorage.instance.refFromURL(url).delete();
      await _locDoc(id).update({'photos': FieldValue.arrayRemove([photo]), 'updatedAt': FieldValue.serverTimestamp()});
      if (!mounted) return;
      setState(() => _photoCache.remove(id));
      _toast('Photo deleted successfully.');
    } catch (e) {
      if (mounted) _toast('Could not delete photo: $e', Colors.red.shade700);
    }
  }

  Widget _locationCloudPhotos(Map<String, dynamic> loc, Color color) {
    final id = loc['id'].toString(), icon = loc['icon'] as IconData;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _photoCache.putIfAbsent(id, () => _getLocationPhotos(id)),
      builder: (context, snap) {
        final cloud = <Map<String, dynamic>>[
          for (final p in snap.data ?? <Map<String, dynamic>>[])
            {'path': p['url'].toString(), 'caption': p['caption']?.toString() ?? loc['name'].toString(), 'icon': icon, 'color': color, 'raw': p},
        ];
        final gallery = cloud.isNotEmpty
            ? cloud
            : <Map<String, dynamic>>[{'path': 'assets/campus/locations/$id.jpg', 'caption': loc['name'], 'icon': icon, 'color': color}];

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: () => _openPhotoViewer(gallery, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  _CampusImage(path: gallery.first['path'] as String, icon: icon, color: color),
                  Positioned(top: 10, left: 10, child: _frosted(loc['category'] as String, Icons.category_outlined)),
                  if (loc['emergency'] == true) Positioned(top: 10, right: 10, child: _tag('SOS', Colors.red, Colors.white)),
                  if (cloud.isNotEmpty) Positioned(right: 10, bottom: 10, child: _frosted('${cloud.length} uploaded', Icons.cloud_done_outlined)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (snap.connectionState == ConnectionState.waiting) const LinearProgressIndicator(minHeight: 2),
          if (cloud.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cloud.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(children: [
                  GestureDetector(
                    onTap: () => _openPhotoViewer(cloud, i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(width: 92, height: 74, child: _CampusImage(path: cloud[i]['path'] as String, icon: icon, color: color)),
                    ),
                  ),
                  if (_canManage)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deleteLocationPhoto(loc, cloud[i]['raw'] as Map<String, dynamic>),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
          if (_canManage) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _uploadLocationPhotos(loc),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Manage Location Photos', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: _primary, side: BorderSide(color: _primary.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ],
        ]);
      },
    );
  }

  // ======================= BUILD =======================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hideButtons = _sheetExtent > 0.7;
    final hybrid = _mapType == MapType.hybrid;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hybrid ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _dark(theme) ? theme.scaffoldBackgroundColor : _lightBg,
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
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
            onMapCreated: (c) => _mapController = c,
            onTap: (_) {
              if (_selectedLocation != null || _selectedDepartment != null) _clearSelection();
            },
          ),
          _buildTopOverlay(),
          Positioned.fill(child: _buildSheet()),
          Positioned(
            right: 14,
            bottom: MediaQuery.of(context).size.height * _sheetExtent + 14,
            child: IgnorePointer(
              ignoring: hideButtons,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: hideButtons ? 0 : 1,
                child: Column(children: [
                  _mapButton(hybrid ? Icons.map_outlined : Icons.satellite_alt_outlined, hybrid ? "Map view" : "Satellite view",
                      () => setState(() => _mapType = hybrid ? MapType.normal : MapType.hybrid)),
                  const SizedBox(height: 10),
                  _mapButton(Icons.zoom_out_map_rounded, "Show whole campus", _fitCampus, primary: true),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ======================= TOP OVERLAY =======================
  Widget _buildTopOverlay() => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(children: [
              Row(children: [
                if (Navigator.of(context).canPop()) ...[
                  _mapButton(Icons.arrow_back_ios_new_rounded, "Back", () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 10),
                ],
                Expanded(child: _buildSearchPill()),
              ]),
              const SizedBox(height: 10),
              _buildCategoryChips(),
            ]),
          ),
        ),
      );

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
          child: SizedBox(width: 46, height: 46, child: Icon(icon, color: primary ? Colors.white : _iconOf(theme), size: 22)),
        ),
      ),
    );
  }

  Widget _buildSearchPill() {
    final theme = Theme.of(context);
    return Container(
      height: 46,
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            if (val.trim().isNotEmpty) _selectedLocation = _selectedDepartment = null;
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
        itemBuilder: (_, i) {
          final sel = _selectedCategoryIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: sel ? _grad : null,
                color: sel ? null : theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (i > 0) ...[
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? Colors.white : _catColor(_categories[i]))),
                  const SizedBox(width: 7),
                ],
                Text(_categories[i], style: _ts(12.5, FontWeight.w700, sel ? Colors.white : _headingOf(theme))),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ======================= BOTTOM SHEET =======================
  Widget _buildSheet() {
    final theme = Theme.of(context);
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
          final showTabs = _selectedDepartment == null && _selectedLocation == null && _searchQuery.trim().isEmpty;
          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: CustomScrollView(controller: scrollController, slivers: [
                SliverToBoxAdapter(
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 12),
                      child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.hintColor.withOpacity(0.35), borderRadius: BorderRadius.circular(10))),
                    ),
                    if (showTabs) _buildTabs(),
                  ]),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 28),
                  sliver: SliverList(delegate: SliverChildListDelegate(_sheetChildren())),
                ),
              ]),
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
    return [_placesTab, _departmentsTab, _galleryTab][_tab]();
  }

  Widget _buildTabs() {
    final theme = Theme.of(context);
    const tabs = [("Places", Icons.place_outlined), ("Departments", Icons.account_balance_outlined), ("Gallery", Icons.photo_library_outlined)];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = _tab == i, fg = sel ? Colors.white : _iconOf(theme);
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(gradient: sel ? _grad : null, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(tabs[i].$2, size: 16, color: fg),
                  const SizedBox(width: 5),
                  Flexible(child: Text(tabs[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(12, FontWeight.w700, fg))),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------- TAB 1: PLACES ----------
  List<Widget> _placesTab() {
    final theme = Theme.of(context), locs = _visibleLocations;
    final out = <Widget>[_sheetTitle("Quick Access", "${locs.length} locations"), const SizedBox(height: 14)];
    if (locs.isEmpty) return out..add(_emptyNote(Icons.search_off_rounded, "No locations found."));

    for (final cat in _categories.skip(1)) {
      final items = locs.where((l) => l['category'] == cat).toList();
      if (items.isEmpty) continue;
      out.addAll([
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _catColor(cat))),
            const SizedBox(width: 8),
            Text(cat, style: _ts(13.5, FontWeight.w800, _headingOf(theme))),
            const Spacer(),
            Text("${items.length}", style: _ts(12, FontWeight.w600, theme.hintColor)),
          ]),
        ),
        _groupedCard(items.map(_placeRow).toList()),
        const SizedBox(height: 16),
      ]);
    }
    return out;
  }

  Widget _listRow(IconData icon, Color c, String title, String sub, VoidCallback onTap, {bool sos = false}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(children: [
          _iconBox(icon, c, size: 44, iconSize: 22, r: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(14.5, FontWeight.w700, _headingOf(theme))),
              const SizedBox(height: 2),
              Text(sub, style: _ts(12, FontWeight.w400, theme.hintColor)),
            ]),
          ),
          if (sos) ...[_tag("SOS", Colors.red.withOpacity(0.12), Colors.red.shade700), const SizedBox(width: 6)],
          Icon(Icons.chevron_right_rounded, color: theme.hintColor, size: 22),
        ]),
      ),
    );
  }

  Widget _placeRow(Map<String, dynamic> l) {
    final f = l['floors'] as int;
    return _listRow(l['icon'] as IconData, _catColor(l['category'] as String), l['name'] as String,
        f == 0 ? "Outdoor" : (f == 1 ? "1 floor" : "$f floors"), () => _selectLocation(l), sos: l['emergency'] == true);
  }

  Widget _departmentRow(Map<String, dynamic> d) =>
      _listRow(d['icon'] as IconData, d['color'] as Color, d['name'] as String, "HOD: ${d['hod']}", () => _selectDepartment(d));

  // ---------- TAB 2: DEPARTMENTS ----------
  List<Widget> _departmentsTab() => [
        _sheetTitle("Departments", "${_departments.length} departments"),
        const SizedBox(height: 14),
        ..._departments.map(_departmentCard),
      ];

  Widget _departmentCard(Map<String, dynamic> d) {
    final theme = Theme.of(context), c = d['color'] as Color;
    final images = (d['images'] as List).cast<String>(), loc = _locationById(d['locationId'] as String);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () => _selectDepartment(d),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(fit: StackFit.expand, children: [
              _CampusImage(path: images.first, icon: d['icon'] as IconData, color: c),
              _fade(60, 0.55),
              Positioned(top: 10, left: 10, child: _frosted(d['short'] as String, Icons.school_outlined)),
              Positioned(bottom: 10, right: 10, child: _frosted("${images.length} photos", Icons.photo_outlined)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(d['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(15.5, FontWeight.w800, _headingOf(theme)))),
                Icon(Icons.chevron_right_rounded, color: theme.hintColor),
              ]),
              const SizedBox(height: 4),
              Text("HOD: ${d['hod']}", style: _ts(12, FontWeight.w600, theme.hintColor)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (loc != null) _tag(loc['name'] as String, _tintOf(theme), _iconOf(theme), icon: Icons.place_outlined),
                _tag("${d['students']} students", theme.hintColor.withOpacity(0.12), theme.hintColor, icon: Icons.groups_outlined),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ---------- TAB 3: GALLERY ----------
  List<Widget> _galleryTab() => [
        _sheetTitle("Campus Gallery", "${_campusPhotos.length} photos"),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _campusPhotos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, mainAxisExtent: 130),
          itemBuilder: (_, i) {
            final p = _campusPhotos[i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(fit: StackFit.expand, children: [
                _CampusImage(path: p['path'] as String, icon: p['icon'] as IconData, color: p['color'] as Color),
                _fade(56, 0.6),
                Positioned(left: 10, right: 10, bottom: 8, child: Text(p['caption'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(12.5, FontWeight.w700, Colors.white))),
                Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: () => _openPhotoViewer(_campusPhotos, i)))),
              ]),
            );
          },
        ),
      ];

  // ---------- SEARCH RESULTS ----------
  List<Widget> _searchResults() {
    final theme = Theme.of(context), q = _searchQuery.trim().toLowerCase();
    final places = _visibleLocations;
    final depts = _departments.where((d) => (d['name'] as String).toLowerCase().contains(q) || (d['short'] as String).toLowerCase().contains(q)).toList();
    final total = places.length + depts.length;

    Widget heading(String t) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 2), child: Text(t, style: _ts(13.5, FontWeight.w800, _headingOf(theme))));

    return [
      _sheetTitle("Search Results", "$total found"),
      const SizedBox(height: 14),
      if (total == 0) _emptyNote(Icons.search_off_rounded, "Nothing found for \"${_searchQuery.trim()}\"."),
      if (places.isNotEmpty) ...[heading("Places"), _groupedCard(places.map(_placeRow).toList()), const SizedBox(height: 16)],
      if (depts.isNotEmpty) ...[heading("Departments"), _groupedCard(depts.map(_departmentRow).toList())],
    ];
  }

  // ---------- DEPARTMENT DETAIL ----------
  List<Widget> _departmentDetail(Map<String, dynamic> d) {
    final theme = Theme.of(context), c = d['color'] as Color;
    final images = (d['images'] as List).cast<String>(), loc = _locationById(d['locationId'] as String);
    final photos = [for (int i = 0; i < images.length; i++) {"path": images[i], "caption": "${d['name']} • Photo ${i + 1}", "icon": d['icon'], "color": c}];

    return [
      _detailTopBar("Departments"),
      const SizedBox(height: 14),
      _photoCarousel(d['id'] as String, photos, d['icon'] as IconData, c),
      const SizedBox(height: 14),
      if (loc != null) _locationCloudPhotos(loc, c),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: Text(d['name'] as String, style: _ts(20, FontWeight.w800, _headingOf(theme), h: 1.2))),
        const SizedBox(width: 8),
        _tag(d['short'] as String, c.withOpacity(0.12), c),
      ]),
      const SizedBox(height: 6),
      Text("HOD: ${d['hod']}", style: _ts(13, FontWeight.w600, theme.hintColor)),
      if (loc != null) ...[
        const SizedBox(height: 10),
        _tag("${loc['name']}  •  ${loc['floors']} floors", _tintOf(theme), _iconOf(theme), icon: Icons.place_outlined),
      ],
      const SizedBox(height: 14),
      Text(d['about'] as String, style: _ts(13.5, FontWeight.w400, theme.hintColor, h: 1.45)),
      const SizedBox(height: 16),
      Row(children: [
        _statTile("${d['students']}", "Students"),
        const SizedBox(width: 10),
        _statTile("${d['faculty']}", "Faculty"),
        const SizedBox(width: 10),
        _statTile("${d['labs']}", "Labs"),
      ]),
      const SizedBox(height: 18),
      Text("Facilities", style: _ts(14, FontWeight.w800, _headingOf(theme))),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (d['facilities'] as List).map((f) => _tag(f as String, Colors.green.withOpacity(0.12), Colors.green.shade700, icon: Icons.check_circle_outline_rounded)).toList(),
      ),
      const SizedBox(height: 20),
      _actionButtons(),
    ];
  }

  Widget _statTile(String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: _tintOf(theme), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(value, style: _ts(18, FontWeight.w800, _headingOf(theme))),
          const SizedBox(height: 2),
          Text(label, style: _ts(11.5, FontWeight.w600, theme.hintColor)),
        ]),
      ),
    );
  }

  // ---------- LOCATION DETAIL ----------
  List<Widget> _locationDetail(Map<String, dynamic> loc) {
    final theme = Theme.of(context), c = _catColor(loc['category'] as String), floors = loc['floors'] as int;
    final deptsHere = _departments.where((d) => d['locationId'] == loc['id']).toList();

    return [
      _detailTopBar("Places"),
      const SizedBox(height: 14),
      _locationCloudPhotos(loc, c),
      const SizedBox(height: 16),
      Row(children: [
        _iconBox(loc['icon'] as IconData, c, size: 46, iconSize: 24, r: 15),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc['name'] as String, style: _ts(19, FontWeight.w800, _headingOf(theme))),
            Text(loc['category'] as String, style: _ts(12.5, FontWeight.w600, theme.hintColor)),
          ]),
        ),
      ]),
      const SizedBox(height: 14),
      Text(loc['desc'] as String, style: _ts(13.5, FontWeight.w400, theme.hintColor, h: 1.45)),
      const SizedBox(height: 16),
      if (floors > 0) ...[
        Text("Select Floor", style: _ts(13, FontWeight.w800, _headingOf(theme))),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: floors + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _selectedFloor == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedFloor = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  decoration: BoxDecoration(color: sel ? _primary : _tintOf(theme), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(i == 0 ? "G" : "$i", style: _ts(13, FontWeight.w800, sel ? Colors.white : _iconOf(theme)))),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(_selectedFloor == 0 ? "Ground floor" : "Floor $_selectedFloor", style: _ts(12, FontWeight.w400, theme.hintColor)),
        const SizedBox(height: 16),
      ],
      if (deptsHere.isNotEmpty) ...[
        Text("Departments here", style: _ts(13, FontWeight.w800, _headingOf(theme))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: deptsHere.map((d) {
            final dc = d['color'] as Color;
            return InkWell(borderRadius: BorderRadius.circular(12), onTap: () => _selectDepartment(d), child: _tag(d['short'] as String, dc.withOpacity(0.12), dc, icon: d['icon'] as IconData));
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
      _actionButtons(),
    ];
  }

  // ---------- SHARED DETAIL PIECES ----------
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
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _iconOf(theme)),
            const SizedBox(width: 6),
            Text(backLabel, style: _ts(12.5, FontWeight.w700, _iconOf(theme))),
          ]),
        ),
      ),
    );
  }

  // Swipeable photos + dots
  Widget _photoCarousel(String keyId, List<Map<String, dynamic>> photos, IconData icon, Color color) {
    final theme = Theme.of(context), count = max(photos.length, 1);
    return Column(children: [
      SizedBox(
        height: 200,
        child: PageView.builder(
          key: ValueKey(keyId), // new department = carousel restarts at photo 1
          itemCount: count,
          onPageChanged: (i) => setState(() => _photoIndex = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: photos.isEmpty ? null : () => _openPhotoViewer(photos, i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(fit: StackFit.expand, children: [
                  _CampusImage(path: photos.isEmpty ? '' : photos[i]['path'] as String, icon: icon, color: color),
                  if (photos.isNotEmpty) Positioned(top: 10, right: 10, child: _frosted("${i + 1}/${photos.length}", Icons.photo_outlined)),
                ]),
              ),
            ),
          ),
        ),
      ),
      if (count > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final active = i == _photoIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: active ? _iconOf(theme) : theme.hintColor.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
            );
          }),
        ),
      ],
    ]);
  }

  Widget _actionButtons() {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _clearSelection,
          icon: const Icon(Icons.close, size: 18),
          label: const Text("Close", style: TextStyle(fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(foregroundColor: theme.hintColor, side: BorderSide(color: theme.dividerColor), padding: const EdgeInsets.symmetric(vertical: 13), shape: shape),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _showOnMap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text("Show on map", style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: shape),
        ),
      ),
    ]);
  }

  // ======================= SHARED SMALL WIDGETS =======================
  Widget _sheetTitle(String title, String trailing) {
    final theme = Theme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(title, style: _ts(18, FontWeight.w800, _headingOf(theme))),
      const Spacer(),
      Text(trailing, style: _ts(12, FontWeight.w600, theme.hintColor)),
    ]);
  }

  Widget _iconBox(IconData icon, Color c, {double size = 42, double iconSize = 22, double r = 13}) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(r)),
        child: Icon(icon, color: c, size: iconSize),
      );

  // small coloured label (optionally with icon)
  Widget _tag(String text, Color bg, Color fg, {IconData? icon}) => Container(
        padding: EdgeInsets.symmetric(horizontal: icon == null ? 9 : 10, vertical: icon == null ? 4 : 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(icon == null ? 8 : 10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 5)],
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(icon == null ? 10.5 : 11.5, FontWeight.w800, fg))),
        ]),
      );

  // dark pill readable on top of photos
  Widget _frosted(String text, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: _ts(11, FontWeight.w700, Colors.white)),
        ]),
      );

  // dark fade at the bottom of photos
  Widget _fade(double h, double a) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(a)])),
        ),
      );

  BoxDecoration _cardDeco(ThemeData t) => BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.dividerColor.withOpacity(0.6)),
      );

  Widget _groupedCard(List<Widget> rows) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: _cardDeco(theme),
      child: Material(
        color: Colors.transparent,
        child: Column(children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 68, color: theme.dividerColor.withOpacity(0.7)),
            rows[i],
          ],
        ]),
      ),
    );
  }

  Widget _emptyNote(IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(theme),
      child: Row(children: [
        Icon(icon, color: theme.hintColor, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: _ts(13, FontWeight.w400, theme.hintColor, h: 1.35))),
      ]),
    );
  }
}

// ======================= PHOTO WIDGET (asset / http, with placeholder) =======================
class _CampusImage extends StatelessWidget {
  final String path;
  final IconData icon;
  final Color color;
  final BoxFit fit;
  const _CampusImage({required this.path, required this.icon, required this.color, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.65)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Icon(icon, size: 40, color: Colors.white.withOpacity(0.85))),
    );
    if (path.isEmpty) return placeholder;
    if (path.startsWith('http')) {
      return Image.network(path, fit: fit, errorBuilder: (_, __, ___) => placeholder, loadingBuilder: (_, child, p) => p == null ? child : placeholder);
    }
    return Image.asset(path, fit: fit, errorBuilder: (_, __, ___) => placeholder);
  }
}

// ======================= FULL-SCREEN PHOTO VIEWER (swipe + pinch zoom) =======================
class _PhotoViewerPage extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;
  const _PhotoViewerPage({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late final _pageController = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final glass = Colors.white.withOpacity(0.18);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final p = photos[i];
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: SizedBox.expand(child: _CampusImage(path: p['path'] as String, icon: p['icon'] as IconData, color: p['color'] as Color, fit: BoxFit.contain)),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: glass, fixedSize: const Size(44, 44)),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: glass, borderRadius: BorderRadius.circular(12)),
                  child: Text("${_index + 1} / ${photos.length}", style: _ts(13, FontWeight.w700, Colors.white)),
                ),
              ]),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Text("${photos[_index]['caption']}", textAlign: TextAlign.center, style: _ts(15, FontWeight.w700, Colors.white)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}