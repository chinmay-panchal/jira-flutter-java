import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../User/UserModel/user_model.dart';
import '../../User/UserViewModel/user_view_model.dart';

class MemberSelectDialog extends StatefulWidget {
  final Set<String> initialSelected;
  final bool singleSelect;

  const MemberSelectDialog({
    super.key,
    required this.initialSelected,
    this.singleSelect = false,
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
  Widget build(BuildContext context) {
    final userVm = context.watch<UserViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                decoration: InputDecoration(
                  hintText: 'Search members',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: userVm.search,
              ),
            ),
            Expanded(
              child: userVm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: userVm.users.length,
                      itemBuilder: (_, i) {
                        final UserModel u = userVm.users[i];
                        final selected = selectedUids.contains(u.uid);

                        return ListTile(
                          title: Text('${u.firstName} ${u.lastName}'),
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
