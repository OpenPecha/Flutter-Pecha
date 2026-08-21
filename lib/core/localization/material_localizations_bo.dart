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
  // Note: These getters are kept for potential future use
  @override
  List<String> get narrowWeekdays => _boWeekdays;
  List<String> get weekdays => _boWeekdays;
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

  // Reserved for future use - fallback to English localization
  // static const _enDelegate = GlobalMaterialLocalizations.delegate;
  //
  // static Future<MaterialLocalizations> _loadEn(Locale locale) {
  //   return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  // }

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
  String get dateInputLabel => _en.dateInputLabel;

  @override
  String get dateOutOfRangeLabel => _en.dateOutOfRangeLabel;

  @override
  String get datePickerHelpText => _en.datePickerHelpText;

  @override
  String get dateRangeEndLabel => _en.dateRangeEndLabel;

  @override
  String get dateRangePickerHelpText => _en.dateRangePickerHelpText;

  @override
  String get dateRangeStartLabel => _en.dateRangeStartLabel;

  @override
  String get dateSeparator => _en.dateSeparator;

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
  String get firstPageTooltip => _en.firstPageTooltip;

  @override
  String get hideAccountsLabel => _en.hideAccountsLabel;

  @override
  String get invalidDateFormatLabel => _en.invalidDateFormatLabel;

  @override
  String get invalidDateRangeLabel => _en.invalidDateRangeLabel;

  @override
  String get invalidTimeLabel => _en.invalidTimeLabel;

  @override
  String get keyboardKeyAlt => _en.keyboardKeyAlt;

  @override
  String get keyboardKeyAltGraph => _en.keyboardKeyAltGraph;

  @override
  String get keyboardKeyBackspace => _en.keyboardKeyBackspace;

  @override
  String get keyboardKeyCapsLock => _en.keyboardKeyCapsLock;

  @override
  String get keyboardKeyChannelDown => _en.keyboardKeyChannelDown;

  @override
  String get keyboardKeyChannelUp => _en.keyboardKeyChannelUp;

  @override
  String get keyboardKeyControl => _en.keyboardKeyControl;

  @override
  String get keyboardKeyDelete => _en.keyboardKeyDelete;

  @override
  String get keyboardKeyEject => _en.keyboardKeyEject;

  @override
  String get keyboardKeyEnd => _en.keyboardKeyEnd;

  @override
  String get keyboardKeyEscape => _en.keyboardKeyEscape;

  @override
  String get keyboardKeyFn => _en.keyboardKeyFn;

  @override
  String get keyboardKeyHome => _en.keyboardKeyHome;

  @override
  String get keyboardKeyInsert => _en.keyboardKeyInsert;

  @override
  String get keyboardKeyMeta => _en.keyboardKeyMeta;

  @override
  String get keyboardKeyMetaMacOs => _en.keyboardKeyMetaMacOs;

  @override
  String get keyboardKeyMetaWindows => _en.keyboardKeyMetaWindows;

  @override
  String get keyboardKeyNumLock => _en.keyboardKeyNumLock;

  @override
  String get keyboardKeyNumpad0 => _en.keyboardKeyNumpad0;

  @override
  String get keyboardKeyNumpad1 => _en.keyboardKeyNumpad1;

  @override
  String get keyboardKeyNumpad2 => _en.keyboardKeyNumpad2;

  @override
  String get keyboardKeyNumpad3 => _en.keyboardKeyNumpad3;

  @override
  String get keyboardKeyNumpad4 => _en.keyboardKeyNumpad4;

  @override
  String get keyboardKeyNumpad5 => _en.keyboardKeyNumpad5;

  @override
  String get keyboardKeyNumpad6 => _en.keyboardKeyNumpad6;

  @override
  String get keyboardKeyNumpad7 => _en.keyboardKeyNumpad7;

  @override
  String get keyboardKeyNumpad8 => _en.keyboardKeyNumpad8;

  @override
  String get keyboardKeyNumpad9 => _en.keyboardKeyNumpad9;

  @override
  String get keyboardKeyNumpadAdd => _en.keyboardKeyNumpadAdd;

  @override
  String get keyboardKeyNumpadComma => _en.keyboardKeyNumpadComma;

  @override
  String get keyboardKeyNumpadDecimal => _en.keyboardKeyNumpadDecimal;

  @override
  String get keyboardKeyNumpadDivide => _en.keyboardKeyNumpadDivide;

  @override
  String get keyboardKeyNumpadEnter => _en.keyboardKeyNumpadEnter;

  @override
  String get keyboardKeyNumpadEqual => _en.keyboardKeyNumpadEqual;

  @override
  String get keyboardKeyNumpadMultiply => _en.keyboardKeyNumpadMultiply;

  @override
  String get keyboardKeyNumpadParenLeft => _en.keyboardKeyNumpadParenLeft;

  @override
  String get keyboardKeyNumpadParenRight => _en.keyboardKeyNumpadParenRight;

  @override
  String get keyboardKeyNumpadSubtract => _en.keyboardKeyNumpadSubtract;

  @override
  String get keyboardKeyPageDown => _en.keyboardKeyPageDown;

  @override
  String get keyboardKeyPageUp => _en.keyboardKeyPageUp;

  @override
  String get keyboardKeyPower => _en.keyboardKeyPower;

  @override
  String get keyboardKeyPowerOff => _en.keyboardKeyPowerOff;

  @override
  String get keyboardKeyPrintScreen => _en.keyboardKeyPrintScreen;

  @override
  String get keyboardKeyScrollLock => _en.keyboardKeyScrollLock;

  @override
  String get keyboardKeySelect => _en.keyboardKeySelect;

  @override
  String get keyboardKeyShift => _en.keyboardKeyShift;

  @override
  String get keyboardKeySpace => _en.keyboardKeySpace;

  @override
  String get lastPageTooltip => _en.lastPageTooltip;

  @override
  String get licensesPackageDetailTextOther => _en.licensesPackageDetailTextOther;

  @override
  String get lookUpButtonLabel => _en.lookUpButtonLabel;

  @override
  String get menuBarMenuLabel => _en.menuBarMenuLabel;

  @override
  String get menuDismissLabel => 'Dismiss';

  @override
  String get moreButtonTooltip => _en.moreButtonTooltip;

  @override
  String get openAppDrawerTooltip => _en.openAppDrawerTooltip;

  @override
  String get pageRowsInfoTitleRaw => _en.pageRowsInfoTitleRaw;

  @override
  String get remainingTextFieldCharacterCountOther => _en.remainingTextFieldCharacterCountOther;

  @override
  String get reorderItemDown => _en.reorderItemDown;

  @override
  String get reorderItemLeft => _en.reorderItemLeft;

  @override
  String get reorderItemRight => _en.reorderItemRight;

  @override
  String get reorderItemToEnd => _en.reorderItemToEnd;

  @override
  String get reorderItemToStart => _en.reorderItemToStart;

  @override
  String get reorderItemUp => _en.reorderItemUp;

  @override
  String get rowsPerPageTitle => _en.rowsPerPageTitle;

  @override
  String get saveButtonLabel => 'Save';

  @override
  String get scanTextButtonLabel => _en.scanTextButtonLabel;

  @override
  String get scrimLabel => 'Close';

  @override
  String get scrimOnTapHintRaw => 'Close';

  @override
  ScriptCategory get scriptCategory => ScriptCategory.tall;

  @override
  String get searchFieldLabel => 'Search';

  @override
  String get searchWebButtonLabel => _en.searchWebButtonLabel;

  @override
  String get selectedDateLabel => _en.selectedDateLabel;

  @override
  String get selectedRowCountTitleOther => _en.selectedRowCountTitleOther;

  @override
  String get shareButtonLabel => 'Share';

  @override
  String get showAccountsLabel => _en.showAccountsLabel;

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
  String get unspecifiedDate => _en.unspecifiedDate;

  @override
  String get unspecifiedDateRange => _en.unspecifiedDateRange;
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
