class DatabaseSchema {
  const DatabaseSchema._();

  static const databaseName = 'wallet_melt.db';
  static const currentVersion = 1;

  static const createCategories = '''
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  isDefault INTEGER NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
''';

  static const createExpenses = '''
CREATE TABLE expenses (
  id TEXT PRIMARY KEY,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  categoryId TEXT NOT NULL,
  title TEXT NOT NULL,
  vendor TEXT,
  date TEXT NOT NULL,
  notes TEXT,
  receiptImageUri TEXT,
  isRecurring INTEGER NOT NULL DEFAULT 0,
  recurrenceFrequency TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  deletedAt TEXT,
  FOREIGN KEY(categoryId) REFERENCES categories(id)
);
''';

  static const createGroceryItems = '''
CREATE TABLE grocery_items (
  id TEXT PRIMARY KEY,
  expenseId TEXT NOT NULL,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  createdAt TEXT NOT NULL,
  FOREIGN KEY(expenseId) REFERENCES expenses(id) ON DELETE CASCADE
);
''';

  static const createBudgets = '''
CREATE TABLE category_budgets (
  id TEXT PRIMARY KEY,
  categoryId TEXT NOT NULL,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  month TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  UNIQUE(categoryId, month),
  FOREIGN KEY(categoryId) REFERENCES categories(id)
);
''';

  static const createMonthlyBudgets = '''
CREATE TABLE monthly_budgets (
  id TEXT PRIMARY KEY,
  month TEXT NOT NULL UNIQUE,
  amount REAL NOT NULL,
  amountMinorUnits INTEGER,
  currency TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
''';

  static const createSyncMetadata = '''
CREATE TABLE sync_metadata (
  entityType TEXT NOT NULL,
  entityId TEXT NOT NULL,
  localVersion INTEGER NOT NULL DEFAULT 1,
  remoteId TEXT,
  lastSyncedAt TEXT,
  syncState TEXT NOT NULL DEFAULT 'local_only',
  PRIMARY KEY(entityType, entityId)
);
''';

  static const indexes = [
    'CREATE INDEX idx_expenses_date ON expenses(date);',
    'CREATE INDEX idx_expenses_category ON expenses(categoryId);',
    'CREATE INDEX idx_expenses_deleted ON expenses(deletedAt);',
    'CREATE INDEX idx_grocery_items_expense ON grocery_items(expenseId);',
    'CREATE INDEX idx_budgets_month ON category_budgets(month);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_monthly_budgets_month ON monthly_budgets(month);',
  ];
}
