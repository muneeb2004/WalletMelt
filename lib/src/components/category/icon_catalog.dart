/// The built-in icon bank shown in the icon picker.
///
/// Ids are stored on categories, so existing ids must never change meaning.
library;

class CategoryPreset {
  const CategoryPreset({
    required this.id,
    required this.label,
    required this.assetPath,
    this.group = 'More',
    this.keywords = const [],
  });

  final String id;
  final String label;
  final String assetPath;
  final String group;
  final List<String> keywords;

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q) ||
        id.toLowerCase().contains(q) ||
        keywords.any((k) => k.contains(q));
  }
}

const String _presets = 'assets/icons/categories/presets';
const String _std = 'assets/icons/categories';

/// Section order in the picker.
const List<String> iconGroups = [
  'Food',
  'Transport',
  'Bills',
  'Home',
  'Shopping',
  'Health',
  'Education',
  'Money',
  'Leisure',
  'Family',
  'More',
];

const List<CategoryPreset> categoryPresets = [
  // Food
  CategoryPreset(id: 'food_dining', label: 'Food & Dining', assetPath: '$_presets/food_dining.svg', group: 'Food', keywords: ['eat', 'meal', 'lunch', 'dinner', 'tea']),
  CategoryPreset(id: 'utensils', label: 'Restaurants', assetPath: '$_presets/utensils.svg', group: 'Food', keywords: ['food', 'eat', 'dine', 'meal', 'fork', 'knife']),
  CategoryPreset(id: 'groceries', label: 'Groceries', assetPath: '$_presets/groceries.svg', group: 'Food', keywords: ['food', 'cart', 'mart', 'supermarket', 'ration']),
  CategoryPreset(id: 'pizza', label: 'Fast food', assetPath: '$_presets/pizza.svg', group: 'Food', keywords: ['food', 'burger', 'snack', 'takeout']),
  CategoryPreset(id: 'fruit', label: 'Fruit & veg', assetPath: '$_presets/fruit.svg', group: 'Food', keywords: ['food', 'apple', 'vegetable', 'sabzi']),
  CategoryPreset(id: 'sweets', label: 'Sweets & bakery', assetPath: '$_presets/sweets.svg', group: 'Food', keywords: ['food', 'cake', 'dessert', 'mithai']),
  CategoryPreset(id: 'drinks', label: 'Drinks', assetPath: '$_presets/drinks.svg', group: 'Food', keywords: ['juice', 'beverage', 'glass']),
  CategoryPreset(id: 'takeaway', label: 'Takeaway', assetPath: '$_presets/takeaway.svg', group: 'Food', keywords: ['food', 'delivery', 'order', 'bag']),
  CategoryPreset(id: 'coffee', label: 'Coffee & Tea', assetPath: '$_presets/coffee.svg', group: 'Food', keywords: ['cafe', 'chai', 'drink']),
  // Transport
  CategoryPreset(id: 'transport', label: 'Transport', assetPath: '$_presets/transport.svg', group: 'Transport', keywords: ['travel', 'commute']),
  CategoryPreset(id: 'car', label: 'Ride & Taxi', assetPath: '$_presets/car.svg', group: 'Transport', keywords: ['uber', 'careem', 'cab', 'vehicle']),
  CategoryPreset(id: 'bus', label: 'Bus & Metro', assetPath: '$_presets/bus.svg', group: 'Transport', keywords: ['commute', 'public']),
  CategoryPreset(id: 'train', label: 'Train', assetPath: '$_presets/train.svg', group: 'Transport', keywords: ['rail', 'metro', 'commute']),
  CategoryPreset(id: 'motorbike', label: 'Motorbike', assetPath: '$_presets/motorbike.svg', group: 'Transport', keywords: ['bike', 'scooter']),
  CategoryPreset(id: 'bicycle', label: 'Bike', assetPath: '$_presets/bicycle.svg', group: 'Transport', keywords: ['cycle']),
  CategoryPreset(id: 'parking', label: 'Parking', assetPath: '$_presets/parking.svg', group: 'Transport', keywords: ['car', 'toll']),
  CategoryPreset(id: 'plane', label: 'Flights', assetPath: '$_presets/plane.svg', group: 'Transport', keywords: ['air', 'trip', 'ticket']),
  CategoryPreset(id: 'travel', label: 'Travel', assetPath: '$_presets/travel.svg', group: 'Transport', keywords: ['trip', 'holiday', 'vacation']),
  // Bills
  CategoryPreset(id: 'smartphone', label: 'Mobile & Data', assetPath: '$_presets/smartphone.svg', group: 'Bills', keywords: ['phone', 'load', 'package']),
  CategoryPreset(id: 'phone_call', label: 'Calls', assetPath: '$_presets/phone_call.svg', group: 'Bills', keywords: ['phone', 'landline']),
  CategoryPreset(id: 'tv', label: 'TV & cable', assetPath: '$_presets/tv.svg', group: 'Bills', keywords: ['streaming', 'netflix', 'television']),
  CategoryPreset(id: 'receipt', label: 'Bills', assetPath: '$_presets/receipt.svg', group: 'Bills', keywords: ['invoice', 'payment']),
  CategoryPreset(id: 'repeat', label: 'Subscriptions', assetPath: '$_presets/repeat.svg', group: 'Bills', keywords: ['recurring', 'monthly']),
  CategoryPreset(id: 'shield', label: 'Insurance', assetPath: '$_presets/shield.svg', group: 'Bills', keywords: ['protection', 'cover']),
  CategoryPreset(id: 'percent', label: 'Tax & Fees', assetPath: '$_presets/percent.svg', group: 'Bills', keywords: ['charges', 'interest']),
  // Home
  CategoryPreset(id: 'building', label: 'Hostel', assetPath: '$_presets/building.svg', group: 'Home', keywords: ['apartment', 'flat', 'dorm']),
  CategoryPreset(id: 'sofa', label: 'Furniture', assetPath: '$_presets/sofa.svg', group: 'Home', keywords: ['couch', 'decor']),
  CategoryPreset(id: 'lightbulb', label: 'Ideas & bulbs', assetPath: '$_presets/lightbulb.svg', group: 'Home', keywords: ['light', 'lamp']),
  CategoryPreset(id: 'leaf', label: 'Garden', assetPath: '$_presets/leaf.svg', group: 'Home', keywords: ['plants', 'nature']),
  CategoryPreset(id: 'laptop', label: 'Tech', assetPath: '$_presets/laptop.svg', group: 'Home', keywords: ['computer', 'gadget', 'electronics']),
  CategoryPreset(id: 'printer', label: 'Printing', assetPath: '$_presets/printer.svg', group: 'Home', keywords: ['print', 'copy']),
  // Shopping
  CategoryPreset(id: 'shopping', label: 'Shopping', assetPath: '$_presets/shopping.svg', group: 'Shopping', keywords: ['bag', 'mall', 'buy']),
  CategoryPreset(id: 'shirt', label: 'Clothing', assetPath: '$_presets/shirt.svg', group: 'Shopping', keywords: ['clothes', 'fashion', 'laundry']),
  CategoryPreset(id: 'tag', label: 'Sale & deals', assetPath: '$_presets/tag.svg', group: 'Shopping', keywords: ['discount', 'offer', 'price']),
  CategoryPreset(id: 'gift', label: 'Gifts', assetPath: '$_presets/gift.svg', group: 'Shopping', keywords: ['present', 'eid', 'birthday']),
  // Health
  CategoryPreset(id: 'health', label: 'Health', assetPath: '$_presets/health.svg', group: 'Health', keywords: ['doctor', 'medical']),
  CategoryPreset(id: 'pill', label: 'Medicine', assetPath: '$_presets/pill.svg', group: 'Health', keywords: ['pharmacy', 'tablet', 'drug']),
  CategoryPreset(id: 'hospital', label: 'Hospital', assetPath: '$_presets/hospital.svg', group: 'Health', keywords: ['clinic', 'doctor', 'cross']),
  CategoryPreset(id: 'tooth', label: 'Dentist', assetPath: '$_presets/tooth.svg', group: 'Health', keywords: ['dental', 'teeth']),
  CategoryPreset(id: 'glasses', label: 'Eyes & glasses', assetPath: '$_presets/glasses.svg', group: 'Health', keywords: ['optician', 'vision']),
  CategoryPreset(id: 'fitness', label: 'Fitness', assetPath: '$_presets/fitness.svg', group: 'Health', keywords: ['gym', 'workout', 'exercise']),
  CategoryPreset(id: 'personal_care', label: 'Self care', assetPath: '$_presets/personal_care.svg', group: 'Health', keywords: ['beauty', 'salon', 'spa']),
  CategoryPreset(id: 'scissors', label: 'Haircut', assetPath: '$_presets/scissors.svg', group: 'Health', keywords: ['barber', 'salon']),
  // Education
  CategoryPreset(id: 'education', label: 'Education', assetPath: '$_presets/education.svg', group: 'Education', keywords: ['school', 'study', 'fees']),
  CategoryPreset(id: 'grad_cap', label: 'University', assetPath: '$_presets/grad_cap.svg', group: 'Education', keywords: ['college', 'tuition', 'degree']),
  CategoryPreset(id: 'book', label: 'Books', assetPath: '$_presets/book.svg', group: 'Education', keywords: ['read', 'library']),
  CategoryPreset(id: 'pencil', label: 'Stationery', assetPath: '$_presets/pencil.svg', group: 'Education', keywords: ['pen', 'notebook']),
  CategoryPreset(id: 'calculator', label: 'Calculator', assetPath: '$_presets/calculator.svg', group: 'Education', keywords: ['math', 'accounts']),
  // Money
  CategoryPreset(id: 'wallet', label: 'Wallet', assetPath: '$_presets/wallet.svg', group: 'Money', keywords: ['purse', 'cash']),
  CategoryPreset(id: 'banknote', label: 'Cash', assetPath: '$_presets/banknote.svg', group: 'Money', keywords: ['money', 'notes']),
  CategoryPreset(id: 'coins', label: 'Coins', assetPath: '$_presets/coins.svg', group: 'Money', keywords: ['change', 'money']),
  CategoryPreset(id: 'credit_card', label: 'Cards', assetPath: '$_presets/credit_card.svg', group: 'Money', keywords: ['credit', 'debit', 'bank']),
  CategoryPreset(id: 'landmark', label: 'Bank', assetPath: '$_presets/landmark.svg', group: 'Money', keywords: ['loan', 'finance']),
  CategoryPreset(id: 'savings', label: 'Savings', assetPath: '$_presets/savings.svg', group: 'Money', keywords: ['piggy', 'save', 'committee']),
  CategoryPreset(id: 'income', label: 'Income', assetPath: '$_presets/income.svg', group: 'Money', keywords: ['salary', 'earn', 'up']),
  CategoryPreset(id: 'outgoing', label: 'Spending', assetPath: '$_presets/outgoing.svg', group: 'Money', keywords: ['expense', 'down']),
  CategoryPreset(id: 'investment', label: 'Investments', assetPath: '$_presets/investment.svg', group: 'Money', keywords: ['stocks', 'chart', 'growth']),
  CategoryPreset(id: 'heart', label: 'Charity', assetPath: '$_presets/heart.svg', group: 'Money', keywords: ['zakat', 'sadaqah', 'donate']),
  // Leisure
  CategoryPreset(id: 'entertainment', label: 'Entertainment', assetPath: '$_presets/entertainment.svg', group: 'Leisure', keywords: ['fun', 'outing']),
  CategoryPreset(id: 'film', label: 'Movies', assetPath: '$_presets/film.svg', group: 'Leisure', keywords: ['cinema', 'video']),
  CategoryPreset(id: 'music', label: 'Music', assetPath: '$_presets/music.svg', group: 'Leisure', keywords: ['songs', 'spotify']),
  CategoryPreset(id: 'headphones', label: 'Headphones', assetPath: '$_presets/headphones.svg', group: 'Leisure', keywords: ['audio', 'podcast']),
  CategoryPreset(id: 'gamepad', label: 'Games', assetPath: '$_presets/gamepad.svg', group: 'Leisure', keywords: ['gaming', 'console']),
  CategoryPreset(id: 'camera', label: 'Photos', assetPath: '$_presets/camera.svg', group: 'Leisure', keywords: ['camera', 'photography']),
  CategoryPreset(id: 'ball', label: 'Sports', assetPath: '$_presets/ball.svg', group: 'Leisure', keywords: ['football', 'cricket', 'game']),
  CategoryPreset(id: 'star', label: 'Special', assetPath: '$_presets/star.svg', group: 'Leisure', keywords: ['favourite', 'event', 'party']),
  // Family
  CategoryPreset(id: 'baby', label: 'Kids', assetPath: '$_presets/baby.svg', group: 'Family', keywords: ['child', 'toys', 'baby']),
  CategoryPreset(id: 'pets', label: 'Pets', assetPath: '$_presets/pets.svg', group: 'Family', keywords: ['dog', 'cat', 'animal']),
  CategoryPreset(id: 'bed', label: 'Hotel & Stay', assetPath: '$_presets/bed.svg', group: 'Family', keywords: ['sleep', 'room', 'stay']),
  // More
];

