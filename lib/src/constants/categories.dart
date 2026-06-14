import '../types/category.dart';

const defaultCurrencyCodes = ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR', 'INR'];

const categoryColors = {
  'electricity': '#F4B740',
  'gas': '#E8805D',
  'grocery': '#8FD6B5',
  'internet': '#7EA6C8',
  'water': '#77C8D4',
  'rent': '#A88CC2',
  'maintenance': '#C09366',
  'other': '#9A958B',
};

List<Category> buildDefaultCategories(DateTime now) {
  final timestamp = now.toIso8601String();
  return [
    Category(id: 'electricity', name: 'Electricity', icon: 'bolt', color: categoryColors['electricity']!, isDefault: true, createdAt: timestamp, updatedAt: timestamp),
    Category(id: 'gas', name: 'Gas', icon: 'local_fire_department', color: categoryColors['gas']!, isDefault: true, createdAt: timestamp, updatedAt: timestamp),
    Category(id: 'grocery', name: 'Grocery', icon: 'shopping_basket', color: categoryColors['grocery']!, isDefault: true, createdAt: timestamp, updatedAt: timestamp),
    Category(id: 'internet', name: 'Internet', icon: 'wifi', color: categoryColors['internet']!, isDefault: true, createdAt: timestamp, updatedAt: timestamp),
    Category(id: 'water', name: 'Water', icon: 'water_drop', color: categoryColors['water']!, isDefault: true, createdAt: timestamp, updatedAt: timestamp),
    Category(id: 'rent', name: 'Rent', icon: 'home', color: categoryColors['rent']!, isDefault: true, createdAt: timestamp, updatedAt: timestamp),
    Category(id: 'maintenance', name: 'Maintenance', icon: 'build', color: categoryColors['maintenance']!, isDefault: true, createdAt: timestamp, updatedAt: timestamp),
    Category(id: 'other', name: 'Other', icon: 'more_horiz', color: categoryColors['other']!, isDefault: true, createdAt: timestamp, updatedAt: timestamp),
  ];
}
