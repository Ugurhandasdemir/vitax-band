import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/text_search.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/widgets/v_segmented.dart';
import '../../data/food_catalog.dart';
import '../../data/models.dart';
import '../diary/quick_add_sheet.dart';

FoodItem _itemOf(FoodEntry e) =>
    FoodItem(e.name, e.portion, e.kcal, e.protein, e.carbs, e.fat);

/// "Son Kullanılanlar" listesinden gizlenen adlar.
class HiddenRecents extends AsyncNotifier<Set<String>> {
  static const _key = 'hiddenRecents';

  @override
  Future<Set<String>> build() async {
    final raw = await ref.read(settingsRepositoryProvider).getString(_key);
    if (raw == null) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  Future<void> _save(Set<String> s) async {
    await ref
        .read(settingsRepositoryProvider)
        .setString(_key, jsonEncode(s.toList()));
    state = AsyncData(s);
  }

  Future<void> hideAll(Iterable<String> names) async =>
      _save({...(state.value ?? {}), ...names});

  Future<void> unhide(String name) async {
    final s = {...(state.value ?? <String>{})};
    if (s.remove(name)) await _save(s);
  }
}

final hiddenRecentsProvider = AsyncNotifierProvider<HiddenRecents, Set<String>>(
  HiddenRecents.new,
);

class Favorites extends AsyncNotifier<List<FoodItem>> {
  static const _key = 'favorites';

