/// Lightweight, dependency-free localization for Karobar Saathi.
///
/// Two locales ship today — English (`en`) and Urdu (`ur`, right-to-left).
/// Strings are held in a plain map keyed by [AppLocale] so the table is easy to
/// audit and extend without ARB codegen or build-runner. Look strings up with
/// `context.l10n.<key>` (see [AppLocalizations]).
library;

import 'package:flutter/widgets.dart';

/// Supported UI languages.
enum AppLocale {
  en('en', 'English', 'English', TextDirection.ltr),
  ur('ur', 'اردو', 'Urdu', TextDirection.rtl);

  const AppLocale(this.code, this.nativeName, this.englishName, this.direction);

  /// ISO code used for [Locale] and persistence.
  final String code;

  /// The language's own name, shown in the switcher ("اردو").
  final String nativeName;

  /// English name, for accessibility labels.
  final String englishName;

  /// Layout direction for this language.
  final TextDirection direction;

  Locale get locale => Locale(code);

  static AppLocale fromCode(String? code) {
    for (final AppLocale value in AppLocale.values) {
      if (value.code == code) return value;
    }
    return AppLocale.en;
  }

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];
}

/// A resolved string table for one [AppLocale].
///
/// Fields are grouped by screen/feature to keep the two language maps aligned;
/// every key present in [_en] must exist in [_ur].
class AppStrings {
  const AppStrings(this._values);

  final Map<String, String> _values;

  String _get(String key) => _values[key] ?? key;

  // ---- App-wide ----------------------------------------------------------
  String get appName => _get('appName');
  String get tagline => _get('tagline');

  // ---- Navigation / shell ------------------------------------------------
  String get navDashboard => _get('navDashboard');
  String get navLedger => _get('navLedger');
  String get navLender => _get('navLender');
  String get titleDashboard => _get('titleDashboard');
  String get titleLedger => _get('titleLedger');
  String get titleLender => _get('titleLender');
  String get actionAdd => _get('actionAdd');
  String get actionAddTooltip => _get('actionAddTooltip');
  String get actionRefresh => _get('actionRefresh');
  String get actionAbout => _get('actionAbout');
  String get actionLanguage => _get('actionLanguage');
  String get savedToLedger => _get('savedToLedger');

  // ---- Language switcher -------------------------------------------------
  String get languageTitle => _get('languageTitle');
  String get languageSubtitle => _get('languageSubtitle');
  String get languageEnglish => _get('languageEnglish');
  String get languageUrdu => _get('languageUrdu');

  // ---- About dialog ------------------------------------------------------
  String get aboutTitle => _get('aboutTitle');
  String get aboutBody => _get('aboutBody');
  String get aboutBackendLabel => _get('aboutBackendLabel');
  String get close => _get('close');

  // ---- Dashboard ---------------------------------------------------------
  String greeting(String name) =>
      _get('greeting').replaceFirst('{name}', name);
  String get loadingBooks => _get('loadingBooks');
  String get somethingWrong => _get('somethingWrong');
  String get tryAgain => _get('tryAgain');
  String get todaysProfit => _get('todaysProfit');
  String get profit => _get('profit');
  String get loss => _get('loss');
  String get salesIn => _get('salesIn');
  String get moneyOut => _get('moneyOut');
  String entriesRecordedToday(int count) => _get(
        count == 1 ? 'entryRecordedTodayOne' : 'entriesRecordedTodayMany',
      ).replaceFirst('{count}', '$count');
  String get cashPosition => _get('cashPosition');
  String get cashPositionCaption => _get('cashPositionCaption');
  String get bestCategory => _get('bestCategory');
  String get recordMoreSales => _get('recordMoreSales');
  String marginPct(String pct) =>
      _get('marginPct').replaceFirst('{pct}', pct);
  String get last7Days => _get('last7Days');
  String get salesVsOut => _get('salesVsOut');
  String get noTrendData => _get('noTrendData');
  String get legendSales => _get('legendSales');
  String get legendMoneyOut => _get('legendMoneyOut');
  String get businessInsight => _get('businessInsight');
  String bestCategoryChip(String cat) =>
      _get('bestCategoryChip').replaceFirst('{cat}', cat);

