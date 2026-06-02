import 'package:csen268_final_project/routes/app_routes.dart';
import 'package:csen268_final_project/services/auth_service.dart';
import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedFilter = 0;
  final _filters = ['All', 'Today', 'Tomorrow', 'Weekend Only'];
  final AuthService _auth = AuthService();
  List<Map<String, dynamic>> _scheduledFavorites = [];
  Map<String, List<Map<String, dynamic>>> _grouped = {};
  bool _isLoading = true;

  final _events = [
    {
      'day': 'Fri',
      'date': '10',
      'title': 'Estate Sale',
      'subtitle': 'Fri. Apr 10 · 12:00pm · San Jose',
      'favorited': false,
    },
    {
      'day': 'Sat',
      'date': '11',
      'title': 'Neighborhood Garage Sale',
      'subtitle': 'Sat. Apr 11 · 2:00pm · San Jose',
      'favorited': false,
    },
    {
      'day': 'Sat',
      'date': '11',
      'title': 'Yard Sale',
      'subtitle': 'Sat. Apr 11 · 3:30pm · San Jose',
      'favorited': false,
    },
    {
      'day': 'Sun',
      'date': '12',
      'title': 'Kitchen and Bath Yard Sale',
      'subtitle': 'Sun. Apr 12 · 10:30am · San Jose',
      'favorited': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setFavorites();
  }

  void _setFavorites() async {
    setState(() {
      _isLoading = true;
    });
    _scheduledFavorites = await _auth.fetchUserFavorites();
    final Map<String, List<Map<String, dynamic>>> grouped_fav = _seperateGroups();
    setState(() {
      _grouped = grouped_fav;
      _isLoading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _seperateGroups() {
    if(_scheduledFavorites.isEmpty) return {};
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final event in _scheduledFavorites) {
      event['subtitle'] = "${event['date']??''} · ${event['starttime']??''}";
      final List<String> splitDate = event['date']?.toString().split(',').toList() ?? ['Sun','Dec 31'];
      if (splitDate.length < 2) continue;
      final key ='${splitDate[0]}-${splitDate[1]}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(event);
    }
    print(grouped);
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    
    final Map<String, List<Map<String, dynamic>>> grouped = _grouped;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2B5BA8)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.chevron_left,
                          color: Color(0xFF2B5BA8), size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Favorite',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF2B5BA8),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle_outlined,
                        color: Color(0xFF2B5BA8)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Upcoming Schedule button
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2B5BA8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Upcoming Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = _selectedFilter == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE8843A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFE8843A)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Events list
            Expanded(
              child: _isLoading 
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE8843A)),
                )
              :
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: grouped.entries.map((entry) {
                  final parts = entry.key.split('-');
                  final dayName = parts[0];
                  final dateNum = parts[1].split(" ").last ?? '1';
                  final events = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date box
                          Container(
                            width: 64,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFF2B5BA8), width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2B5BA8),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    dayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    dateNum,
                                    style: const TextStyle(
                                      color: Color(0xFF2B5BA8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Event cards
                          Expanded(
                            child: Column(
                              children: events
                                  .map((event) => _EventCard(event: event)) // HERE
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFFD0DDEE)),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  const _EventCard({required this.event});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  // bool _favorited = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFECFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1B3A6B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.event['subtitle'] as String,
                  style: const TextStyle(
                      color: Color(0xFF4A6B9A), fontSize: 12),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.details,
                          arguments: widget.event,
                        ),
                  child: Row(
                    children: [
                      const Text(
                        'details ',
                        style: TextStyle(
                          color: Color(0xFF1B3A6B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 13, color: Color(0xFF1B3A6B)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // IconButton(
          //   icon: Icon(
          //     _favorited ? Icons.favorite : Icons.favorite_border,
          //     color: _favorited ? Colors.red : Colors.grey,
          //     size: 20,
          //   ),
          //   onPressed: () => setState(() => _favorited = !_favorited),
          //   padding: EdgeInsets.zero,
          //   constraints: const BoxConstraints(),
          // ),
        ],
      ),
    );
  }
}