  @override
  Future<List<FoodItem>> build() async {
    final raw = await ref.read(settingsRepositoryProvider).getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggle(FoodItem item) async {
    final list = [...(state.value ?? <FoodItem>[])];
    final i = list.indexWhere((f) => f.name == item.name);
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.add(item);
    }
    await ref
        .read(settingsRepositoryProvider)
        .setString(_key, jsonEncode(list.map((f) => f.toJson()).toList()));
    state = AsyncData(list);
  }
}

final favoritesProvider = AsyncNotifierProvider<Favorites, List<FoodItem>>(
  Favorites.new,
);

/// Son kullanılanlar: benzersiz, en yeni önce, gizlenenler hariç.
final recentFoodsProvider = FutureProvider<List<FoodEntry>>((ref) async {
  final all = await ref
      .watch(nutritionRepositoryProvider)
      .recentFoods(limit: 30);
  final hidden = await ref.watch(hiddenRecentsProvider.future);
  return all.where((e) => !hidden.contains(e.name)).take(20).toList();
});

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, this.initialMeal});
  final MealType? initialMeal;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _search = TextEditingController();
  late MealType _meal;
  int _tab = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal ?? defaultMealFor(ref.read(clockProvider)());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _add(FoodItem item) async {
    final day = ref.read(selectedDayProvider);
    await ref
        .read(nutritionActionsProvider)
        .addFood(
          FoodEntry(
            date: day,
            meal: _meal,
            name: item.name,
            portion: item.portion,
            kcal: item.kcal,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
          ),
        );
    await ref.read(hiddenRecentsProvider.notifier).unhide(item.name);
    ref.invalidate(recentFoodsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Eklendi'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final recents = ref.watch(recentFoodsProvider).value ?? const <FoodEntry>[];
    final favorites = ref.watch(favoritesProvider).value ?? const <FoodItem>[];
    final favNames = favorites.map((f) => f.name).toSet();
    final searching = _query.trim().isNotEmpty;

    Widget content;
    if (searching) {
      final source = <FoodItem>[];
      final seen = <String>{};
      for (final f in [...recents.map(_itemOf), ...foodCatalog]) {
        if (seen.add(normalizeTr(f.name))) source.add(f);
      }
      final results = searchFoods(_query, source: source);
      content = _FoodList(
        header: 'ARAMA SONUÇLARI',
        emptyText: 'Sonuç bulunamadı',
        items: results,
        favNames: favNames,
        addKey: (i, f) => 'add-result-$i',
        onAdd: _add,
        onFav: (f) => ref.read(favoritesProvider.notifier).toggle(f),
      );
    } else if (_tab == 0) {
      content = _FoodList(
        header: 'SON TÜKETİLENLER',
        headerAction: recents.isEmpty
            ? null
            : (
                'Tümünü Temizle',
                () => ref
                    .read(hiddenRecentsProvider.notifier)
                    .hideAll(recents.map((e) => e.name))
                    .then((_) => ref.invalidate(recentFoodsProvider)),
              ),
        emptyText: 'Henüz yemek kaydetmedin. Aşağıdan arayabilir veya özel yemek ekleyebilirsin.',
        items: recents.map(_itemOf).toList(),
        favNames: favNames,
        addKey: (i, f) => 'add-recent-${f.name}',
        onAdd: _add,
        onFav: (f) => ref.read(favoritesProvider.notifier).toggle(f),
      );
    } else if (_tab == 1) {
      content = _FoodList(
        header: 'FAVORİLERİN',
        emptyText: 'Favori eklemek için yiyeceklerin yanındaki yıldıza dokun.',
        items: favorites,
        favNames: favNames,
        addKey: (i, f) => 'add-fav-${f.name}',
        onAdd: _add,
        onFav: (f) => ref.read(favoritesProvider.notifier).toggle(f),
      );
    } else {
      content = _FoodList(
        header: 'TÜM YİYECEKLER',
        emptyText: 'Sonuç bulunamadı',
        items: foodCatalog,
        favNames: favNames,
        addKey: (i, f) => 'add-result-$i',
        onAdd: _add,
        onFav: (f) => ref.read(favoritesProvider.notifier).toggle(f),
      );
    }

    return VDetailScaffold(
      key: const ValueKey('screen-add-food'),
      title: 'Yemek Ekle / Ara',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          _SearchField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            onBarcode: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Barkod tarama Tara sekmesinde')),
            ),
          ),
          const SizedBox(height: VSpace.gutter),
          _MealChips(
            selected: _meal,
            onChanged: (m) => setState(() => _meal = m),
          ),
          const SizedBox(height: VSpace.gutter),
          VSegmented(
            labels: const ['Son Kullanılan', 'Favoriler', 'Tümü'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.restaurant_menu,
                  title: 'Özel Yemek',
                  subtitle: 'Kendi tarifini veya besin değerini gir',
                  onTap: () => _openCustom(context),
                ),
              ),
              const SizedBox(width: VSpace.gutter),
              Expanded(
                child: _ActionCard(
                  icon: Icons.bolt,
                  title: 'Hızlı Kalori',
                  subtitle: 'Sadece kalori ve öğün ile tek dokunuş',
                  onTap: () => showQuickAddSheet(context, meal: _meal),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.md),
          content,
          const SizedBox(height: VSpace.md),
          Container(
            padding: const EdgeInsets.all(VSpace.gutter),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: VColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'İpucu: ', style: VText.labelMd),
                        TextSpan(
                          text:
                              'Ambalajlı ürünleri Tara sekmesinden barkodla '
                              'hatasız kaydedebilirsin.',
                          style: VText.bodyMd.copyWith(
                            color: VColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustom(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: VColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.cardLg)),
    ),
    builder: (_) => _CustomFoodSheet(meal: _meal),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onBarcode,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onBarcode;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.only(left: 16, right: 6),
    decoration: BoxDecoration(
      color: VColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(VRadius.pill),
      border: Border.all(color: VColors.surfaceContainerHighest),
    ),
    child: Row(
      children: [
        const Icon(Icons.search, color: VColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            key: const ValueKey('food-search'),
            controller: controller,
            onChanged: onChanged,
            style: VText.bodyLg,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'Yemek, meyve, marka veya barkod ara...',
              hintStyle: VText.bodyMd.copyWith(color: VColors.outline),
            ),
          ),
        ),
        GestureDetector(
          onTap: onBarcode,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: VColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 20,
              color: VColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MealChips extends StatelessWidget {
  const _MealChips({required this.selected, required this.onChanged});
  final MealType selected;
  final ValueChanged<MealType> onChanged;

  static const _labels = {
    MealType.breakfast: 'Kahvaltı',
    MealType.lunch: 'Öğle',
    MealType.dinner: 'Akşam',
    MealType.snack: 'Atıştırma',
  };

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final m in MealType.values) ...[
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(m),
            child: Container(
              key: ValueKey('meal-chip-${m.name}'),
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: m == selected
                    ? VColors.primaryFixed
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(VRadius.pill),
                border: Border.all(
                  color: m == selected
                      ? VColors.primary
                      : VColors.surfaceContainerHighest,
                ),
              ),
              child: Text(
                _labels[m]!,
                maxLines: 1,
                style: VText.labelMd.copyWith(
                  fontSize: 12,
                  color: m == selected
                      ? VColors.primary
                      : VColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (m != MealType.snack) const SizedBox(width: 6),
      ],
    ],
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: VColors.primaryFixed,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Icon(icon, color: VColors.primary, size: 22),
          ),
          const SizedBox(height: VSpace.gutter),
          Text(title, style: VText.bodyLgMedium),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: VText.microTag.copyWith(
              fontWeight: FontWeight.w500,
              color: VColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FoodList extends StatelessWidget {
  const _FoodList({
    required this.header,
    required this.emptyText,
    required this.items,
    required this.favNames,
    required this.addKey,
    required this.onAdd,
    required this.onFav,
    this.headerAction,
  });

  final String header;
  final String emptyText;
  final List<FoodItem> items;
  final Set<String> favNames;
  final String Function(int, FoodItem) addKey;
  final void Function(FoodItem) onAdd;
  final void Function(FoodItem) onFav;
  final (String, VoidCallback)? headerAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            header,
            style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant),
          ),
          const Spacer(),
          if (headerAction != null)
            GestureDetector(
              onTap: headerAction!.$2,
              child: Text(
                headerAction!.$1,
                style: VText.labelCaps.copyWith(color: VColors.secondary),
              ),
            ),
        ],
      ),
      const SizedBox(height: VSpace.gutter),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: VSpace.lg),
          child: Center(
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
            ),
          ),
        )
      else
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: VSpace.sm),
            child: _FoodRow(
              item: items[i],
              isFav: favNames.contains(items[i].name),
              addKey: addKey(i, items[i]),
              onAdd: () => onAdd(items[i]),
              onFav: () => onFav(items[i]),
            ),
          ),
    ],
  );
}