  // ---- Ledger ------------------------------------------------------------
  String get loadingLedger => _get('loadingLedger');
  String get ledgerEmptyTitle => _get('ledgerEmptyTitle');
  String get ledgerEmptyBody => _get('ledgerEmptyBody');
  String get addTransaction => _get('addTransaction');
  String recordedEntries(int count) => _get(
        count == 1 ? 'recordedEntryOne' : 'recordedEntriesMany',
      ).replaceFirst('{count}', '$count');
  String inOut(String inV, String outV) =>
      _get('inOut').replaceFirst('{in}', inV).replaceFirst('{out}', outV);
  String get deleteEntryTitle => _get('deleteEntryTitle');
  String deleteEntryBody(String type, String amount) => _get('deleteEntryBody')
      .replaceFirst('{type}', type)
      .replaceFirst('{amount}', amount);
  String get keep => _get('keep');
  String get delete => _get('delete');
  String get entryDeleted => _get('entryDeleted');
  String get unconfirmed => _get('unconfirmed');
  String get deleteEntryTooltip => _get('deleteEntryTooltip');

  // ---- Entry types -------------------------------------------------------
  String get typeSale => _get('typeSale');
  String get typePurchase => _get('typePurchase');
  String get typeExpense => _get('typeExpense');
  String get typeWithdrawal => _get('typeWithdrawal');
  String get typeUnclear => _get('typeUnclear');

  // ---- Transaction sheet -------------------------------------------------
  String get addTransactionsTitle => _get('addTransactionsTitle');
  String get checkBeforeSaving => _get('checkBeforeSaving');
  String get typeOrSpeak => _get('typeOrSpeak');
  String get whatHappenedLabel => _get('whatHappenedLabel');
  String get whatHappenedHint => _get('whatHappenedHint');
  String get convertToEntries => _get('convertToEntries');
  String get readingEntry => _get('readingEntry');
  String get orSpeak => _get('orSpeak');
  String get tapMicIdle => _get('tapMicIdle');
  String recordingElapsed(String time) =>
      _get('recordingElapsed').replaceFirst('{time}', time);
  String get discardRecording => _get('discardRecording');
  String get recordingCaptured => _get('recordingCaptured');
  String get recordingTooShort => _get('recordingTooShort');
  String get micBlocked => _get('micBlocked');
  String get settings => _get('settings');
  String get micPermissionDenied => _get('micPermissionDenied');
  String get micPermanentlyDenied => _get('micPermanentlyDenied');
  String get recordStartFailed => _get('recordStartFailed');
  String get recordSaveFailed => _get('recordSaveFailed');
  String get typeEntryEmpty => _get('typeEntryEmpty');
  String noTransactionsFound(String transcript) => _get('noTransactionsFound')
      .replaceFirst('{transcript}', transcript);
  String get weHeard => _get('weHeard');
  String needsAnswerBanner(int count) => _get(
        count == 1 ? 'needsAnswerOne' : 'needsAnswerMany',
      ).replaceFirst('{count}', '$count');
  String get startOver => _get('startOver');
  String get saving => _get('saving');
  String get answerToSave => _get('answerToSave');
  String saveNEntries(int count) => _get(
        count == 1 ? 'saveEntryOne' : 'saveEntriesMany',
      ).replaceFirst('{count}', '$count');
  String get backToEntry => _get('backToEntry');

  // ---- Parsed entry card -------------------------------------------------
  String entryN(int n) => _get('entryN').replaceFirst('{n}', '$n');
  String get needsYourAnswer => _get('needsYourAnswer');
  String get defaultClarification => _get('defaultClarification');
  String get pickTypeToSave => _get('pickTypeToSave');
  String get transactionType => _get('transactionType');
  String get amountRs => _get('amountRs');
  String get enterAmount => _get('enterAmount');
  String get noteOptional => _get('noteOptional');
  String categoryLabel(String cat) =>
      _get('categoryLabel').replaceFirst('{cat}', cat);
  String discardEntryTooltip(int n) =>
      _get('discardEntryTooltip').replaceFirst('{n}', '$n');

