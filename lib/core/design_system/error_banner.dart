import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_client.dart';

class ApiErrorBanner extends StatelessWidget {
  const ApiErrorBanner({
    super.key,
    required this.error,
    this.onDismiss,
  });

  final Object error;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final failure = error is ApiFailure ? error as ApiFailure : null;
    final message = failure?.message ?? error.toString();
    final requestId = failure?.requestId;
    final fields = failure?.fieldErrors ?? const [];

    void copyRequestId() {
      if (requestId != null) {
        Clipboard.setData(ClipboardData(text: requestId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request ID copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (fields.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (final f in fields)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• ${f['field'] ?? 'Field'}: ${f['message'] ?? 'Invalid'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                      ],
                      if (requestId != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: copyRequestId,
                          onLongPress: copyRequestId,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Request ID: $requestId',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer
                                        .withValues(alpha: 0.8),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer
                                      .withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