/// Built-in standard icons (the default categories). They are listed apart
/// from [categoryPresets] because the icon library treats them as "standard".
const List<CategoryPreset> standardIconChoices = [
  CategoryPreset(id: 'fuel', label: 'Fuel', assetPath: '$_std/fuel.svg', group: 'Transport', keywords: ['petrol', 'gas', 'diesel']),
  CategoryPreset(id: 'electricity', label: 'Electricity', assetPath: '$_std/electricity.svg', group: 'Bills', keywords: ['power', 'bolt', 'light', 'wapda']),
  CategoryPreset(id: 'gas', label: 'Gas', assetPath: '$_std/gas.svg', group: 'Bills', keywords: ['utility', 'fire', 'sui']),
  CategoryPreset(id: 'water', label: 'Water', assetPath: '$_std/water.svg', group: 'Bills', keywords: ['utility', 'drop']),
  CategoryPreset(id: 'internet', label: 'Internet', assetPath: '$_std/internet.svg', group: 'Bills', keywords: ['wifi', 'broadband', 'data']),
  CategoryPreset(id: 'rent', label: 'Rent', assetPath: '$_std/rent.svg', group: 'Home', keywords: ['house', 'housing', 'home']),
  CategoryPreset(id: 'maintenance', label: 'Repairs', assetPath: '$_std/maintenance.svg', group: 'Home', keywords: ['fix', 'tools', 'maintenance']),
  CategoryPreset(id: 'grocery', label: 'Basket', assetPath: '$_std/grocery.svg', group: 'More', keywords: ['shopping', 'basket']),
  CategoryPreset(id: 'other', label: 'Other', assetPath: '$_std/other.svg', group: 'More', keywords: ['misc', 'general', 'dots']),
];

