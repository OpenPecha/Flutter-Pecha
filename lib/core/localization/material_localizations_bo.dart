// This file contains the Tibetan material localization delegate for the app.
// It provides Tibetan translations for Material widgets.
// Tibetan material localization delegate for the app.
// Provides Tibetan translations for Material widgets.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/foundation.dart';

class MaterialLocalizationsBo extends GlobalMaterialLocalizations {
  final GlobalMaterialLocalizations _en;
  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _MaterialLocalizationsBoDelegate();

  MaterialLocalizationsBo({
    required super.localeName,
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
    required GlobalMaterialLocalizations en,
  }) : _en = en;

  static const List<String> _boWeekdays = <String>[
    'གཟའ་ཉི་མ་',
    'གཟའ་ཟླ་བ་',
    'གཟའ་མིག་དམར་',
    'གཟའ་ལྷག་པ་',
    'གཟའ་ཕུར་བུ་',
    'གཟའ་པ་སངས་',
    'གཟའ་སྤེན་པ་',
  ];

  @override
  String get okButtonLabel => 'འགྲིག';
  @override
  String get cancelButtonLabel => 'རྩིས་མེད།';
  @override
  String get closeButtonLabel => 'ཁ་རྒྱབ';
  @override
  String get continueButtonLabel => 'འཕྲལ་མར་འགྱོ';
  @override
  List<String> get narrowWeekdays => _boWeekdays;
  @override
  List<String> get weekdays => _boWeekdays;
  @override
  List<String> get shortWeekdays => _boWeekdays;

  @override
  String get aboutListTileTitleRaw => _en.aboutListTileTitleRaw;
  @override
  String get alertDialogLabel => _en.alertDialogLabel;
  @override
  String get anteMeridiemAbbreviation => _en.anteMeridiemAbbreviation;
  @override
  String get backButtonTooltip => _en.backButtonTooltip;

  @override
  String get closeButtonTooltip => _en.closeButtonTooltip;
  @override
  String get copyButtonLabel => _en.copyButtonLabel;
  @override
  String get cutButtonLabel => _en.cutButtonLabel;
  @override
  String get dateHelpText => _en.dateHelpText;
  @override
  String get dateRangeEndDateSemanticLabelRaw =>
      _en.dateRangeEndDateSemanticLabelRaw;
  @override
  String get dateRangeStartDateSemanticLabelRaw =>
      _en.dateRangeStartDateSemanticLabelRaw;
  @override
  String get deleteButtonTooltip => _en.deleteButtonTooltip;
  @override
  String get dialogLabel => _en.dialogLabel;
  @override
  String get drawerLabel => _en.drawerLabel;
  @override
  String get inputDateModeButtonLabel => _en.inputDateModeButtonLabel;
  @override
  String get inputTimeModeButtonLabel => _en.inputTimeModeButtonLabel;
  @override
  String get licensesPageTitle => _en.licensesPageTitle;
  @override
  String get modalBarrierDismissLabel => _en.modalBarrierDismissLabel;
  @override
  String get nextMonthTooltip => _en.nextMonthTooltip;
  @override
  String get nextPageTooltip => _en.nextPageTooltip;
  @override
  String get pageRowsInfoTitleApproximateRaw =>
      _en.pageRowsInfoTitleApproximateRaw;
  @override
  String get pasteButtonLabel => _en.pasteButtonLabel;
  @override
  String get popupMenuLabel => _en.popupMenuLabel;
  @override
  String get postMeridiemAbbreviation => _en.postMeridiemAbbreviation;
  @override
  String get previousMonthTooltip => _en.previousMonthTooltip;
  @override
  String get previousPageTooltip => _en.previousPageTooltip;
  @override
  String get refreshIndicatorSemanticLabel => _en.refreshIndicatorSemanticLabel;
  @override
  String get selectAllButtonLabel => _en.selectAllButtonLabel;
  @override
  String get selectYearSemanticsLabel => _en.selectYearSemanticsLabel;
  @override
  String get showMenuTooltip => _en.showMenuTooltip;
  @override
  String get signedInLabel => _en.signedInLabel;
  @override
  String get tabLabelRaw => _en.tabLabelRaw;
  @override
  String get timePickerDialHelpText => _en.timePickerDialHelpText;
  @override
  String get timePickerHourLabel => _en.timePickerHourLabel;
  @override
  String get timePickerMinuteLabel => _en.timePickerMinuteLabel;
  @override
  String get viewLicensesButtonLabel => _en.viewLicensesButtonLabel;

  static const _enDelegate = GlobalMaterialLocalizations.delegate;

