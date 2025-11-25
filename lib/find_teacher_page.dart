import 'package:flutter/material.dart';
import 'api_service.dart';
import 'timetable_model.dart';

class FindTeacherPage extends StatefulWidget {
  const FindTeacherPage({super.key});

  @override
  State<FindTeacherPage> createState() => _FindTeacherPageState();
}

class _FindTeacherPageState extends State<FindTeacherPage> {
  List<TeacherSearchResult> _results = [];
  bool _isLoading = false;
  String? _error;

  // Function to handle manual search (e.g., pressing Enter)
  void _manualSearch(String query) async {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name to search')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      final teachers = await ApiService.searchTeachers(query);
      setState(() {
        _results = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to find teachers. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Teacher'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar Area with Autocomplete
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Autocomplete<TeacherSearchResult>(
              // 1. Define how to display the option in the text field
              displayStringForOption: (TeacherSearchResult option) => option.name,

              // 2. Fetch options from API as user types
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<TeacherSearchResult>.empty();
                }
                try {
                  return await ApiService.searchTeachers(textEditingValue.text);
                } catch (e) {
                  return const Iterable<TeacherSearchResult>.empty();
                }
              },

              // 3. Handle selection from dropdown
              onSelected: (TeacherSearchResult selection) {
                setState(() {
                  // Show the selected teacher immediately
                  _results = [selection];
                  _error = null;
                });
              },

              // 4. Build the Input Field
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) => _manualSearch(val),
                  decoration: InputDecoration(
                    hintText: 'Search by teacher name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    // Clear Button
                    suffixIcon: textEditingController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              textEditingController.clear();
                              setState(() {
                                _results = [];
                                _error = null;
                              });
                            },
                          )
                        : null,
                  ),
                );
              },

              // 5. Build the Dropdown List Options
              // ✅ FIX: Used Container instead of SizedBox to support 'constraints'
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    child: Container( 
                      width: MediaQuery.of(context).size.width - 32, // Match width of search box (screen - padding)
                      constraints: const BoxConstraints(maxHeight: 250), // Limit height
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (option.image != null && option.image!.isNotEmpty)
                                  ? NetworkImage(option.image!)
                                  : const NetworkImage("https://i.pravatar.cc/150?img=11"),
                            ),
                            title: Text(
                              option.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              option.dept,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.black54,
                              ),
                            ),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Results List (The Cards)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search_outlined, size: 80, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text("No teachers found", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              return _buildTeacherCard(_results[index], isDark);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(TeacherSearchResult teacher, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAvailable = teacher.availability;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Hero(
                  tag: teacher.id,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAvailable ? Colors.green : Colors.red,
                        width: 3,
                      ),
                      image: DecorationImage(
                        image: (teacher.image != null && teacher.image!.isNotEmpty)
                            ? NetworkImage(teacher.image!)
                            : const NetworkImage("https://i.pravatar.cc/150?img=11"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teacher.dept,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Availability Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAvailable ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAvailable ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: isAvailable ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAvailable ? "In Cabin / Available" : "Not Available",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isAvailable ? Colors.green : Colors.red,
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
          ),

          // Cabin Info Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.room, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  "Cabin: ",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  teacher.cabinRoom,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}