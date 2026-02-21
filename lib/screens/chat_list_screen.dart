// ============================================================
// Lista de conversaciones. Usa ConversationsRepository.
// Al tap abrimos TeamChatScreen (flujo existente).
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/conversations_repository.dart';
import 'package:myapp/screens/team_chat_screen.dart';
import 'package:myapp/widgets/loading_widget.dart';
import 'package:myapp/widgets/empty_state_widget.dart';

class ChatListScreen extends StatefulWidget {
  final String userRole;
  final String userName;

  const ChatListScreen({super.key, this.userRole = 'coach', this.userName = 'Usuario'});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<ConversationsRepository>();
      repo.fetch();
      repo.subscribeRealtime();
    });
  }

  @override
  void dispose() {
    context.read<ConversationsRepository>().unsubscribeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.watch<ConversationsRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat', style: GoogleFonts.oswald(fontWeight: FontWeight.bold)),
      ),
      body: repo.loading && repo.items.isEmpty
          ? const LoadingWidget(message: 'Cargando conversaciones...')
          : repo.items.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.chat_bubble_outline,
                  title: 'Sin conversaciones',
                  subtitle: 'El chat con el staff aparecerá aquí.',
                )
              : RefreshIndicator(
                  onRefresh: () => repo.fetch(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: repo.items.length,
                    itemBuilder: (context, i) {
                      final c = repo.items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text((c.participantName ?? c.participantId).isNotEmpty ? (c.participantName ?? c.participantId).substring(0, 1).toUpperCase() : '?'),
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(c.participantName ?? 'Chat')),
                              if (c.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(12)),
                                  child: Text('${c.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                            ],
                          ),
                          subtitle: Text(c.lastMessagePreview ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeamChatScreen(userRole: widget.userRole, userName: widget.userName),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
