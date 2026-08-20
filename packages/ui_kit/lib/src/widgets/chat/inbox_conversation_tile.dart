import 'package:flutter/material.dart';

class InboxConversationTile extends StatelessWidget {
  final String title;
  final String lastMessageContent;
  final String timeStr;
  final int unreadCount;
  final IconData icon;
  final Color iconColor;
  final bool isSupport;
  final VoidCallback onTap;

  const InboxConversationTile({
    super.key,
    required this.title,
    required this.lastMessageContent,
    required this.timeStr,
    required this.unreadCount,
    required this.icon,
    required this.iconColor,
    required this.isSupport,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor.withValues(alpha: 0.2), iconColor.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (isSupport)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                            color: unreadCount > 0 ? iconColor : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessageContent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            color: unreadCount > 0 ? colorScheme.onSurface.withValues(alpha: 0.7) : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
