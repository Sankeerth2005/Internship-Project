import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/presentation/widgets/app_feedback.dart';
import 'business_share_helper.dart';

Future<void> showShareActionsSheet(
  BuildContext context, {
  required String message,
  required String link,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Share via…'),
            onTap: () async {
              Navigator.pop(ctx);
              await SharePlus.instance.share(ShareParams(text: message));
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_rounded),
            title: const Text('WhatsApp'),
            onTap: () async {
              Navigator.pop(ctx);
              final uri = BusinessShareHelper.whatsappShareUri(message);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else if (context.mounted) {
                AppFeedback.showWarning(context, 'WhatsApp is not available.');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('Copy link'),
            onTap: () async {
              Navigator.pop(ctx);
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) {
                AppFeedback.showSuccess(context, 'Link copied');
              }
            },
          ),
        ],
      ),
    ),
  );
}