  // ---- Lender view -------------------------------------------------------
  String get conceptBadge => _get('conceptBadge');
  String get conceptBody => _get('conceptBody');
  String get sampleApplicant => _get('sampleApplicant');

  /// Localized trade description for a seeded demo shop, keyed by its id.
  /// Falls back to [fallback] (the backend English text) for unknown ids.
  String shopDescription(String id, String fallback) {
    final String? value = _values['shopDesc_$id'];
    return value ?? fallback;
  }
  String get callingApi => _get('callingApi');
  String sharesData(String name) =>
      _get('sharesData').replaceFirst('{name}', name);
  String get consentGrantedSub => _get('consentGrantedSub');
  String get consentRevokedSub => _get('consentRevokedSub');
  String get consentHint => _get('consentHint');
  String get http403Title => _get('http403Title');
  String get restoreConsent => _get('restoreConsent');
  String get consentVerified => _get('consentVerified');
  String generatedAt(String time) =>
      _get('generatedAt').replaceFirst('{time}', time);
  String get verifiedMetrics => _get('verifiedMetrics');
  String get avgDailySales => _get('avgDailySales');
  String get salesVolatility => _get('salesVolatility');
  String get daysWithTransactions => _get('daysWithTransactions');
  String get cashBuffer => _get('cashBuffer');
  String daysValue(int n) => _get('daysValue').replaceFirst('{n}', '$n');
  String get whyProfile => _get('whyProfile');
  String get whyProfileSub => _get('whyProfileSub');
  String get noFactors => _get('noFactors');
  String get viewUnderlying => _get('viewUnderlying');
  String get underlyingRecords => _get('underlyingRecords');
  String get noRecordsTitle => _get('noRecordsTitle');
  String get noRecordsBody => _get('noRecordsBody');
  String get activityTitle => _get('activityTitle');
  String activityDaysCount(int count) =>
      _get('activityDaysCount').replaceFirst('{count}', '$count');
  String dayRecordsOne(String date) =>
      _get('dayRecordsOne').replaceFirst('{date}', date);
  String dayRecordsMany(String date, int count) => _get('dayRecordsMany')
      .replaceFirst('{date}', date)
      .replaceFirst('{count}', '$count');
  String dayNoRecords(String date) =>
      _get('dayNoRecords').replaceFirst('{date}', date);
  String get activityLegendRecorded => _get('activityLegendRecorded');
  String get activityLegendMissed => _get('activityLegendMissed');

  // ---- Volatility values (from backend: low/medium/high/unknown) ---------
  String volatility(String raw) {
    switch (raw.toLowerCase()) {
      case 'low':
        return _get('volatilityLow');
      case 'medium':
        return _get('volatilityMedium');
      case 'high':
        return _get('volatilityHigh');
      default:
        return _get('volatilityUnknown');
    }
  }

  static const AppStrings en = AppStrings(_en);
  static const AppStrings ur = AppStrings(_ur);

  static AppStrings of(AppLocale locale) =>
      locale == AppLocale.ur ? ur : en;
}