/// Everything the icon picker offers: presets first, then standard icons.
const List<CategoryPreset> pickerCatalog = [
  ...categoryPresets,
  ...standardIconChoices,
];

/// Stored aliases that resolve to a bundled standard icon.
const Map<String, String> standardCategorySvgMap = {
  'electricity': 'assets/icons/categories/electricity.svg',
  'bolt': 'assets/icons/categories/electricity.svg',
  'gas': 'assets/icons/categories/gas.svg',
  'local_fire_department': 'assets/icons/categories/gas.svg',
  'grocery': 'assets/icons/categories/grocery.svg',
  'shopping_basket': 'assets/icons/categories/grocery.svg',
  'internet': 'assets/icons/categories/internet.svg',
  'wifi': 'assets/icons/categories/internet.svg',
  'water': 'assets/icons/categories/water.svg',
  'water_drop': 'assets/icons/categories/water.svg',
  'rent': 'assets/icons/categories/rent.svg',
  'home': 'assets/icons/categories/rent.svg',
  'maintenance': 'assets/icons/categories/maintenance.svg',
  'build': 'assets/icons/categories/maintenance.svg',
  'fuel': 'assets/icons/categories/fuel.svg',
  'local_gas_station': 'assets/icons/categories/fuel.svg',
  'other': 'assets/icons/categories/other.svg',
  'more_horiz': 'assets/icons/categories/other.svg',
};

