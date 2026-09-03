/// Data models mirroring the Karobar Saathi FastAPI backend schemas
/// (see backend/app/models/schemas.py).
library;

/// Ledger entry classification. Mirrors the backend `EntryType` enum.
enum EntryType {
  sale('sale', 'Sale / Bikri'),
  purchase('purchase', 'Purchase / Maal'),
  expense('expense', 'Expense / Kharcha'),
  withdrawal('withdrawal', 'Withdrawal / Ghar bheje'),
  unclear('unclear', 'Unclear');

  const EntryType(this.wire, this.label);

  /// The exact string the backend expects/returns.
  final String wire;

  /// Human readable label used in the UI.
  final String label;

  static EntryType fromWire(String? value) {
    for (final type in EntryType.values) {
      if (type.wire == value) return type;
    }
    return EntryType.unclear;
  }

  /// Entry types a user is allowed to pick when correcting a parsed entry.
  static const List<EntryType> selectable = <EntryType>[
    EntryType.sale,
    EntryType.purchase,
    EntryType.expense,
    EntryType.withdrawal,
  ];

  /// Money flowing into the business.
  bool get isInflow => this == EntryType.sale;

  /// Money flowing out of the business.
  bool get isOutflow =>
      this == EntryType.purchase ||
      this == EntryType.expense ||
      this == EntryType.withdrawal;
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// A shopkeeper account. Mirrors `UserResponse`.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.businessType,
    this.businessName,
    this.phone,
    this.createdAt,
  });

  final String id;
  final String name;
  final String businessType;
  final String? businessName;
  final String? phone;
  final String? createdAt;

  /// `home_tailor` -> `Home Tailor`
  String get businessTypeLabel => businessType
      .split(RegExp(r'[_\s]+'))
      .where((String part) => part.isNotEmpty)
      .map((String part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        businessType: json['business_type'] as String? ?? '',
        businessName: json['business_name'] as String?,
        phone: json['phone'] as String?,
        createdAt: json['created_at'] as String?,
      );
}

/// A saved ledger row. Mirrors `LedgerEntryResponse`.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.userId,
    required this.entryType,
    required this.amount,
    required this.confirmed,
    this.note,
    this.rawTranscript,
    this.category,
    this.createdAt,
  });

  final int id;
  final String userId;
  final EntryType entryType;
  final double amount;
  final bool confirmed;
  final String? note;
  final String? rawTranscript;
  final String? category;
  final String? createdAt;

  DateTime? get createdAtLocal {
    final String? raw = createdAt;
    if (raw == null || raw.isEmpty) return null;
    // Backend stores naive UTC timestamps; treat them as UTC.
    final DateTime? parsed = DateTime.tryParse(raw.endsWith('Z') ? raw : '${raw}Z');
    return parsed?.toLocal();
  }

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: _toInt(json['id']),
        userId: json['user_id'] as String? ?? '',
        entryType: EntryType.fromWire(json['entry_type'] as String?),
        amount: _toDouble(json['amount']),
        confirmed: json['confirmed'] == true,
        note: json['note'] as String?,
        rawTranscript: json['raw_transcript'] as String?,
        category: json['category'] as String?,
        createdAt: json['created_at'] as String?,
      );
}

/// A single AI-parsed candidate entry. Mirrors `ParsedEntry`.
///
/// This is an editable draft: the confirmation UI mutates copies of it before
/// the user commits the batch to the ledger.
class ParsedEntry {
  const ParsedEntry({
    required this.entryType,
    required this.amount,
    this.note,
    this.category,
    this.needsClarification = false,
    this.clarificationQuestion,
  });

  final EntryType entryType;
  final double amount;
  final String? note;
  final String? category;
  final bool needsClarification;
  final String? clarificationQuestion;

  /// An entry may not be saved while the server still considers it ambiguous
  /// or while it carries no usable amount.
  bool get isUnclear =>
      needsClarification || entryType == EntryType.unclear || amount <= 0;

  ParsedEntry copyWith({
    EntryType? entryType,
    double? amount,
    String? note,
    String? category,
    bool? needsClarification,
    String? clarificationQuestion,
  }) =>
      ParsedEntry(
        entryType: entryType ?? this.entryType,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        category: category ?? this.category,
        needsClarification: needsClarification ?? this.needsClarification,
        clarificationQuestion:
            clarificationQuestion ?? this.clarificationQuestion,
      );

  factory ParsedEntry.fromJson(Map<String, dynamic> json) => ParsedEntry(
        entryType: EntryType.fromWire(json['entry_type'] as String?),
        amount: _toDouble(json['amount']),
        note: json['note'] as String?,
        category: json['category'] as String?,
        needsClarification: json['needs_clarification'] == true,
        clarificationQuestion: json['clarification_question'] as String?,
      );

  /// Shape expected by `POST /api/v1/ledger/batch-confirm`.
  Map<String, dynamic> toCreateJson({
    required String userId,
    required String rawTranscript,
  }) =>
      <String, dynamic>{
        'user_id': userId,
        'entry_type': entryType.wire,
        'amount': amount,
        'note': note,
        'raw_transcript': rawTranscript,
        'category': category,
        'confirmed': true,
      };
}

