# WalletMelt JSON Backup Format Specification

This document provides a formal, hardened specification of the JSON backup format for WalletMelt. It serves as a contract to ensure stability, determinism, and machine-readability, facilitating reliable import and export capabilities without database mutation.

---

## 1. File Metadata & Encoding

- **Filename Format:** `walletmelt-backup-YYYYMMDD-HHMMSS.json` (e.g., `walletmelt-backup-20260614-191944.json`). In case of name collisions in the output directory, a suffix `-N` is appended before the extension (e.g., `-2`, `-3`).
- **MIME Type:** `application/json`
- **Character Encoding:** UTF-8 (without Byte Order Mark)
- **Formatting:** Pretty-printed with a 2-space indentation.

---

## 2. Top-Level Structure

Every valid WalletMelt JSON backup must be a single JSON object containing exactly the following keys:

1. `metadata` (Object)
2. `expenses` (Array)
3. `grocery_items` (Array)
4. `categories` (Array)
5. `budgets` (Array)
6. `settings` (Object or Null)

### Example Root Structure

```json
{
  "metadata": { ... },
  "expenses": [ ... ],
  "grocery_items": [ ... ],
  "categories": [ ... ],
  "budgets": [ ... ],
  "settings": { ... }
}
```

---

## 3. Metadata Object Schema

The `metadata` object contains general information about the backup context and formats included.

| Key | Type | Description |
|---|---|---|
| `format` | String | Must be exactly `walletmelt.local_json_backup`. |
| `format_version` | Integer | The schema version of the JSON layout. Currently `1`. |
| `app_version` | String (Nullable) | The version of the WalletMelt app that generated the backup (e.g., `0.1.1+2`). |
| `exported_at` | String | ISO 8601 UTC timestamp of the backup generation. |
| `includes` | Array of Strings | Lists the array/object keys present in this backup version. Must include `["expenses", "grocery_items", "categories", "budgets", "settings"]`. |

### Example Metadata

```json
  "metadata": {
    "format": "walletmelt.local_json_backup",
    "format_version": 1,
    "app_version": "0.1.1+2",
    "exported_at": "2026-06-14T09:08:07.000",
    "includes": [
      "expenses",
      "grocery_items",
      "categories",
      "budgets",
      "settings"
    ]
  }
```

---

## 4. Entity Schemas

### 4.1 Expenses (`expenses`)

Represents records from the expense table.
- **Sorting Rule:** Sorted deterministically in ascending order by `id`.

| Field | Type | Nullable | Description / Example |
|---|---|---|---|
| `id` | String | No | Unique identifier (e.g. UUID). |
| `amount` | Number | No | The expense value (e.g., `1200.5`). |
| `currency` | String | No | Currency code (e.g., `"PKR"`, `"USD"`). |
| `category_id` | String | No | Category identifier relationship. |
| `title` | String | No | Expense label / title. |
| `vendor` | String | Yes | Name of vendor/store. |
| `date` | String | No | ISO 8601 date/time of the expense. |
| `notes` | String | Yes | Free-form notes. |
| `receipt_image_uri` | String | Yes | System URI pointing to receipt file (e.g., `file:///path/to/receipt.jpg`). |
| `is_recurring` | Boolean | No | Recurrence status flag. |
| `recurrence_frequency`| String | Yes | Recurrence frequency name (e.g., `"daily"`, `"weekly"`, `"monthly"`, `"yearly"`). |
| `created_at` | String | No | ISO 8601 creation timestamp. |
| `updated_at` | String | No | ISO 8601 last update timestamp. |
| `deleted_at` | String | Yes | ISO 8601 deletion timestamp (for soft-deleted rows). |

---

### 4.2 Grocery Items (`grocery_items`)

Represents individual items bought within a parent expense.
- **Sorting Rule:** Sorted deterministically by `expense_id` (ascending), then `created_at` (ascending), then `id` (ascending).

| Field | Type | Nullable | Description / Example |
|---|---|---|---|
| `id` | String | No | Unique identifier. |
| `expense_id` | String | No | References the parent `expenses.id`. |
| `name` | String | No | Item name (e.g., `"Milk"`). |
| `amount` | Number | No | Cost of this item. |
| `created_at` | String | No | ISO 8601 creation timestamp. |

---

### 4.3 Categories (`categories`)

Represents transaction classification definitions.
- **Sorting Rule:** Sorted deterministically in ascending order by `id`.