// ---------------------------------------------------------------------------
// English
// ---------------------------------------------------------------------------
const Map<String, String> _en = <String, String>{
  'appName': 'Karobar Saathi',
  'tagline': 'Your business companion',

  'navDashboard': 'Dashboard',
  'navLedger': 'Ledger',
  'navLender': 'Lender',
  'titleDashboard': 'Karobar Saathi',
  'titleLedger': 'My Ledger',
  'titleLender': 'Lender View (Concept)',
  'actionAdd': 'Add',
  'actionAddTooltip': 'Add a transaction by voice or text',
  'actionRefresh': 'Refresh',
  'actionAbout': 'About',
  'actionLanguage': 'Language',
  'savedToLedger': 'Saved to your ledger.',

  'languageTitle': 'Choose language',
  'languageSubtitle': 'Zaban chunein — the app text switches instantly.',
  'languageEnglish': 'English',
  'languageUrdu': 'اردو (Urdu)',

  'aboutTitle': 'About this build',
  'aboutBody':
      'Karobar Saathi turns spoken daily transactions into a structured, '
          'explainable financial record.',
  'aboutBackendLabel': 'Backend',
  'close': 'Close',

  'greeting': 'Assalam-o-Alaikum, {name}',
  'loadingBooks': 'Loading your books…',
  'somethingWrong': 'Something went wrong',
  'tryAgain': 'Try again',
  'todaysProfit': "Today's profit",
  'profit': 'Profit',
  'loss': 'Loss',
  'salesIn': 'Sales in',
  'moneyOut': 'Money out',
  'entryRecordedTodayOne': '1 entry recorded today',
  'entriesRecordedTodayMany': '{count} entries recorded today',
  'cashPosition': 'Cash position',
  'cashPositionCaption': 'All money in minus out',
  'bestCategory': 'Best category',
  'recordMoreSales': 'Record more sales',
  'marginPct': '{pct}% margin',
  'last7Days': 'Last 7 days',
  'salesVsOut': 'Sales against money going out',
  'noTrendData': 'No trend data yet. Record a few days of transactions.',
  'legendSales': 'Sales',
  'legendMoneyOut': 'Money out',
  'businessInsight': 'Your business insight',
  'bestCategoryChip': 'Best: {cat}',

  'loadingLedger': 'Loading your ledger…',
  'ledgerEmptyTitle': 'Your ledger is empty',
  'ledgerEmptyBody':
      'Record your first sale or purchase and it will appear here, along '
          'with exactly what you said.',
  'addTransaction': 'Add transaction',
  'recordedEntryOne': '1 recorded entry',
  'recordedEntriesMany': '{count} recorded entries',
  'inOut': 'In {in}  •  Out {out}',
  'deleteEntryTitle': 'Delete this entry?',
  'deleteEntryBody':
      '{type} of {amount} will be removed from your ledger.',
  'keep': 'Keep',
  'delete': 'Delete',
  'entryDeleted': 'Entry deleted.',
  'unconfirmed': 'Unconfirmed',
  'deleteEntryTooltip': 'Delete entry',

  'typeSale': 'Sale / Bikri',
  'typePurchase': 'Purchase / Maal',
  'typeExpense': 'Expense / Kharcha',
  'typeWithdrawal': 'Withdrawal / Ghar bheje',
  'typeUnclear': 'Unclear',

  'addTransactionsTitle': 'Add transactions',
  'checkBeforeSaving': 'Check before saving',
  'typeOrSpeak': 'Type it, or hold the mic and say it',
  'whatHappenedLabel': 'What happened today?',
  'whatHappenedHint': 'Aaj 4500 ki sale hui aur 1200 ka maal khareeda',
  'convertToEntries': 'Convert to ledger entries',
  'readingEntry': 'Reading your entry…',
  'orSpeak': 'or speak',
  'tapMicIdle': 'Tap the mic and speak in Urdu or Roman Urdu',
  'recordingElapsed': 'Recording… {time} — tap to stop and send',
  'discardRecording': 'Discard recording',
  'recordingCaptured': 'Recording captured. Uploading for transcription…',
  'recordingTooShort':
      'That recording was too short to hear. Hold the button a little '
          'longer, or type the transaction instead.',
  'micBlocked': 'Microphone access is blocked for this app.',
  'settings': 'Settings',
  'micPermissionDenied':
      'Microphone permission is required to record your transactions.',
  'micPermanentlyDenied':
      'Microphone access is blocked. Enable it in system settings to record '
          'your transactions.',
  'recordStartFailed':
      'Could not start recording. Try again, or type the transaction instead.',
  'recordSaveFailed':
      'Could not save the recording. Try again, or type the transaction '
          'instead.',
  'typeEntryEmpty':
      'Type what happened, for example "Aaj 4500 ki sale hui aur 1200 ka '
          'maal khareeda".',
  'noTransactionsFound':
      'No transactions were found in "{transcript}". Try mentioning the '
          'amount and what it was for.',
  'weHeard': 'We heard',
  'needsAnswerOne': '1 entry needs your answer before saving.',
  'needsAnswerMany': '{count} entries need your answer before saving.',
  'startOver': 'Start over',
  'saving': 'Saving…',
  'answerToSave': 'Answer the question above to save',
  'saveEntryOne': 'Save 1 entry',
  'saveEntriesMany': 'Save {count} entries',
  'backToEntry': 'Back to entry',

  'entryN': 'Entry {n}',
  'needsYourAnswer': 'Needs your answer',
  'defaultClarification':
      'Yeh transaction kya thi? Sale, khareed, kharcha ya ghar bheje?',
  'pickTypeToSave': 'Pick the correct type below to save this entry.',
  'transactionType': 'Transaction type',
  'amountRs': 'Amount (Rs)',
  'enterAmount': 'Enter an amount',
  'noteOptional': 'Note (optional)',
  'categoryLabel': 'Category: {cat}',
  'discardEntryTooltip': 'Discard entry {n}',

  'conceptBadge': 'CONCEPT DEMO — NOT A LENDING PRODUCT',
  'conceptBody':
      'An illustration of what a partner lender or government department '
          'would receive from the consent-gated evidence API. No credit '
          'decision, score, or loan offer is made here, and the shops below '
          'are seeded sample data.',
  'sampleApplicant': 'Sample applicant',
  'shopDesc_shop_001': 'Tea stall',
  'shopDesc_shop_002': 'Kirana store',
  'shopDesc_shop_003': 'Home-based tailor',
  'callingApi': 'Calling the evidence API…',
  'sharesData': '{name} shares their data',
  'consentGrantedSub':
      'Consent granted — the API returns the evidence profile.',
  'consentRevokedSub': 'Consent revoked — the API returns HTTP 403.',
  'consentHint':
      'The shopkeeper owns this switch. Flip it to see the API refuse '
          'access in real time.',
  'http403Title': 'HTTP 403 — Access refused',
  'restoreConsent': 'Turn the consent switch back on to restore access.',
  'consentVerified': 'Consent verified — profile released',
  'generatedAt': 'Generated {time}',
  'verifiedMetrics': 'Verified metrics (last 30 days)',
  'avgDailySales': 'Average daily sales',
  'salesVolatility': 'Sales volatility',
  'daysWithTransactions': 'Days with transactions',
  'cashBuffer': 'Cash buffer',
  'daysValue': '{n} days',
  'whyProfile': 'Why this profile looks like this',
  'whyProfileSub':
      'Every factor is traceable to recorded transactions — no opaque score.',
  'noFactors': 'No factors available yet.',
  'viewUnderlying': 'View underlying ledger records',
  'underlyingRecords': 'Underlying records',
  'noRecordsTitle': 'No records',
  'noRecordsBody': 'This sample shop has no ledger entries.',
  'activityTitle': 'Business activity',
  'activityDaysCount': '{count} of the last 30 days have records',
  'dayRecordsOne': '{date} — 1 record',
  'dayRecordsMany': '{date} — {count} records',
  'dayNoRecords': '{date} — no records',
  'activityLegendRecorded': 'Recorded',
  'activityLegendMissed': 'No records',

  'volatilityLow': 'Low',
  'volatilityMedium': 'Medium',
  'volatilityHigh': 'High',
  'volatilityUnknown': 'Unknown',
};