/// Maps a stored alias (for example `bolt`) to the catalog id the picker
/// highlights (`electricity`). Other ids are returned unchanged.
String canonicalIconId(String raw) {
  final r = raw.trim();
  final key = r.startsWith('preset:') ? r.substring('preset:'.length) : r;
  final asset = standardCategorySvgMap[key.toLowerCase()];
  if (asset == null) return key;
  for (final p in pickerCatalog) {
    if (p.assetPath == asset) return p.id;
  }
  return key;
}

/// Emoji can stand in for an icon: stored as `emoji:<glyph>`.
const String emojiPrefix = 'emoji:';

class EmojiChoice {
  const EmojiChoice(this.glyph, this.label, [this.keywords = const []]);
  final String glyph;
  final String label;
  final List<String> keywords;

  String get id => '$emojiPrefix$glyph';

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q) ||
        keywords.any((k) => k.contains(q));
  }
}

const List<EmojiChoice> emojiChoices = [
  EmojiChoice('🍔', 'Burger', ['food', 'fast']),
  EmojiChoice('🍕', 'Pizza', ['food']),
  EmojiChoice('🍗', 'Chicken', ['food', 'meat']),
  EmojiChoice('🍛', 'Curry', ['food', 'biryani', 'rice']),
  EmojiChoice('🍜', 'Noodles', ['food']),
  EmojiChoice('🥗', 'Salad', ['food', 'healthy']),
  EmojiChoice('🍞', 'Bread', ['food', 'bakery']),
  EmojiChoice('🥛', 'Milk', ['food', 'dairy']),
  EmojiChoice('🍎', 'Apple', ['fruit', 'food']),
  EmojiChoice('🥦', 'Vegetables', ['food', 'sabzi']),
  EmojiChoice('🍰', 'Cake', ['dessert', 'sweet']),
  EmojiChoice('🍦', 'Ice cream', ['dessert']),
  EmojiChoice('☕', 'Coffee', ['drink', 'cafe', 'tea']),
  EmojiChoice('🧃', 'Juice', ['drink']),
  EmojiChoice('🛒', 'Shopping cart', ['groceries']),
  EmojiChoice('🛍️', 'Shopping bags', ['mall', 'buy']),
  EmojiChoice('👕', 'T-shirt', ['clothes']),
  EmojiChoice('👟', 'Shoes', ['clothes']),
  EmojiChoice('👜', 'Handbag', ['fashion']),
  EmojiChoice('💄', 'Makeup', ['beauty']),
  EmojiChoice('💇', 'Haircut', ['salon']),
  EmojiChoice('🚗', 'Car', ['transport']),
  EmojiChoice('🚕', 'Taxi', ['ride', 'uber']),
  EmojiChoice('🚌', 'Bus', ['transport']),
  EmojiChoice('🚆', 'Train', ['transport']),
  EmojiChoice('🏍️', 'Motorbike', ['bike']),
  EmojiChoice('🚲', 'Bicycle', ['bike']),
  EmojiChoice('⛽', 'Fuel', ['petrol']),
  EmojiChoice('✈️', 'Plane', ['flight', 'travel']),
  EmojiChoice('🏖️', 'Beach', ['holiday', 'trip']),
  EmojiChoice('🏨', 'Hotel', ['stay']),
  EmojiChoice('🏠', 'Home', ['rent', 'house']),
  EmojiChoice('🛋️', 'Furniture', ['sofa']),
  EmojiChoice('🔧', 'Repairs', ['tools', 'fix']),
  EmojiChoice('💡', 'Light bulb', ['electricity', 'idea']),
  EmojiChoice('🔥', 'Fire', ['gas']),
  EmojiChoice('💧', 'Water', ['drop']),
  EmojiChoice('📶', 'Internet', ['wifi', 'signal']),
  EmojiChoice('📱', 'Phone', ['mobile']),
  EmojiChoice('💻', 'Laptop', ['computer', 'tech']),
  EmojiChoice('🎧', 'Headphones', ['music']),
  EmojiChoice('🎮', 'Games', ['gaming']),
  EmojiChoice('🎬', 'Movies', ['cinema']),
  EmojiChoice('🎵', 'Music', ['songs']),
  EmojiChoice('⚽', 'Football', ['sports']),
  EmojiChoice('🏏', 'Cricket', ['sports']),
  EmojiChoice('🏋️', 'Gym', ['fitness']),
  EmojiChoice('💊', 'Medicine', ['pharmacy']),
  EmojiChoice('🩺', 'Doctor', ['health']),
  EmojiChoice('🦷', 'Dentist', ['teeth']),
  EmojiChoice('🎓', 'University', ['education', 'degree']),
  EmojiChoice('📚', 'Books', ['study']),
  EmojiChoice('✏️', 'Stationery', ['pencil']),
  EmojiChoice('🏫', 'School', ['education', 'fees']),
  EmojiChoice('👶', 'Baby', ['kids']),
  EmojiChoice('🧸', 'Toys', ['kids']),
  EmojiChoice('🐶', 'Dog', ['pets']),
  EmojiChoice('🐱', 'Cat', ['pets']),
  EmojiChoice('🎁', 'Gift', ['present', 'eid']),
  EmojiChoice('🎉', 'Party', ['event', 'celebration']),
  EmojiChoice('💍', 'Wedding', ['marriage', 'shadi']),
  EmojiChoice('🕌', 'Mosque', ['prayer', 'masjid']),
  EmojiChoice('🤲', 'Charity', ['zakat', 'sadaqah', 'dua']),
  EmojiChoice('❤️', 'Heart', ['love', 'donate']),
  EmojiChoice('💰', 'Money bag', ['cash', 'savings']),
  EmojiChoice('💵', 'Cash', ['notes', 'money']),
  EmojiChoice('💳', 'Card', ['credit', 'bank']),
  EmojiChoice('🏦', 'Bank', ['loan']),
  EmojiChoice('🐷', 'Piggy bank', ['savings']),
  EmojiChoice('📈', 'Investments', ['stocks', 'growth']),
  EmojiChoice('🧾', 'Receipt', ['bill']),
  EmojiChoice('🔁', 'Subscription', ['recurring']),
  EmojiChoice('🛡️', 'Insurance', ['protect']),
  EmojiChoice('🧹', 'Cleaning', ['house']),
  EmojiChoice('🧺', 'Laundry', ['clothes']),
  EmojiChoice('🪴', 'Plants', ['garden']),
  EmojiChoice('✂️', 'Scissors', ['salon']),
  EmojiChoice('📷', 'Camera', ['photos']),
  EmojiChoice('⭐', 'Star', ['favourite']),
];
