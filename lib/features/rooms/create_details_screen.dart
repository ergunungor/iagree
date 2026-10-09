import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/platform_services.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/feedback/app_sheet.dart';
import '../../core/design_system/components/feedback/app_toast.dart';
import '../../core/design_system/components/inputs/app_selection_field.dart';
import '../../core/design_system/components/inputs/app_slider.dart';
import '../../core/design_system/components/inputs/app_text_field.dart';
import '../../core/design_system/components/selection/app_chip.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/domain/room.dart';
import '../../core/domain/room_catalog.dart';
import '../../l10n/app_localizations.dart';
import 'create_what_screen.dart';
import 'widgets/create_scaffold.dart';

/// D1 · 2. adım "Nerede, ne zaman?" (SCREENS D1 `CreateDetails`). Alanlar kategoriye göre
/// değişir: mekanda konum + mesafe + bütçe, film ve dizide platform. Eksik alanla "Odayı
/// kur"a basılırsa alan işaretlenir ve error haptic verilir.
class CreateDetailsScreen extends StatefulWidget {
  const CreateDetailsScreen({super.key, required this.args});

  final CreateDetailsArgs args;

  @override
  State<CreateDetailsScreen> createState() => _CreateDetailsScreenState();
}

class _CreateDetailsScreenState extends State<CreateDetailsScreen> {
  static const List<double> _distances = [1, 3, 5, 10];
  static const int _budgetLevels = 3;
  static const String _lira = '₺';

  /// "Konumum" seçeneğinin değeri; gerçek bir semt adıyla çakışmaz.
  static const String _myLocation = '\u0000my-location';

  final TextEditingController _name = TextEditingController();
  late RoomWhen _when = widget.args.when;
  DateTime? _date;
  String? _district;
  double _km = 3;
  final Set<int> _budgets = {2};
  final Set<String> _platforms = {};
  bool _nameEdited = false;
  bool _submitted = false;
  bool _busy = false;
  bool _namePrimed = false;