/// Response of both `/voice/parse-text` and `/voice/transcribe`.
class TranscriptResult {
  const TranscriptResult({
    required this.parsedEntries,
    required this.rawTranscript,
  });

  final List<ParsedEntry> parsedEntries;
  final String rawTranscript;

  factory TranscriptResult.fromJson(Map<String, dynamic> json) =>
      TranscriptResult(
        parsedEntries: (json['parsed_entries'] as List<dynamic>? ??
                <dynamic>[])
            .map((dynamic e) => ParsedEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        rawTranscript: json['raw_transcript'] as String? ?? '',
      );
}

/// One bar in the dashboard's 7-day trend.
class TrendDay {
  const TrendDay({
    required this.day,
    required this.date,
    required this.sales,
    required this.expenses,
    required this.profit,
  });

  final String day;
  final String date;
  final double sales;
  final double expenses;
  final double profit;

  factory TrendDay.fromJson(Map<String, dynamic> json) => TrendDay(
        day: json['day'] as String? ?? '',
        date: json['date'] as String? ?? '',
        sales: _toDouble(json['sales']),
        expenses: _toDouble(json['expenses']),
        profit: _toDouble(json['profit']),
      );
}

/// Mirrors `DashboardResponse`.
class Dashboard {
  const Dashboard({
    required this.todayProfit,
    required this.todaySales,
    required this.todayExpenses,
    required this.weeklyTrend,
    required this.cashPosition,
    required this.killerInsight,
    required this.totalEntriesToday,
    this.topCategory,
    this.topCategoryMargin,
  });

  final double todayProfit;
  final double todaySales;
  final double todayExpenses;
  final List<TrendDay> weeklyTrend;
  final double cashPosition;
  final String killerInsight;
  final int totalEntriesToday;
  final String? topCategory;
  final double? topCategoryMargin;

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
        todayProfit: _toDouble(json['today_profit']),
        todaySales: _toDouble(json['today_sales']),
        todayExpenses: _toDouble(json['today_expenses']),
        weeklyTrend: (json['weekly_trend'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => TrendDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        cashPosition: _toDouble(json['cash_position']),
        killerInsight: json['killer_insight'] as String? ?? '',
        totalEntriesToday: _toInt(json['total_entries_today']),
        topCategory: json['top_category'] as String?,
        topCategoryMargin: json['top_category_margin'] == null
            ? null
            : _toDouble(json['top_category_margin']),
      );
}

/// Mirrors `MetricsModel`.
class EvidenceMetrics {
  const EvidenceMetrics({
    required this.avgDailySales,
    required this.salesVolatility,
    required this.daysWithTransactions,
    required this.cashBufferDays,
  });

  final double avgDailySales;
  final String salesVolatility;
  final int daysWithTransactions;
  final int cashBufferDays;

  factory EvidenceMetrics.fromJson(Map<String, dynamic> json) =>
      EvidenceMetrics(
        avgDailySales: _toDouble(json['avg_daily_sales']),
        salesVolatility: json['sales_volatility'] as String? ?? 'unknown',
        daysWithTransactions: _toInt(json['days_with_transactions']),
        cashBufferDays: _toInt(json['cash_buffer_days']),
      );
}

/// Mirrors `EvidenceProfileResponse`.
class EvidenceProfile {
  const EvidenceProfile({
    required this.userId,
    required this.hasUserConsentedToShare,
    required this.profileGeneratedAt,
    required this.metrics,
    required this.explainableFactors,
    required this.readinessSummary,
  });

  final String userId;
  final bool hasUserConsentedToShare;
  final String profileGeneratedAt;
  final EvidenceMetrics metrics;
  final List<String> explainableFactors;
  final String readinessSummary;

  factory EvidenceProfile.fromJson(Map<String, dynamic> json) =>
      EvidenceProfile(
        userId: json['user_id'] as String? ?? '',
        hasUserConsentedToShare: json['has_user_consented_to_share'] == true,
        profileGeneratedAt: json['profile_generated_at'] as String? ?? '',
        metrics: EvidenceMetrics.fromJson(
            (json['metrics'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
        explainableFactors:
            (json['explainable_factors'] as List<dynamic>? ?? <dynamic>[])
                .map((dynamic e) => e.toString())
                .toList(),
        readinessSummary: json['readiness_summary'] as String? ?? '',
      );
}

/// A hard-coded demo shop used by the concept Lender View.
class DemoShop {
  const DemoShop({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

/// Exactly the three seeded backend profiles (see backend/app/seed_data.py).
const List<DemoShop> kDemoShops = <DemoShop>[
  DemoShop(
    id: 'shop_001',
    name: 'Ahmad Chai Wala',
    description: 'Tea stall',
  ),
  DemoShop(
    id: 'shop_002',
    name: 'Bibi Naseem',
    description: 'Kirana store',
  ),
  DemoShop(
    id: 'shop_003',
    name: 'Fatima Silai',
    description: 'Home-based tailor',
  ),
];
