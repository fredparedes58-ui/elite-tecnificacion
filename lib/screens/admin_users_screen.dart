// ============================================================
// Admin: Gestión de usuarios. Lista, aprobar/revocar, asignar créditos.
// Paridad con React AdminUsers + UserManagement.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/repositories/users_repository.dart';
import 'package:myapp/repositories/credits_repository.dart';
import 'package:myapp/utils/snackbar_helper.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final startIndex = widget.initialTab == 'credits' ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: startIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersRepository>().fetch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleApproval(UserProfileItem user) async {
    final repo = context.read<UsersRepository>();
    final ok = await repo.updateApproval(user.id, !user.isApproved);
    if (!mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(
        context,
        user.isApproved ? 'Acceso revocado.' : 'Usuario aprobado.',
      );
    } else {
      SnackBarHelper.showError(context, 'Error al actualizar.');
    }
  }

  Future<void> _updateCredits(String userId, int newBalance) async {
    final creditsRepo = context.read<CreditsRepository>();
    final ok = await creditsRepo.setBalanceForUser(userId, newBalance);
    if (!mounted) return;
    if (ok) {
      context.read<UsersRepository>().invalidate();
      context.read<UsersRepository>().fetch(forceRefresh: true);
      SnackBarHelper.showSuccess(context, 'Créditos actualizados.');
    } else {
      SnackBarHelper.showError(context, 'Error al actualizar créditos.');
    }
  }

  void _openCreditsDialog(UserProfileItem user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CreditsDialog(
        userName: user.fullName ?? user.email,
        currentCredits: user.credits,
        onSave: (value) {
          Navigator.of(ctx).pop();
          _updateCredits(user.id, value);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersRepo = context.watch<UsersRepository>();
    final usersForCredits = List<UserProfileItem>.from(usersRepo.users)
      ..sort((a, b) => b.credits.compareTo(a.credits));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Usuarios',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Usuarios'),
            Tab(text: 'Créditos'),
          ],
        ),
      ),
      body: usersRepo.loading && usersRepo.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          :             TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(context, usersRepo.users, null),
                _buildTabContent(context, usersForCredits, 'Cartera de créditos'),
              ],
            ),
      floatingActionButton: usersRepo.loading == false && usersRepo.users.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => usersRepo.fetch(forceRefresh: true),
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Widget _buildTabContent(BuildContext context, List<UserProfileItem> users, String? subtitle) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => context.read<UsersRepository>().fetch(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(subtitle, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
            ],
            Text('${users.length} usuarios', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            if (users.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No hay usuarios', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 600;
                  if (wide) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Usuario')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Rol')),
                          DataColumn(label: Text('Créditos')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: users.map((user) => _buildDataRow(context, user)).toList(),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _buildUserCard(context, users[i]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, UserProfileItem user) {
    final theme = Theme.of(context);
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Icon(Icons.person, color: theme.colorScheme.primary)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(user.fullName ?? 'Sin nombre'),
            ],
          ),
        ),
        DataCell(Text(user.email, style: theme.textTheme.bodySmall)),
        DataCell(Text(user.role)),
        DataCell(
          InkWell(
            onTap: () => _openCreditsDialog(user),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('${user.credits}'),
              ],
            ),
          ),
        ),
        DataCell(
          Chip(
            label: Text(user.isApproved ? 'Aprobado' : 'Pendiente'),
            backgroundColor: user.isApproved
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.errorContainer,
          ),
        ),
        DataCell(
          user.role == 'admin'
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: () => _toggleApproval(user),
                  child: Text(user.isApproved ? 'Revocar' : 'Aprobar'),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, UserProfileItem user) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Icon(Icons.person, color: theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? 'Sin nombre',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        user.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          Chip(
                            label: Text(user.role, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              user.isApproved ? 'Aprobado' : 'Pendiente',
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openCreditsDialog(user),
                  icon: const Icon(Icons.account_balance_wallet, size: 18),
                  label: Text('${user.credits} créditos'),
                ),
                if (user.role != 'admin')
                  TextButton(
                    onPressed: () => _toggleApproval(user),
                    child: Text(user.isApproved ? 'Revocar' : 'Aprobar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _CreditsDialog extends StatefulWidget {
  const _CreditsDialog({
    required this.userName,
    required this.currentCredits,
    required this.onSave,
    required this.onCancel,
  });

  final String userName;
  final int currentCredits;
  final void Function(int value) onSave;
  final VoidCallback onCancel;

  @override
  State<_CreditsDialog> createState() => _CreditsDialogState();
}

class _CreditsDialogState extends State<_CreditsDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentCredits}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Créditos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Usuario: ${widget.userName}'),
          Text('Créditos actuales: ${widget.currentCredits}'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nuevos créditos',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final v = int.tryParse(_controller.text);
            if (v != null && v >= 0) {
              Navigator.of(context).pop();
              widget.onSave(v);
            }
          },
          child: const Text('Actualizar'),
        ),
      ],
    );
  }
}