  RoomCategory get _category => widget.args.category;
  bool get _isFilm => _category.kind == RoomKind.film;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_namePrimed) return;
    _namePrimed = true;
    _name.text = _suggestedName();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// "Konumum": izin yalnızca burada istenir; reddedilirse semt elle seçilir.
  Future<void> _onDistrict(String value) async {
    if (value != _myLocation) {
      setState(() => _district = value);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final access = await scope.location.request();
    if (!mounted) return;
    if (access == LocationAccess.granted) {
      setState(() => _district = _myLocation);
    } else {
      AppToast.show(context, message: l10n.createLocationDenied);
    }
  }

  String _placeName() => _district == _myLocation
      ? AppLocalizations.of(context).createMyLocation
      : _district!;

  String _whenLabel() {
    final l10n = AppLocalizations.of(context);
    return switch (_when) {
      RoomWhen.now => l10n.createWhenNow,
      RoomWhen.tonight => l10n.createWhenTonight,
      RoomWhen.weekend => l10n.createWhenWeekend,
      RoomWhen.date => DateFormat.MMMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(_date ?? DateTime.now()),
    };
  }

  /// "Bu akşam yemek": oda adı seçimlerden önerilir; kullanıcı yazmaya başlayınca bırakılır.
  String _suggestedName() =>
      AppLocalizations.of(context)
          .createRoomNameDefault(_whenLabel(), _category.inlineLabel);

  void _setWhen(RoomWhen when, {DateTime? date}) {
    setState(() {
      _when = when;
      _date = date ?? _date;
      if (!_nameEdited) _name.text = _suggestedName();
    });
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = ValueNotifier<DateTime>(
      _date == null || _date!.isBefore(today) ? today : _date!,
    );
    final result = await AppSheet.show<DateTime>(
      context,
      title: l10n.createDateSheetTitle,
      builder: (_) => SizedBox(
        height: _pickerHeight,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          minimumDate: today,
          initialDateTime: picked.value,
          onDateTimeChanged: (d) => picked.value = d,
        ),
      ),
      footer: Builder(
        builder: (sheetContext) => AppButton.primary(
          label: l10n.createDateConfirm,
          onPressed: () => Navigator.of(sheetContext).pop(picked.value),
        ),
      ),
    );
    picked.dispose();
    if (result != null) _setWhen(RoomWhen.date, date: result);
  }

  static const double _pickerHeight = 216;

  String _budgetText() {
    final levels = _budgets.toList()..sort();
    return levels.map((l) => _lira * l).join(' / ');
  }

  RoomDraft? _validDraft() {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final missingPlace = !_isFilm && _district == null;
    final missingPlatform = _isFilm && _platforms.isEmpty;
    if (name.isEmpty || missingPlace || missingPlatform) return null;
    final whenLabel = _whenLabel();
    return RoomDraft(
      name: name,
      category: _category,
      whenLabel: whenLabel,
      frameTags: [
        _category.label,
        whenLabel,
        if (!_isFilm && _budgets.isNotEmpty) _budgetText(),
        if (!_isFilm) l10n.createPlaceTag(_placeName(), _km.round()),
        if (_isFilm)
          for (final p in widget.args.catalog.platforms)
            if (_platforms.contains(p)) p,
      ],
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _submitted = true);
    final draft = _validDraft();
    if (draft == null) {
      AppHaptics.error();
      return;
    }
    final scope = AppScope.of(context);
    final user = scope.session.user!;
    setState(() => _busy = true);
    try {
      final room = await scope.rooms.create(
        draft,
        owner: RoomMember(id: user.id, name: user.name),
      );
      if (!mounted) return;
      AppRoutes.finishCreate(context, room);
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHaptics.error();
      AppToast.show(
        context,
        message: AppLocalizations.of(context).createFailed,
        kind: AppToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = widget.args.catalog;

    return CreateScaffold(
      progress: 1,
      onBack: () => Navigator.of(context).maybePop(),
      bottom: AppButton.primary(
        label: l10n.createSubmit,
        isLoading: _busy,
        onPressed: _submit,
      ),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.xl + AppSpacing.xxs,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(l10n.createDetailsTitle, style: context.text.h1),
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.xxs),
          if (!_isFilm) ...[
            AppSelectionField<String>(
              label: l10n.createWhere,
              sheetTitle: l10n.createWhereSheetTitle,
              hintText: l10n.createWherePlaceholder,
              value: _district,
              options: [
                AppSelectionOption(
                  value: _myLocation,
                  label: l10n.createMyLocation,
                ),
                for (final d in catalog.districts)
                  AppSelectionOption(value: d, label: d),
              ],
              onChanged: _onDistrict,
            ),
            if (_submitted && _district == null)
              _FieldError(l10n.createLocationRequired),
            const SizedBox(height: AppSpacing.md),
            AppSlider(
              values: _distances,
              value: _km,
              semanticLabel: l10n.createDistance,
              valueFormatter: (v) => l10n.createDistanceKm(v.round()),
              onChanged: (v) => setState(() => _km = v),
            ),
            const SizedBox(height: AppSpacing.xl + AppSpacing.xxs),
          ],
          _Label(l10n.createWhen),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppChip(
                label: l10n.createWhenNow,
                selected: _when == RoomWhen.now,
                onChanged: (_) => _setWhen(RoomWhen.now),
              ),
              AppChip(
                label: l10n.createWhenTonight,
                selected: _when == RoomWhen.tonight,
                onChanged: (_) => _setWhen(RoomWhen.tonight),
              ),
              AppChip(
                label: l10n.createWhenWeekend,
                selected: _when == RoomWhen.weekend,
                onChanged: (_) => _setWhen(RoomWhen.weekend),
              ),
              AppChip(
                label: _when == RoomWhen.date
                    ? _whenLabel()
                    : l10n.createWhenPickDate,
                selected: _when == RoomWhen.date,
                onChanged: (_) => _pickDate(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl + AppSpacing.xxs),
          if (_isFilm) ...[
            _Label(l10n.createPlatform),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in catalog.platforms)
                  AppChip(
                    label: p,
                    selected: _platforms.contains(p),
                    onChanged: (on) => setState(
                      () => on ? _platforms.add(p) : _platforms.remove(p),
                    ),
                  ),
              ],
            ),
            if (_submitted && _platforms.isEmpty)
              _FieldError(l10n.createPlatformRequired),
          ] else ...[
            _Label(l10n.createBudget),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (var level = 1; level <= _budgetLevels; level++)
                  AppChip(
                    label: _lira * level,
                    selected: _budgets.contains(level),
                    onChanged: (on) => setState(
                      () => on ? _budgets.add(level) : _budgets.remove(level),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl + AppSpacing.xxs),
          AppTextField(
            label: l10n.createRoomName,
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            errorText: _submitted && _name.text.trim().isEmpty
                ? l10n.createRoomNameRequired
                : null,
            onChanged: (_) => setState(() => _nameEdited = true),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }
}

/// Alan grubu etiketi (`bodySmall`, 500, `textSecondary`).
class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: context.text.bodySmall.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(AppIcons.warning, size: AppIconSize.s14, color: c.error),
            const SizedBox(width: AppSpacing.xxs),
            Expanded(
              child: Text(
                message,
                style: context.text.caption.copyWith(color: c.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
