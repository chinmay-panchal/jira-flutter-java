import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../User/UserViewModel/user_view_model.dart';
import '../../User/UserModel/user_model.dart';
import '../ProjectModel/project_form_model.dart';
import '../ProjectViewModel/project_view_model.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  DateTime? deadline;

  final Set<String> selectedUids = {};

  @override
  void initState() {
    super.initState();
    context.read<UserViewModel>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final userVm = context.watch<UserViewModel>();

    return AlertDialog(
      title: const Text('Create Project'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 8),
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(labelText: 'Search members'),
              onChanged: userVm.search,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
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
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => deadline = d);
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(deadline == null
                      ? 'Select deadline'
                      : '${deadline!.day}/${deadline!.month}/${deadline!.year}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: deadline == null
              ? null
              : () async {
                  await context.read<ProjectViewModel>().createProject(
                        ProjectFormModel(
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          members: selectedUids.toList(),
                          lastDate: deadline!,
                        ),
                      );
                  Navigator.pop(context);
                },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