  static Future<MaterialLocalizations> _loadEn(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  String get bottomSheetLabel => 'Bottom sheet';

  @override
  String get calendarModeButtonLabel => _en.calendarModeButtonLabel;

  @override
  String get clearButtonTooltip => _en.clearButtonTooltip;

  @override
  String get collapsedHint => _en.collapsedHint;

  @override
  String get collapsedIconTapHint => _en.collapsedIconTapHint;

  @override
  String get currentDateLabel => _en.currentDateLabel;

  @override
  // TODO: implement dateInputLabel
  String get dateInputLabel => throw UnimplementedError();

  @override
  // TODO: implement dateOutOfRangeLabel
  String get dateOutOfRangeLabel => throw UnimplementedError();

  @override
  // TODO: implement datePickerHelpText
  String get datePickerHelpText => throw UnimplementedError();

  @override
  // TODO: implement dateRangeEndLabel
  String get dateRangeEndLabel => throw UnimplementedError();

  @override
  // TODO: implement dateRangePickerHelpText
  String get dateRangePickerHelpText => throw UnimplementedError();

  @override
  // TODO: implement dateRangeStartLabel
  String get dateRangeStartLabel => throw UnimplementedError();

  @override
  // TODO: implement dateSeparator
  String get dateSeparator => throw UnimplementedError();

  @override
  String get dialModeButtonLabel => _en.dialModeButtonLabel;

  @override
  String get expandedHint => _en.expandedHint;

  @override
  String get expandedIconTapHint => _en.expandedIconTapHint;

  @override
  String get expansionTileCollapsedHint => _en.expansionTileCollapsedHint;

  @override
  String get expansionTileCollapsedTapHint => _en.expansionTileCollapsedTapHint;

  @override
  String get expansionTileExpandedHint => _en.expansionTileExpandedHint;

  @override
  String get expansionTileExpandedTapHint => _en.expansionTileExpandedTapHint;

  @override
  // TODO: implement firstPageTooltip
  String get firstPageTooltip => throw UnimplementedError();

  @override
  // TODO: implement hideAccountsLabel
  String get hideAccountsLabel => throw UnimplementedError();

  @override
  // TODO: implement invalidDateFormatLabel
  String get invalidDateFormatLabel => throw UnimplementedError();

  @override
  // TODO: implement invalidDateRangeLabel
  String get invalidDateRangeLabel => throw UnimplementedError();

  @override
  // TODO: implement invalidTimeLabel
  String get invalidTimeLabel => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyAlt
  String get keyboardKeyAlt => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyAltGraph
  String get keyboardKeyAltGraph => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyBackspace
  String get keyboardKeyBackspace => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyCapsLock
  String get keyboardKeyCapsLock => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyChannelDown
  String get keyboardKeyChannelDown => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyChannelUp
  String get keyboardKeyChannelUp => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyControl
  String get keyboardKeyControl => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyDelete
  String get keyboardKeyDelete => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyEject
  String get keyboardKeyEject => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyEnd
  String get keyboardKeyEnd => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyEscape
  String get keyboardKeyEscape => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyFn
  String get keyboardKeyFn => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyHome
  String get keyboardKeyHome => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyInsert
  String get keyboardKeyInsert => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyMeta
  String get keyboardKeyMeta => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyMetaMacOs
  String get keyboardKeyMetaMacOs => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyMetaWindows
  String get keyboardKeyMetaWindows => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumLock
  String get keyboardKeyNumLock => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad0
  String get keyboardKeyNumpad0 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad1
  String get keyboardKeyNumpad1 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad2
  String get keyboardKeyNumpad2 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad3
  String get keyboardKeyNumpad3 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad4
  String get keyboardKeyNumpad4 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad5
  String get keyboardKeyNumpad5 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad6
  String get keyboardKeyNumpad6 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad7
  String get keyboardKeyNumpad7 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad8
  String get keyboardKeyNumpad8 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpad9
  String get keyboardKeyNumpad9 => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadAdd
  String get keyboardKeyNumpadAdd => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadComma
  String get keyboardKeyNumpadComma => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadDecimal
  String get keyboardKeyNumpadDecimal => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadDivide
  String get keyboardKeyNumpadDivide => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadEnter
  String get keyboardKeyNumpadEnter => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadEqual
  String get keyboardKeyNumpadEqual => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadMultiply
  String get keyboardKeyNumpadMultiply => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadParenLeft
  String get keyboardKeyNumpadParenLeft => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadParenRight
  String get keyboardKeyNumpadParenRight => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyNumpadSubtract
  String get keyboardKeyNumpadSubtract => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyPageDown
  String get keyboardKeyPageDown => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyPageUp
  String get keyboardKeyPageUp => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyPower
  String get keyboardKeyPower => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyPowerOff
  String get keyboardKeyPowerOff => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyPrintScreen
  String get keyboardKeyPrintScreen => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyScrollLock
  String get keyboardKeyScrollLock => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeySelect
  String get keyboardKeySelect => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeyShift
  String get keyboardKeyShift => throw UnimplementedError();

  @override
  // TODO: implement keyboardKeySpace
  String get keyboardKeySpace => throw UnimplementedError();

  @override
  // TODO: implement lastPageTooltip
  String get lastPageTooltip => throw UnimplementedError();

  @override
  // TODO: implement licensesPackageDetailTextOther
  String get licensesPackageDetailTextOther => throw UnimplementedError();

  @override
  // TODO: implement lookUpButtonLabel
  String get lookUpButtonLabel => throw UnimplementedError();

  @override
  // TODO: implement menuBarMenuLabel
  String get menuBarMenuLabel => throw UnimplementedError();

  @override
  String get menuDismissLabel => 'Dismiss';

  @override
  // TODO: implement moreButtonTooltip
  String get moreButtonTooltip => throw UnimplementedError();

  @override
  // TODO: implement openAppDrawerTooltip
  String get openAppDrawerTooltip => throw UnimplementedError();

  @override
  // TODO: implement pageRowsInfoTitleRaw
  String get pageRowsInfoTitleRaw => throw UnimplementedError();

  @override
  // TODO: implement remainingTextFieldCharacterCountOther
  String get remainingTextFieldCharacterCountOther =>
      throw UnimplementedError();

  @override
  // TODO: implement reorderItemDown
  String get reorderItemDown => throw UnimplementedError();

  @override
  // TODO: implement reorderItemLeft
  String get reorderItemLeft => throw UnimplementedError();

  @override
  // TODO: implement reorderItemRight
  String get reorderItemRight => throw UnimplementedError();

  @override
  // TODO: implement reorderItemToEnd
  String get reorderItemToEnd => throw UnimplementedError();

  @override
  // TODO: implement reorderItemToStart
  String get reorderItemToStart => throw UnimplementedError();

  @override
  // TODO: implement reorderItemUp
  String get reorderItemUp => throw UnimplementedError();

  @override
  // TODO: implement rowsPerPageTitle
  String get rowsPerPageTitle => throw UnimplementedError();

  @override
  String get saveButtonLabel => 'Save';

  @override
  // TODO: implement scanTextButtonLabel
  String get scanTextButtonLabel => throw UnimplementedError();

  @override
  String get scrimLabel => 'Close';

  @override
  String get scrimOnTapHintRaw => 'Close';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.tall;

  @override
  String get searchFieldLabel => 'Search';

  @override
  // TODO: implement searchWebButtonLabel
  String get searchWebButtonLabel => throw UnimplementedError();

  @override
  // TODO: implement selectedDateLabel
  String get selectedDateLabel => throw UnimplementedError();

  @override
  // TODO: implement selectedRowCountTitleOther
  String get selectedRowCountTitleOther => throw UnimplementedError();

  @override
  String get shareButtonLabel => 'Share';

  @override
  // TODO: implement showAccountsLabel
  String get showAccountsLabel => throw UnimplementedError();

  @override
  TimeOfDayFormat get timeOfDayFormatRaw => _en.timeOfDayFormatRaw;

  @override
  String get timePickerHourModeAnnouncement =>
      _en.timePickerHourModeAnnouncement;

  @override
  String get timePickerInputHelpText => 'དུས་ཚོད་འདེམ།';

  @override
  String get timePickerMinuteModeAnnouncement =>
      _en.timePickerMinuteModeAnnouncement;

  @override
  // TODO: implement unspecifiedDate
  String get unspecifiedDate => throw UnimplementedError();

  @override
  // TODO: implement unspecifiedDateRange
  String get unspecifiedDateRange => throw UnimplementedError();
}

class _MaterialLocalizationsBoDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLocalizationsBoDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'bo';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    final String localeName = intl.Intl.canonicalizedLocale(locale.toString());
    // Fallback to 'en' for intl DateFormat/NumberFormat if 'bo' is not supported
    final String formatLocale =
        ['bo', 'bo_CN', 'bo_IN'].contains(localeName) ? 'en' : localeName;
    final en = await GlobalMaterialLocalizations.delegate.load(
      const Locale('en'),
    );
    return SynchronousFuture<MaterialLocalizations>(
      MaterialLocalizationsBo(
        localeName: localeName,
        fullYearFormat: intl.DateFormat.y(formatLocale),
        compactDateFormat: intl.DateFormat.yMd(formatLocale),
        shortDateFormat: intl.DateFormat.yMd(formatLocale),
        mediumDateFormat: intl.DateFormat.yMMMd(formatLocale),
        longDateFormat: intl.DateFormat.yMMMMEEEEd(formatLocale),
        yearMonthFormat: intl.DateFormat.yMMMM(formatLocale),
        shortMonthDayFormat: intl.DateFormat.MMMd(formatLocale),
        decimalFormat: intl.NumberFormat.decimalPattern(formatLocale),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', formatLocale),
        en: en as GlobalMaterialLocalizations,
      ),
    );
  }

  @override
  bool shouldReload(_MaterialLocalizationsBoDelegate old) => false;
}