String _g(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : formatDecimalTr(v);

class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.item,
    required this.isFav,
    required this.addKey,
    required this.onAdd,
    required this.onFav,
  });
  final FoodItem item;
  final bool isFav;
  final String addKey;
  final VoidCallback onAdd;
  final VoidCallback onFav;

  @override
  Widget build(BuildContext context) => VCard(
    padding: const EdgeInsets.fromLTRB(VSpace.md, 12, 12, 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VText.bodyLgMedium,
              ),
              Text(
                item.portion,
                style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.kcal} kcal',
                      style: VText.labelMd.copyWith(color: VColors.primary),
                    ),
                    TextSpan(
                      text:
                          '  P: ${_g(item.protein)}g  K: ${_g(item.carbs)}g  '
                          'Y: ${_g(item.fat)}g',
                      style: VText.microTag.copyWith(
                        fontWeight: FontWeight.w500,
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          key: ValueKey('fav-${item.name}'),
          behavior: HitTestBehavior.opaque,
          onTap: onFav,
          child: SizedBox(
            width: VSpace.touchMin,
            height: VSpace.touchMin,
            child: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? VColors.primaryContainer : VColors.outline,
            ),
          ),
        ),
        GestureDetector(
          key: ValueKey(addKey),
          onTap: onAdd,
          child: Container(
            width: VSpace.touchMin,
            height: VSpace.touchMin,
            decoration: const BoxDecoration(
              color: VColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: VColors.onPrimary),
          ),
        ),
      ],
    ),
  );
}

class _CustomFoodSheet extends ConsumerStatefulWidget {
  const _CustomFoodSheet({required this.meal});
  final MealType meal;

  @override
  ConsumerState<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends ConsumerState<_CustomFoodSheet> {
  final _c = {
    for (final k in ['name', 'portion', 'kcal', 'protein', 'carbs', 'fat'])
      k: TextEditingController(),
  };
  String? _error;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(String k) =>
      double.tryParse(_c[k]!.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final name = _c['name']!.text.trim();
    final kcal = _num('kcal').round();
    if (name.isEmpty || kcal <= 0) {
      setState(() => _error = 'Ad ve kalori gerekli');
      return;
    }
    final portion = _c['portion']!.text.trim();
    final item = FoodItem(
      name,
      portion.isEmpty ? '1 porsiyon' : portion,
      kcal,
      _num('protein'),
      _num('carbs'),
      _num('fat'),
    );
    await ref
        .read(nutritionActionsProvider)
        .addFood(
          FoodEntry(
            date: ref.read(selectedDayProvider),
            meal: widget.meal,
            name: item.name,
            portion: item.portion,
            kcal: item.kcal,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
          ),
        );
    ref.invalidate(recentFoodsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(String k, String label, {bool number = true}) => TextField(
    key: ValueKey('custom-$k'),
    controller: _c[k],
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: VColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.button),
        borderSide: BorderSide.none,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      VSpace.margin,
      VSpace.md,
      VSpace.margin,
      MediaQuery.of(context).viewInsets.bottom + VSpace.md,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Özel Yemek', style: VText.headlineMd),
        const SizedBox(height: VSpace.gutter),
        _field('name', 'Yemek adı', number: false),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _field('portion', 'Porsiyon', number: false),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _field('kcal', 'kcal')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _field('protein', 'Protein g')),
            const SizedBox(width: 8),
            Expanded(child: _field('carbs', 'Karb. g')),
            const SizedBox(width: 8),
            Expanded(child: _field('fat', 'Yağ g')),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: VText.bodyMd.copyWith(color: VColors.error)),
        ],
        const SizedBox(height: VSpace.md),
        SizedBox(
          width: double.infinity,
          height: VSpace.touchMin,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: VColors.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VRadius.button),
              ),
            ),
            onPressed: _save,
            child: Text(
              'Kaydet',
              style: VText.labelMd.copyWith(color: VColors.onPrimary),
            ),
          ),
        ),
      ],
    ),
  );
}
