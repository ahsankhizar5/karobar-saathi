/// Localized labels for [EntryType]. Kept out of the model so `models.dart`
/// stays free of UI/localization concerns.
library;

import '../models/models.dart';
import 'app_strings.dart';

extension EntryTypeL10n on EntryType {
  /// The label for this entry type in the active language.
  String localizedLabel(AppStrings s) {
    switch (this) {
      case EntryType.sale:
        return s.typeSale;
      case EntryType.purchase:
        return s.typePurchase;
      case EntryType.expense:
        return s.typeExpense;
      case EntryType.withdrawal:
        return s.typeWithdrawal;
      case EntryType.unclear:
        return s.typeUnclear;
    }
  }
}
