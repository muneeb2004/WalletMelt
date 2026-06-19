import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// Shows a success snackbar with [message].
///
/// Uses [WalletMeltColors.positive] as the background and includes a
/// "Dismiss" action. Duration is 3 seconds.
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WalletMeltColors.positive,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
}

/// Shows an error snackbar with [message].
///
/// Uses [WalletMeltColors.danger] as the background and includes a
/// "Dismiss" action. Duration is 3 seconds.
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: WalletMeltColors.danger,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
}
