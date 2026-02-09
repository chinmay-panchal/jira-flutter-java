import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Auth/AuthViewModel/auth_view_model.dart';
import '../../User/UserModel/user_model.dart';
import '../../User/UserViewModel/user_view_model.dart';

class MemberSelectDialog extends StatefulWidget {
  final Set<String> initialSelected;
  final bool singleSelect;
  final bool hideCurrentUser;

  const MemberSelectDialog({
    super.key,
    required this.initialSelected,
    this.singleSelect = false,
    this.hideCurrentUser = false,
  });

  @override
  State<MemberSelectDialog> createState() => _MemberSelectDialogState();
}

class _MemberSelectDialogState extends State<MemberSelectDialog> {
  final searchCtrl = TextEditingController();
  late Set<String> selectedUids;

  @override
  void initState() {
    super.initState();
    selectedUids = {...widget.initialSelected};
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userVm = context.watch<UserViewModel>();
    final authVm = context.read<AuthViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    final List<UserModel> users = widget.hideCurrentUser && authVm.uid != null
        ? userVm.users.where((u) => u.uid != authVm.uid).toList()
        : userVm.users;

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
                onChanged: userVm.search,
              ),
            ),
            Expanded(
              child: userVm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                  ? Center(
                      child: Text(
                        'No members found',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (_, i) {
                        final UserModel u = users[i];
                        final selected = selectedUids.contains(u.uid);
                        final isYou = u.uid == authVm.uid;

                        return ListTile(
                          title: Text(
                            isYou ? 'You' : '${u.firstName} ${u.lastName}',
                            style: TextStyle(
                              fontWeight: isYou
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(u.email),
                          trailing: Checkbox(
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (widget.singleSelect) {
                                  selectedUids.clear();
                                  if (v == true) {
                                    selectedUids.add(u.uid);
                                  }
                                } else {
                                  v == true
                                      ? selectedUids.add(u.uid)
                                      : selectedUids.remove(u.uid);
                                }
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
