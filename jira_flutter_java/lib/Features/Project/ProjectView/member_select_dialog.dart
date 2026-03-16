import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Auth/AuthViewModel/auth_view_model.dart';
import '../../User/UserModel/user_model.dart';
import '../../User/UserViewModel/user_view_model.dart';

class MemberSelectDialog extends StatefulWidget {
  final Set<String> initialSelected;
  final bool singleSelect;
  final bool hideCurrentUser;
  final List<UserModel>? overrideUsers;

  const MemberSelectDialog({
    super.key,
    required this.initialSelected,
    this.singleSelect = false,
    this.hideCurrentUser = false,
    this.overrideUsers,
  });

  @override
  State<MemberSelectDialog> createState() => _MemberSelectDialogState();
}

class _MemberSelectDialogState extends State<MemberSelectDialog> {
  final searchCtrl = TextEditingController();
  late Set<String> selectedUids;
  List<UserModel> _displayUsers = [];

  @override
  void initState() {
    super.initState();
    selectedUids = {...widget.initialSelected};
    if (widget.overrideUsers != null) {
      _displayUsers = List.of(widget.overrideUsers!);
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q, UserViewModel userVm) {
    if (widget.overrideUsers != null) {
      final query = q.toLowerCase().trim();
      setState(() {
        _displayUsers = widget.overrideUsers!.where((u) {
          final fullName = '${u.firstName} ${u.lastName}'.toLowerCase();
          return fullName.contains(query) ||
              u.email.toLowerCase().contains(query);
        }).toList();
      });
    } else {
      userVm.search(q);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVm = context.watch<UserViewModel>();
    final authVm = context.read<AuthViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    final List<UserModel> baseUsers = widget.overrideUsers != null
        ? _displayUsers
        : (widget.hideCurrentUser && authVm.uid != null
              ? userVm.users.where((u) => u.uid != authVm.uid).toList()
              : userVm.users);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 420,
        width: 380,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search members',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (q) => _onSearch(q, userVm),
              ),
            ),
            Expanded(
              child: userVm.isLoading && widget.overrideUsers == null
                  ? const Center(child: CircularProgressIndicator())
                  : baseUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: baseUsers.length,
                      itemBuilder: (_, i) {
                        final UserModel u = baseUsers[i];
                        final selected = selectedUids.contains(u.uid);
                        final isYou = u.uid == authVm.uid;

                        return ListTile(
                          selected: widget.singleSelect && selected,
                          selectedTileColor: colorScheme.primary.withOpacity(
                            0.08,
                          ),
                          onTap: () {
                            setState(() {
                              if (widget.singleSelect) {
                                selectedUids.clear();
                                if (!selected) selectedUids.add(u.uid);
                              } else {
                                selected
                                    ? selectedUids.remove(u.uid)
                                    : selectedUids.add(u.uid);
                              }
                            });
                          },
                          title: Text(
                            isYou ? 'You' : '${u.firstName} ${u.lastName}',
                            style: TextStyle(
                              fontWeight: isYou
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(u.email),
                          trailing: widget.singleSelect
                              ? null
                              : Checkbox(
                                  value: selected,
                                  onChanged: (v) {
                                    setState(() {
                                      v == true
                                          ? selectedUids.add(u.uid)
                                          : selectedUids.remove(u.uid);
                                    });
                                  },
                                ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, selectedUids);
                      },
                      child: const Text('Done'),
                    ),
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
