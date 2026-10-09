import 'package:flutter/widgets.dart';

import '../core/design_system/components/feedback/app_toast.dart';
import '../l10n/app_localizations.dart';
import 'app_scope.dart';

/// Dış bağlantıyı açar; açılamazsa (Mail yok, ağ yok) bilgi toast'ı gösterir.
Future<void> openExternal(BuildContext context, Uri uri) async {
  final scope = AppScope.of(context);
  final message = AppLocalizations.of(context).linkOpenFailed;
  final ok = await scope.opener.open(uri);
  if (!ok && context.mounted) {
    AppToast.show(context, message: message);
  }
}
