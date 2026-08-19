import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../local/wallet_melt_database.dart' as local;
import '../../../types/essential_expense.dart';
import '../../../types/fuel.dart';

class DriftEssentialExpenseRepository {
  DriftEssentialExpenseRepository(this._db);

  final local.WalletMeltDatabase _db;
  final _uuid = const Uuid();

  Future<List<EssentialExpenseTemplate>> listAll(
      {bool includeDeleted = false}) async {
    final query = _db.select(_db.essentialExpenseTemplates);
    if (!includeDeleted) {
      query.where((row) => row.deletedAt.isNull());
    }
    query.orderBy([(row) => OrderingTerm(expression: row.createdAt)]);

    final templateRows = await query.get();
    final allFuelComponents = await _db.select(_db.fuelTemplateComponents).get();

    final fuelByTemplate = <String, List<FuelTemplateComponent>>{};
    for (final row in allFuelComponents) {
      fuelByTemplate.putIfAbsent(row.templateId, () => []).add(
            FuelTemplateComponent(
              id: row.id,
              templateId: row.templateId,
              fuelType: FuelType.fromName(row.fuelType),
              expectedLitres: row.expectedLitres,
              expectedPricePerLitre: row.expectedPricePerLitre,
              createdAt: row.createdAt,
            ),
          );
    }

    return templateRows.map((row) {
      return EssentialExpenseTemplate(
        id: row.id,
        name: row.name,
        categoryId: row.categoryId,
        frequency: row.frequency,
        expectedAmount: row.expectedAmount,
        expectedDay: row.expectedDay,
        dueDate: row.dueDate,
        isActive: row.isActive,
        isFuel: row.isFuel,
        notes: row.notes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        fuelComponents: fuelByTemplate[row.id] ?? [],
      );
    }).toList();
  }

  Future<EssentialExpenseTemplate?> getById(String id,
      {bool includeDeleted = false}) async {
    final query = _db.select(_db.essentialExpenseTemplates)
      ..where((row) => row.id.equals(id));
    if (!includeDeleted) {
      query.where((row) => row.deletedAt.isNull());
    }

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final fuelRows = await (_db.select(_db.fuelTemplateComponents)
          ..where((f) => f.templateId.equals(id)))
        .get();

    final fuelComponents = fuelRows.map((f) {
      return FuelTemplateComponent(
        id: f.id,
        templateId: f.templateId,
        fuelType: FuelType.fromName(f.fuelType),
        expectedLitres: f.expectedLitres,
        expectedPricePerLitre: f.expectedPricePerLitre,
        createdAt: f.createdAt,
      );
    }).toList();

    return EssentialExpenseTemplate(
      id: row.id,
      name: row.name,
      categoryId: row.categoryId,
      frequency: row.frequency,
      expectedAmount: row.expectedAmount,
      expectedDay: row.expectedDay,
      dueDate: row.dueDate,
      isActive: row.isActive,
      isFuel: row.isFuel,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      fuelComponents: fuelComponents,
    );
  }

  Future<EssentialExpenseTemplate> create(
    EssentialExpenseTemplate template, {
    List<FuelTemplateComponent>? fuelComponents,
  }) async {
    final now = DateTime.now().toIso8601String();
    final templateId = template.id.isEmpty ? _uuid.v4() : template.id;

    final componentsToInsert = fuelComponents ?? template.fuelComponents;

    await _db.transaction(() async {
      await _db.into(_db.essentialExpenseTemplates).insert(
            local.EssentialExpenseTemplatesCompanion(
              id: Value(templateId),
              name: Value(template.name.trim()),
              categoryId: Value(template.categoryId),
              frequency: Value(template.frequency),
              expectedAmount: Value(template.expectedAmount),
              expectedDay: Value(template.expectedDay),
              dueDate: Value(template.dueDate),
              isActive: Value(template.isActive),
              isFuel: Value(template.isFuel),
              notes: Value(template.notes),
              createdAt: Value(template.createdAt.isEmpty ? now : template.createdAt),
              updatedAt: Value(now),
              deletedAt: Value(template.deletedAt),
            ),
          );

      if (template.isFuel && componentsToInsert.isNotEmpty) {
        for (final comp in componentsToInsert) {
          final compId = comp.id.isEmpty ? _uuid.v4() : comp.id;
          await _db.into(_db.fuelTemplateComponents).insert(
                local.FuelTemplateComponentsCompanion(
                  id: Value(compId),
                  templateId: Value(templateId),
                  fuelType: Value(comp.fuelType.name),
                  expectedLitres: Value(comp.expectedLitres),
                  expectedPricePerLitre: Value(comp.expectedPricePerLitre),
                  createdAt: Value(comp.createdAt.isEmpty ? now : comp.createdAt),
                ),
              );
        }
      }
    });

    final created = await getById(templateId);
    return created!;
  }

  Future<void> update(
    EssentialExpenseTemplate template, {
    List<FuelTemplateComponent>? fuelComponents,
  }) async {
    final now = DateTime.now().toIso8601String();
    final componentsToUpdate = fuelComponents ?? template.fuelComponents;

    await _db.transaction(() async {
      await (_db.update(_db.essentialExpenseTemplates)
            ..where((row) => row.id.equals(template.id)))
          .write(
        local.EssentialExpenseTemplatesCompanion(
          name: Value(template.name.trim()),
          categoryId: Value(template.categoryId),
          frequency: Value(template.frequency),
          expectedAmount: Value(template.expectedAmount),
          expectedDay: Value(template.expectedDay),
          dueDate: Value(template.dueDate),
          isActive: Value(template.isActive),
          isFuel: Value(template.isFuel),
          notes: Value(template.notes),
          updatedAt: Value(now),
          deletedAt: Value(template.deletedAt),
        ),
      );

      // Always sync fuel components for fuel templates
      await (_db.delete(_db.fuelTemplateComponents)
            ..where((row) => row.templateId.equals(template.id)))
          .go();

      if (template.isFuel && componentsToUpdate.isNotEmpty) {
        for (final comp in componentsToUpdate) {
          final compId = comp.id.isEmpty ? _uuid.v4() : comp.id;
          await _db.into(_db.fuelTemplateComponents).insert(
                local.FuelTemplateComponentsCompanion(
                  id: Value(compId),
                  templateId: Value(template.id),
                  fuelType: Value(comp.fuelType.name),
                  expectedLitres: Value(comp.expectedLitres),
                  expectedPricePerLitre: Value(comp.expectedPricePerLitre),
                  createdAt: Value(comp.createdAt.isEmpty ? now : comp.createdAt),
                ),
              );
        }
      }
    });
  }

  Future<void> toggleActive(String id, bool isActive) async {
    final now = DateTime.now().toIso8601String();
    await (_db.update(_db.essentialExpenseTemplates)
          ..where((row) => row.id.equals(id)))
        .write(
      local.EssentialExpenseTemplatesCompanion(
        isActive: Value(isActive),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> delete(String id) async {
    // Delete template and cascading fuel template components
    await (_db.delete(_db.essentialExpenseTemplates)
          ..where((row) => row.id.equals(id)))
        .go();
  }
}
