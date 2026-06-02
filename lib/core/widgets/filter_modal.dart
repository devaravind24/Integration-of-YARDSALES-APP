import 'package:flutter/material.dart';
import 'filter_data.dart';

class FilterModal extends StatefulWidget {
  final FilterData? initialFilter;
  const FilterModal({
    super.key,
    this.initialFilter,
  });
  static Future<FilterData?> show(
  BuildContext context,
  FilterData? currentFilter,
) {
  return showModalBottomSheet<FilterData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FilterModal(
      initialFilter: currentFilter,
    ),
  );
}
  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  final List<String> _categories = [
    'electronics',
    'furniture',
    'toys',
    'books',
  ];

   final List<String> _selectedCategories = [
    'electronics',
    'furniture',
    'toys',
    'books',
  ];

  final List<String> _sortOptions = [
    'Popularity',
    'Nearest',
    'Newest',
    'High Price',
    'Low Price',
    'Review'
  ];
  String _selectedSort = 'Popularity';

  final List<String> _distances = ['1 mi', '5 mi', '10 mi', '20 mi'];
  String _selectedDistance = '';

  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialFilter != null) {
      _selectedCategories
        ..clear()
        ..addAll(widget.initialFilter!.categories);

      _selectedSort = widget.initialFilter!.sortBy;
      _selectedDistance = widget.initialFilter!.distance;

      _minController.text =
          widget.initialFilter!.minPrice?.toString() ?? '';

      _maxController.text =
          widget.initialFilter!.maxPrice?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _selectedCategories
        ..clear()
        ..addAll(_categories);
      _selectedSort = 'Popularity';
      _selectedDistance = '';
      _minController.clear();
      _maxController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Card ─────────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                const Text(
                                  'Filter',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close,
                                      color: Colors.black54, size: 22),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const _SectionLabel('Category'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((cat) {
                                final selected =
                                    _selectedCategories.contains(cat);
                                return _FilterChip(
                                  label: cat,
                                  selected: selected,
                                  filled: selected,
                                  onTap: () => setState(() {
                                    if (selected) {
                                      _selectedCategories.remove(cat);
                                    } else {
                                      _selectedCategories.add(cat);
                                    }
                                  }),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),

                            const _SectionLabel('Sort By'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _sortOptions.map((opt) {
                                final selected = _selectedSort == opt;
                                return _FilterChip(
                                  label: opt,
                                  selected: selected,
                                  filled: selected,
                                  onTap: () =>
                                      setState(() => _selectedSort = opt),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),

                            const _SectionLabel('Distance'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _distances.map((d) {
                                final selected = _selectedDistance == d;
                                return _FilterChip(
                                  label: d,
                                  selected: selected,
                                  filled:
                                      false, // distance chips are outline-only
                                  onTap: () =>
                                      setState(() => _selectedDistance = d),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 22),

                            const _SectionLabel('Price Range'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _PriceField(
                                    hint: 'Min Price',
                                    controller: _minController,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PriceField(
                                    hint: 'Max Price',
                                    controller: _maxController,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              FilterData(
                                categories: List.from(_selectedCategories),
                                sortBy: _selectedSort,
                                distance: _selectedDistance,
                                minPrice: double.tryParse(_minController.text),
                                maxPrice: double.tryParse(_maxController.text),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8843A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _reset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFE8843A).withOpacity(0.75),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool filled;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected && filled;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8843A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFE8843A) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  const _PriceField({required this.hint, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE8843A), width: 1.5),
        ),
      ),
    );
  }
}
