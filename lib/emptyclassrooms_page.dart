// lib/emptyclassrooms_page.dart
import 'package:flutter/material.dart';

class EmptyClassroomsPage extends StatefulWidget {
  final String userBranch;
  final String userSection;

  const EmptyClassroomsPage({
    super.key,
    required this.userBranch,
    required this.userSection,
  });

  @override
  State<EmptyClassroomsPage> createState() => _EmptyClassroomsPageState();
}

class _EmptyClassroomsPageState extends State<EmptyClassroomsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String selectedFloor = 'All Floors';
  String selectedType = 'All';
  String searchQuery = '';

  // Room occupancy tracking with branch and section info
  // Structure: {roomName: {'occupied': true/false, 'branch': 'CSE', 'section': 'A'}}
  final Map<String, Map<String, dynamic>> _roomStatus = {
    // Initially occupied rooms
    'N001': {'occupied': true, 'branch': 'CSE', 'section': 'A'},
    'N002': {'occupied': true, 'branch': 'ECE', 'section': 'B'},
    'N005': {'occupied': true, 'branch': 'MECH', 'section': 'A'},
    'S003': {'occupied': true, 'branch': 'CSE', 'section': 'B'},
    'S007': {'occupied': true, 'branch': 'EEE', 'section': 'A'},
    'N101': {'occupied': true, 'branch': 'CIVIL', 'section': 'A'},
    'N105': {'occupied': true, 'branch': 'IT', 'section': 'B'},
    'S104': {'occupied': true, 'branch': 'CSE', 'section': 'C'},
    'S108': {'occupied': true, 'branch': 'ECE', 'section': 'A'},
    'N011L': {'occupied': true, 'branch': 'CSE', 'section': 'A'},
    'S012L': {'occupied': true, 'branch': 'ECE', 'section': 'B'},
    'N201': {'occupied': true, 'branch': 'MECH', 'section': 'B'},
    'N204': {'occupied': true, 'branch': 'EEE', 'section': 'B'},
    'S202': {'occupied': true, 'branch': 'CIVIL', 'section': 'B'},
    'S209': {'occupied': true, 'branch': 'IT', 'section': 'A'},
  };
  // Generate classrooms dynamically
  List<Map<String, dynamic>> _generateClassrooms() {
    final List<Map<String, dynamic>> classrooms = [];

    // Generate rooms for each floor
    final floors = ['1st Floor', '2nd Floor', '3rd Floor'];
    final wings = ['N', 'S'];

    for (int floorIndex = 0; floorIndex < floors.length; floorIndex++) {
      for (String wing in wings) {
        // Generate 11 classrooms per wing per floor (00-10)
        for (int roomNum = 0; roomNum <= 10; roomNum++) {
          final roomCode =
              '$wing${floorIndex}${roomNum.toString().padLeft(2, '0')}';
          classrooms.add({
            'name': roomCode,
            'floor': floors[floorIndex],
            'capacity': 50 + (roomNum * 5), // Varying capacity
            'type': 'Class',
            'wing': wing,
          });
        }

        // Add 2 labs per wing per floor
        for (int labNum = 1; labNum <= 2; labNum++) {
          final labCode = '$wing${floorIndex}${(10 + labNum).toString()}L';
          classrooms.add({
            'name': labCode,
            'floor': floors[floorIndex],
            'capacity': 30 + (labNum * 5),
            'type': 'Lab',
            'wing': wing,
          });
        }
      }
    }

    return classrooms;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredClassrooms {
    final allClassrooms = _generateClassrooms();

    return allClassrooms.where((room) {
      final matchesFloor =
          selectedFloor == 'All Floors' || room['floor'] == selectedFloor;
      final matchesType = selectedType == 'All' || room['type'] == selectedType;
      final matchesSearch = room['name'].toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      return matchesFloor && matchesType && matchesSearch;
    }).toList();
  }

  int get occupiedCount =>
      _roomStatus.values.where((status) => status['occupied'] == true).length;

  int get availableCount {
    final totalRooms = _generateClassrooms().length;
    return totalRooms - occupiedCount;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.filter_list,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Filter by Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('All', Icons.grid_view_rounded),
              const SizedBox(height: 12),
              _buildFilterOption('Class', Icons.class_rounded),
              const SizedBox(height: 12),
              _buildFilterOption('Lab', Icons.science_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String type, IconData icon) {
    final isSelected = selectedType == type;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          selectedType = type;
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : scheme.outlineVariant.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? scheme.primary : scheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: scheme.primary, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            actions: [
              // Filter Button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.white),
                        if (selectedType != 'All')
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 8,
                                minHeight: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter',
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Classroom Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                        : [const Color(0xFF00ACC1), const Color(0xFF26C6DA)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.meeting_room,
                        size: 180,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Statistics Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Occupied',
                          occupiedCount.toString(),
                          Icons.door_front_door,
                          const Color(0xFFEF4444),
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Available',
                          availableCount.toString(),
                          Icons.meeting_room_outlined,
                          const Color(0xFF10B981),
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search classrooms...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Floor Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Floors', scheme),
                        _buildFilterChip('1st Floor', scheme),
                        _buildFilterChip('2nd Floor', scheme),
                        _buildFilterChip('3rd Floor', scheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Classroom Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final room = filteredClassrooms[index];
                return _buildClassroomCard(context, room, isDark);
              }, childCount: filteredClassrooms.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ColorScheme scheme) {
    final isSelected = selectedFloor == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => selectedFloor = label),
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildClassroomCard(
    BuildContext context,
    Map<String, dynamic> room,
    bool isDark,
  ) {
    final roomName = room['name'];
    final roomStatus = _roomStatus[roomName];
    final isOccupied = roomStatus?['occupied'] == true;
    final isLab = room['type'] == 'Lab';

    final statusColor = isOccupied
        ? const Color(0xFFEF4444) // Red for occupied
        : const Color(0xFF10B981); // Green for available
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showClassroomDetails(context, room),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator header
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.6)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room icon and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isLab
                                ? Icons.science_rounded
                                : (isOccupied
                                      ? Icons.door_front_door
                                      : Icons.meeting_room_outlined),
                            color: statusColor,
                            size: 24,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOccupied ? 'OCCUPIED' : 'AVAILABLE',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Room name
                    Text(
                      roomName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isLab
                            ? const Color(0xFFFF9800).withOpacity(0.15)
                            : const Color(0xFF00ACC1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLab ? Icons.science_rounded : Icons.class_rounded,
                            size: 11,
                            color: isLab
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF00ACC1),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            room['type'],
                            style: TextStyle(
                              fontSize: 10,
                              color: isLab
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF00ACC1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Floor info
                    Row(
                      children: [
                        Icon(
                          Icons.layers,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          room['floor'],
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Capacity
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${room['capacity']} seats',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // Branch-Section if occupied
                    if (isOccupied && roomStatus != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${roomStatus['branch']}-${roomStatus['section']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassroomDetails(BuildContext context, Map<String, dynamic> room) {
    final roomName = room['name'];
    final roomStatus = _roomStatus[roomName];
    final isOccupied = roomStatus?['occupied'] == true;
    final isAvailable = !isOccupied;

    final statusColor = isOccupied
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Room name with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isOccupied
                        ? Icons.door_front_door
                        : Icons.meeting_room_outlined,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roomName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOccupied ? 'OCCUPIED' : 'AVAILABLE',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Details
            _buildDetailRow(Icons.category, 'Type', room['type'], scheme),
            _buildDetailRow(Icons.layers, 'Floor', room['floor'], scheme),
            _buildDetailRow(
              Icons.people,
              'Capacity',
              '${room['capacity']} seats',
              scheme,
            ),

            if (isOccupied && roomStatus != null) ...[
              _buildDetailRow(
                Icons.business,
                'Branch',
                roomStatus['branch'] ?? 'Unknown',
                scheme,
              ),
              _buildDetailRow(
                Icons.group,
                'Section',
                roomStatus['section'] ?? 'Unknown',
                scheme,
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            if (isAvailable) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _roomStatus[roomName] = {
                        'occupied': true,
                        'branch': widget.userBranch,
                        'section': widget.userSection,
                      };
                    });
                    Navigator.pop(bCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✓ Room occupied by ${widget.userBranch}-${widget.userSection}',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.meeting_room),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Occupy This Room',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(bCtx),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _roomStatus[roomName] = {
                        'occupied': false,
                        'branch': null,
                        'section': null,
                      };
                    });
                    Navigator.pop(bCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Room marked as available'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_open),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Mark as Available',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(bCtx),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Close', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
