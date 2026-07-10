import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  final LatLng collegeGate = const LatLng(19.1383, 77.3210);
  final LatLng canteen = const LatLng(19.1386, 77.3213);
  final LatLng parking = const LatLng(19.1380, 77.3207);
  final LatLng library = const LatLng(19.1385, 77.3215);
  final LatLng adminBlock = const LatLng(19.1387, 77.3211);
  final LatLng chemistryDept = const LatLng(19.1389, 77.3209);
  final LatLng physicsDept = const LatLng(19.1390, 77.3212);
  final LatLng computerDept = const LatLng(19.1391, 77.3214);
  final LatLng zoologyDept = const LatLng(19.1384, 77.3218);
  final LatLng sportsGround = const LatLng(19.1378, 77.3216);

  String selectedKey = "gate";

  late final List<Map<String, dynamic>> locations = [
    {
      "key": "gate", "label": "College Gate", "icon": Icons.school_outlined, "point": collegeGate,
      "description": "Main entrance of the college campus.",
      "images": ["https://picsum.photos/seed/gate1/800/600", "https://picsum.photos/seed/gate2/800/600"],
    },
    {
      "key": "admin", "label": "Admin Block", "icon": Icons.apartment_outlined, "point": adminBlock,
      "description": "Administrative office and principal's cabin.",
      "images": ["https://picsum.photos/seed/admin1/800/600", "https://picsum.photos/seed/admin2/800/600"],
    },
    {
      "key": "library", "label": "Library", "icon": Icons.menu_book_outlined, "point": library,
      "description": "Central library with study halls and reading rooms.",
      "images": ["https://picsum.photos/seed/lib1/800/600", "https://picsum.photos/seed/lib2/800/600"],
    },
    {
      "key": "canteen", "label": "Canteen", "icon": Icons.restaurant_outlined, "point": canteen,
      "description": "Campus canteen serving snacks and meals.",
      "images": ["https://picsum.photos/seed/canteen1/800/600", "https://picsum.photos/seed/canteen2/800/600"],
    },
    {
      "key": "parking", "label": "Parking", "icon": Icons.local_parking_outlined, "point": parking,
      "description": "Two-wheeler and four-wheeler parking area.",
      "images": ["https://picsum.photos/seed/parking1/800/600", "https://picsum.photos/seed/parking2/800/600"],
    },
    {
      "key": "chemistry", "label": "Chemistry Dept", "icon": Icons.science_outlined, "point": chemistryDept,
      "description": "Chemistry labs and faculty offices.",
      "images": ["https://picsum.photos/seed/chem1/800/600", "https://picsum.photos/seed/chem2/800/600"],
    },
    {
      "key": "physics", "label": "Physics Dept", "icon": Icons.bolt_outlined, "point": physicsDept,
      "description": "Physics labs and lecture halls.",
      "images": ["https://picsum.photos/seed/phy1/800/600", "https://picsum.photos/seed/phy2/800/600"],
    },
    {
      "key": "computer", "label": "Computer Dept", "icon": Icons.computer_outlined, "point": computerDept,
      "description": "Computer labs with high-speed internet access.",
      "images": ["https://picsum.photos/seed/comp1/800/600", "https://picsum.photos/seed/comp2/800/600"],
    },
    {
      "key": "zoology", "label": "Zoology Dept", "icon": Icons.pets_outlined, "point": zoologyDept,
      "description": "Zoology labs and specimen museum.",
      "images": ["https://picsum.photos/seed/zoo1/800/600", "https://picsum.photos/seed/zoo2/800/600"],
    },
    {
      "key": "sports", "label": "Sports Ground", "icon": Icons.sports_soccer_outlined, "point": sportsGround,
      "description": "Ground for outdoor sports and annual events.",
      "images": ["https://picsum.photos/seed/sports1/800/600", "https://picsum.photos/seed/sports2/800/600"],
    },
  ];

  // 👇 Marker sirf map-behavior karega - koi photo sheet nahi
  Set<Marker> _buildMarkers() {
    return locations.map((loc) {
      return Marker(
        markerId: MarkerId(loc["key"]),
        position: loc["point"],
        infoWindow: InfoWindow(title: loc["label"], snippet: loc["description"]),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selectedKey == loc["key"] ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
        ),
        onTap: () {
          // 👇 Sirf selection update + camera move, PHOTOS NAHI khulenge
          setState(() => selectedKey = loc["key"]);
        },
      );
    }).toSet();
  }

  void _moveCamera(LatLng point, String key) {
    setState(() => selectedKey = key);
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 19)),
    );
  }

  // 👇 Ye sirf BOTTOM CARD se call hoga - yahi photos dikhayega
  void _openLocationPhotos(Map<String, dynamic> loc) {
    setState(() => selectedKey = loc["key"]);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationDetailSheet(
        location: loc,
        onViewOnMap: () {
          Navigator.pop(context);
          _moveCamera(loc["point"], loc["key"]); // "View on Map" se hi map move hoga
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Map", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: collegeGate, zoom: 17),
            markers: _buildMarkers(),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: true,
            padding: const EdgeInsets.only(bottom: 170, top: 10, right: 10),
            onMapCreated: (controller) => mapController = controller,
          ),

          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _RoundIconButton(
                  icon: Icons.add,
                  onTap: () => mapController.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 10),
                _RoundIconButton(
                  icon: Icons.remove,
                  onTap: () => mapController.animateCamera(CameraUpdate.zoomOut()),
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 14, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Campus Locations",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text("Tap for photos", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: locations.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final loc = locations[index];
                        final isSelected = selectedKey == loc["key"];

                        return GestureDetector(
                          // 👇 SIRF ye card photos kholega - map nahi hilega
                          onTap: () => _openLocationPhotos(loc),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 82,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: 1.2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(loc["icon"], color: isSelected ? Colors.white : Colors.blue, size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  loc["label"],
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.blue, size: 22),
        ),
      ),
    );
  }
}

class _LocationDetailSheet extends StatefulWidget {
  final Map<String, dynamic> location;
  final VoidCallback onViewOnMap;

  const _LocationDetailSheet({required this.location, required this.onViewOnMap});

  @override
  State<_LocationDetailSheet> createState() => _LocationDetailSheetState();
}

class _LocationDetailSheetState extends State<_LocationDetailSheet> {
  int currentPage = 0;
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = List<String>.from(widget.location["images"] ?? []);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: pageController,
                            itemCount: images.isEmpty ? 1 : images.length,
                            onPageChanged: (i) => setState(() => currentPage = i),
                            itemBuilder: (context, index) {
                              if (images.isEmpty) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(widget.location["icon"], size: 60, color: Colors.grey.shade400),
                                );
                              }
                              return ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                child: Image.network(
                                  images[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                  errorBuilder: (context, error, stack) => Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(widget.location["icon"], size: 60, color: Colors.grey.shade400),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (images.length > 1)
                            Positioned(
                              bottom: 14,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (i) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: currentPage == i ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: currentPage == i ? Colors.white : Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), shape: BoxShape.circle),
                                child: Icon(widget.location["icon"], color: Colors.blue, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.location["label"],
                                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.location["description"] ?? "",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: widget.onViewOnMap,
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text("View on Map"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}