| Field | Type | Nullable | Description / Example |
|---|---|---|---|
| `id` | String | No | Unique category identifier. |
| `name` | String | No | Display name of the category. |
| `icon` | String | No | Identifier string of the icon asset/glyph. |
| `color` | String | No | Hex color code (e.g., `"#FF0000"`). |
| `is_default` | Boolean | No | Flag indicating if this is a system default category. |
| `created_at` | String | No | ISO 8601 creation timestamp. |
| `updated_at` | String | No | ISO 8601 update timestamp. |

---

### 4.4 Budgets (`budgets`)

Represents monthly spending limits set on categories.
- **Sorting Rule:** Sorted deterministically by `month` (ascending, format `YYYY-MM`), then `category_id` (ascending), then `id` (ascending).

| Field | Type | Nullable | Description / Example |
|---|---|---|---|
| `id` | String | No | Unique budget identifier. |
| `category_id` | String | No | References `categories.id`. |
| `amount` | Number | No | Allocated budget limit. |
| `currency` | String | No | Currency code (e.g. `"PKR"`). |
| `month` | String | No | Target month in format `YYYY-MM` (e.g., `"2026-06"`). |
| `created_at` | String | No | ISO 8601 creation timestamp. |
| `updated_at` | String | No | ISO 8601 update timestamp. |

---

### 4.5 Settings (`settings`)

Represents global application preferences.
- **Sorting Rule:** Not applicable (serialized as a single JSON object).

| Field | Type | Nullable | Description / Example |
|---|---|---|---|
| `currency` | String | No | Default application currency (e.g. `"PKR"`). |
| `theme_preference` | String | No | Theme preference name (e.g., `"system"`, `"light"`, `"dark"`). |
| `has_completed_onboarding`| Boolean | No | Onboarding flow completion status. |
| `last_exported_at` | String | Yes | Date string of last export activity (format `YYYY-MM-DD`). |
| `monthly_budget_amount` | Number | Yes | Primary monthly spending limit (e.g. `150000.00`). |

---

## 5. Serialization & Logic Rules

### 5.1 Deterministic Sorting
To facilitate binary comparison and verification of backup contents, all list objects must follow the strict, deterministic sorting keys detailed in Section 4. Unsorted source data from the database is ordered before serialization.

### 5.2 Null Handling
- Fields specified as Nullable in the schema above MUST write `null` values as JSON `null` literals when empty.
- Non-nullable fields must contain valid data. Reconstructing missing values must follow strict fallback rules during restore (to be planned).

### 5.3 Date and Time Format
- Timestamps are represented as ISO 8601 strings in local or UTC timezone matching standard Dart date conversions (e.g. `2026-06-14T09:08:07.000`).
- Date strings (such as `last_exported_at`) use the format `YYYY-MM-DD`.

### 5.4 Receipt URI Handling
- `receipt_image_uri` contains the literal text value of the stored URI.
- The path remains absolute to the local device's directories at the time of export.
- Packaging of receipt files is **excluded** from this spec; files are not archived inside the JSON file.

---

## 6. Strict Exclusions

The current version of the backup format does **not** support:
1. **ZIP/Archive Packaging:** The backup is exported purely as a single `.json` text file. No file archiving is performed.
2. **Receipt File Packaging:** Receipt images are not embedded, zipped, or base64-encoded.
3. **Receipt URI Rewrite:** Path resolution during export remains local-device specific.
4. **Database Mutation on Import:** There is no database restore mechanism implemented in this phase.

---

## 7. Forward Compatibility & Restore Planning

- **Format Version Bump:** Any additions to the schemas, changes in nullable fields, or change in ordering will require incrementing `format_version` in the `metadata`.
- **Validation-Readiness:** Decoders must run the read-only validator before attempting to read any arrays. If validation fails, import must abort immediately.
- **Restore Implication:** Backup IDs are source identifiers, not guaranteed safe destination identifiers. A future restore planner must preserve IDs only when they do not collide locally, otherwise it must remap IDs and update references such as `expenses.category_id`, `grocery_items.expense_id`, and `budgets.category_id`.
- **Settings Implication:** The `settings` object is exportable for portability, but future restore flows must treat settings import as an explicit option and must not silently overwrite local preferences.
- **Receipt Implication:** `receipt_image_uri` is a text reference only. Future restore flows must warn when receipt paths may be missing and must not claim media recovery unless a later archive/receipt packaging format is introduced.
