class FilterData {
  final List<String> categories;
  final String sortBy;
  final String distance;
  final double? minPrice;
  final double? maxPrice;

  const FilterData({
    required this.categories,
    required this.sortBy,
    required this.distance,
    this.minPrice,
    this.maxPrice,
  });
}