// ---------------------------------------------------------------------------
// Urdu (اردو) — right-to-left
// ---------------------------------------------------------------------------
const Map<String, String> _ur = <String, String>{
  'appName': 'کاروبار ساتھی',
  'tagline': 'آپ کے کاروبار کا ساتھی',

  'navDashboard': 'ڈیش بورڈ',
  'navLedger': 'کھاتہ',
  'navLender': 'قرض دہندہ',
  'titleDashboard': 'کاروبار ساتھی',
  'titleLedger': 'میرا کھاتہ',
  'titleLender': 'قرض دہندہ ویو (تصوراتی)',
  'actionAdd': 'شامل کریں',
  'actionAddTooltip': 'آواز یا ٹیکسٹ سے لین دین شامل کریں',
  'actionRefresh': 'تازہ کریں',
  'actionAbout': 'تعارف',
  'actionLanguage': 'زبان',
  'savedToLedger': 'آپ کے کھاتے میں محفوظ ہو گیا۔',

  'languageTitle': 'زبان منتخب کریں',
  'languageSubtitle': 'زبان چنیں — ایپ کا متن فوراً بدل جائے گا۔',
  'languageEnglish': 'English (انگریزی)',
  'languageUrdu': 'اردو',

  'aboutTitle': 'اس ایپ کے بارے میں',
  'aboutBody':
      'کاروبار ساتھی آپ کے روزمرہ کے بولے گئے لین دین کو ایک منظم اور قابلِ '
          'وضاحت مالی ریکارڈ میں تبدیل کرتا ہے۔',
  'aboutBackendLabel': 'بیک اینڈ',
  'close': 'بند کریں',

  'greeting': 'السلام علیکم، {name}',
  'loadingBooks': 'آپ کا کھاتہ کھل رہا ہے…',
  'somethingWrong': 'کچھ غلط ہو گیا',
  'tryAgain': 'دوبارہ کوشش کریں',
  'todaysProfit': 'آج کا منافع',
  'profit': 'منافع',
  'loss': 'نقصان',
  'salesIn': 'آمدنی (فروخت)',
  'moneyOut': 'اخراجات',
  'entryRecordedTodayOne': 'آج ۱ اندراج ریکارڈ ہوا',
  'entriesRecordedTodayMany': 'آج {count} اندراج ریکارڈ ہوئے',
  'cashPosition': 'نقدی کی صورتحال',
  'cashPositionCaption': 'کل آمدنی منہا اخراجات',
  'bestCategory': 'بہترین قسم',
  'recordMoreSales': 'مزید فروخت ریکارڈ کریں',
  'marginPct': '{pct}% مارجن',
  'last7Days': 'پچھلے ۷ دن',
  'salesVsOut': 'فروخت بمقابلہ اخراجات',
  'noTrendData':
      'ابھی کوئی رجحان دستیاب نہیں۔ چند دن کے لین دین ریکارڈ کریں۔',
  'legendSales': 'فروخت',
  'legendMoneyOut': 'اخراجات',
  'businessInsight': 'آپ کے کاروبار کی بصیرت',
  'bestCategoryChip': 'بہترین: {cat}',

  'loadingLedger': 'آپ کا کھاتہ کھل رہا ہے…',
  'ledgerEmptyTitle': 'آپ کا کھاتہ خالی ہے',
  'ledgerEmptyBody':
      'اپنی پہلی فروخت یا خریداری ریکارڈ کریں، وہ یہاں ظاہر ہو جائے گی — بالکل '
          'ویسے جیسے آپ نے کہا تھا۔',
  'addTransaction': 'لین دین شامل کریں',
  'recordedEntryOne': '۱ ریکارڈ شدہ اندراج',
  'recordedEntriesMany': '{count} ریکارڈ شدہ اندراج',
  'inOut': 'آمدنی {in}  •  اخراجات {out}',
  'deleteEntryTitle': 'یہ اندراج حذف کریں؟',
  'deleteEntryBody':
      '{amount} کا {type} آپ کے کھاتے سے ہٹا دیا جائے گا۔',
  'keep': 'رہنے دیں',
  'delete': 'حذف کریں',
  'entryDeleted': 'اندراج حذف ہو گیا۔',
  'unconfirmed': 'غیر تصدیق شدہ',
  'deleteEntryTooltip': 'اندراج حذف کریں',

  'typeSale': 'فروخت / بکری',
  'typePurchase': 'خریداری / مال',
  'typeExpense': 'خرچہ',
  'typeWithdrawal': 'رقم نکالی / گھر بھیجی',
  'typeUnclear': 'غیر واضح',

  'addTransactionsTitle': 'لین دین شامل کریں',
  'checkBeforeSaving': 'محفوظ کرنے سے پہلے جانچیں',
  'typeOrSpeak': 'لکھیں، یا مائیک دبا کر بولیں',
  'whatHappenedLabel': 'آج کیا ہوا؟',
  'whatHappenedHint': 'آج 4500 کی سیل ہوئی اور 1200 کا مال خریدا',
  'convertToEntries': 'کھاتے کے اندراج میں بدلیں',
  'readingEntry': 'آپ کا اندراج پڑھا جا رہا ہے…',
  'orSpeak': 'یا بولیں',
  'tapMicIdle': 'مائیک دبائیں اور اردو یا رومن اردو میں بولیں',
  'recordingElapsed': 'ریکارڈنگ… {time} — روکنے اور بھیجنے کے لیے دبائیں',
  'discardRecording': 'ریکارڈنگ ضائع کریں',
  'recordingCaptured': 'ریکارڈنگ محفوظ ہو گئی۔ تحریر کے لیے اپلوڈ ہو رہی ہے…',
  'recordingTooShort':
      'یہ ریکارڈنگ بہت مختصر تھی۔ بٹن تھوڑا دیر دبائے رکھیں، یا لین دین لکھ '
          'کر درج کریں۔',
  'micBlocked': 'اس ایپ کے لیے مائیکروفون بند ہے۔',
  'settings': 'ترتیبات',
  'micPermissionDenied':
      'لین دین ریکارڈ کرنے کے لیے مائیکروفون کی اجازت درکار ہے۔',
  'micPermanentlyDenied':
      'مائیکروفون کی رسائی بند ہے۔ لین دین ریکارڈ کرنے کے لیے اسے سسٹم '
          'ترتیبات میں فعال کریں۔',
  'recordStartFailed':
      'ریکارڈنگ شروع نہیں ہو سکی۔ دوبارہ کوشش کریں، یا لین دین لکھ کر درج کریں۔',
  'recordSaveFailed':
      'ریکارڈنگ محفوظ نہیں ہو سکی۔ دوبارہ کوشش کریں، یا لین دین لکھ کر درج '
          'کریں۔',
  'typeEntryEmpty':
      'جو ہوا وہ لکھیں، مثلاً "آج 4500 کی سیل ہوئی اور 1200 کا مال خریدا"۔',
  'noTransactionsFound':
      '"{transcript}" میں کوئی لین دین نہیں ملا۔ رقم اور اس کی وجہ بتانے کی '
          'کوشش کریں۔',
  'weHeard': 'ہم نے سنا',
  'needsAnswerOne': 'محفوظ کرنے سے پہلے ۱ اندراج کے لیے آپ کا جواب درکار ہے۔',
  'needsAnswerMany':
      'محفوظ کرنے سے پہلے {count} اندراج کے لیے آپ کا جواب درکار ہے۔',
  'startOver': 'دوبارہ شروع کریں',
  'saving': 'محفوظ ہو رہا ہے…',
  'answerToSave': 'محفوظ کرنے کے لیے اوپر دیے سوال کا جواب دیں',
  'saveEntryOne': '۱ اندراج محفوظ کریں',
  'saveEntriesMany': '{count} اندراج محفوظ کریں',
  'backToEntry': 'اندراج پر واپس',

  'entryN': 'اندراج {n}',
  'needsYourAnswer': 'آپ کا جواب درکار ہے',
  'defaultClarification':
      'یہ لین دین کیا تھا؟ فروخت، خریداری، خرچہ یا گھر بھیجی رقم؟',
  'pickTypeToSave':
      'اس اندراج کو محفوظ کرنے کے لیے نیچے درست قسم منتخب کریں۔',
  'transactionType': 'لین دین کی قسم',
  'amountRs': 'رقم (روپے)',
  'enterAmount': 'رقم درج کریں',
  'noteOptional': 'نوٹ (اختیاری)',
  'categoryLabel': 'قسم: {cat}',
  'discardEntryTooltip': 'اندراج {n} ضائع کریں',

  'conceptBadge': 'تصوراتی ڈیمو — یہ قرض دینے کی پروڈکٹ نہیں',
  'conceptBody':
      'یہ ایک مثال ہے کہ رضامندی سے محفوظ شدہ ثبوت API سے کوئی شراکت دار قرض '
          'دہندہ یا سرکاری ادارہ کیا وصول کرے گا۔ یہاں کوئی کریڈٹ فیصلہ، اسکور '
          'یا قرض کی پیشکش نہیں ہوتی، اور نیچے دی گئی دکانیں نمونہ ڈیٹا ہیں۔',
  'sampleApplicant': 'نمونہ درخواست گزار',
  'shopDesc_shop_001': 'چائے کا کھوکھا',
  'shopDesc_shop_002': 'کریانہ اسٹور',
  'shopDesc_shop_003': 'گھریلو درزی',
  'callingApi': 'ثبوت API کو کال کیا جا رہا ہے…',
  'sharesData': '{name} اپنا ڈیٹا شیئر کرتے ہیں',
  'consentGrantedSub': 'رضامندی دی گئی — API ثبوت پروفائل واپس کرتا ہے۔',
  'consentRevokedSub': 'رضامندی واپس لی گئی — API HTTP 403 واپس کرتا ہے۔',
  'consentHint':
      'یہ سوئچ دکاندار کے اختیار میں ہے۔ اسے بدل کر دیکھیں کہ API کیسے فوراً '
          'رسائی سے انکار کرتا ہے۔',
  'http403Title': 'HTTP 403 — رسائی مسترد',
  'restoreConsent': 'رسائی بحال کرنے کے لیے رضامندی سوئچ دوبارہ آن کریں۔',
  'consentVerified': 'رضامندی کی تصدیق — پروفائل جاری',
  'generatedAt': 'تیار شدہ {time}',
  'verifiedMetrics': 'تصدیق شدہ اعداد و شمار (پچھلے ۳۰ دن)',
  'avgDailySales': 'اوسط یومیہ فروخت',
  'salesVolatility': 'فروخت میں اتار چڑھاؤ',
  'daysWithTransactions': 'لین دین والے دن',
  'cashBuffer': 'نقدی بفر',
  'daysValue': '{n} دن',
  'whyProfile': 'یہ پروفائل ایسی کیوں ہے',
  'whyProfileSub':
      'ہر عنصر ریکارڈ شدہ لین دین سے جُڑا ہے — کوئی خفیہ اسکور نہیں۔',
  'noFactors': 'ابھی کوئی عنصر دستیاب نہیں۔',
  'viewUnderlying': 'بنیادی کھاتہ ریکارڈ دیکھیں',
  'underlyingRecords': 'بنیادی ریکارڈ',
  'noRecordsTitle': 'کوئی ریکارڈ نہیں',
  'noRecordsBody': 'اس نمونہ دکان کا کوئی کھاتہ اندراج نہیں۔',
  'activityTitle': 'کاروبار کی سرگرمی',
  'activityDaysCount': 'آخری ۳۰ دن میں سے {count} دنوں کے ریکارڈ ہیں',
  'dayRecordsOne': '{date} — ۱ ریکارڈ',
  'dayRecordsMany': '{date} — {count} ریکارڈ',
  'dayNoRecords': '{date} — کوئی ریکارڈ نہیں',
  'activityLegendRecorded': 'ریکارڈ شدہ',
  'activityLegendMissed': 'کوئی ریکارڈ نہیں',

  'volatilityLow': 'کم',
  'volatilityMedium': 'درمیانہ',
  'volatilityHigh': 'زیادہ',
  'volatilityUnknown': 'نامعلوم',
};
