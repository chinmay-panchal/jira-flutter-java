import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jira_flutter_java/Core/socket/project_socket_service.dart';
import 'package:jira_flutter_java/Core/theme/theme_provider.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardView/project_details_dialog.dart';
import 'package:jira_flutter_java/Features/Dashboard/DashboardView/task_details_dialog.dart';
import 'package:jira_flutter_java/Features/Project/ProjectViewModel/project_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:jira_flutter_java/Core/theme/theme_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../DashboardViewModel/task_view_model.dart';
import '../DashboardModel/task_model.dart';
import 'create_todo_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final int projectId;

  const DashboardScreen({super.key, required this.projectId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PageController _pageController;
  final TextEditingController _searchController = TextEditingController();

  bool _isAutoScrolling = false;
  bool _isDragging = false;
  bool _shouldTrackPageChanges = true;
  DateTime? _edgeHoverStart;
  bool _initialPageSet = false;
  int? _currentPage;

  double get _screenWidth => MediaQuery.of(context).size.width;
  bool get _isMobile => _screenWidth < 600;
  bool get _isTablet => _screenWidth >= 600 && _screenWidth < 1000;
  bool get _isDesktop => _screenWidth >= 1000;

  // Filter state
  Set<String> _selectedAssigneeUids = {};
  bool _isFilterActive = false;
  String _searchQuery = '';
  bool _showOnlyMyIssues = true; // Default to true
  bool _isHoveringAvatars = false; // For avatar hover effect

  final sections = const ['TODO', 'IN_PROGRESS', 'QA', 'DONE'];
  void _handleSocketEvent(ProjectSocketEvent event) {
    if (event.type == ProjectEventType.memberRemoved) {
      final projectId = (event.payload['projectId'] as num?)?.toInt();
      final memberUid = event.payload['memberUid'] as String?;
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      if (projectId == widget.projectId && memberUid == currentUid) {
        if (mounted) _showAccessRevokedDialog();
      }

      // Refresh member list for avatar filters
      if (projectId == widget.projectId && mounted) {
        context.read<UserViewModel>().refreshProjectMembers(widget.projectId);
      }
    }

    if (event.type == ProjectEventType.memberAdded) {
      final projectId = (event.payload['projectId'] as num?)?.toInt();
      if (projectId == widget.projectId && mounted) {
        context.read<UserViewModel>().refreshProjectMembers(widget.projectId);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _pageController.addListener(_onPageControllerChange);
    _searchController.addListener(_onSearchChanged);

    // Listen for member removal
    ProjectSocketService().addListener(_handleSocketEvent);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<TaskViewModel>();
      final userVm = context.read<UserViewModel>();

      if (vm.tasks.isEmpty) {
        await vm.loadTasks(widget.projectId);
        await userVm.loadProjectMembers(widget.projectId);
      }

      if (mounted && !kIsWeb) {
        _setInitialPage(vm);
      }
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  String _getAssigneeName(BuildContext context, String? uid) {
    if (uid == null) return 'N/A';

    final userVm = context.watch<UserViewModel>();

    if (userVm.isLoading && userVm.users.isEmpty) {
      return 'Loading...';
    }

    final user = userVm.users.firstWhereOrNull((u) => u.uid == uid);

    if (user == null) {
      return 'N/A';
    }

    // Get initials from first and last name
    final firstName = user.firstName.trim();
    final lastName = user.lastName.trim();

    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }

    return initials.isEmpty ? 'NA' : initials;
  }

  String _getFullName(BuildContext context, String? uid) {
    if (uid == null) return 'N/A';

    final userVm = context.read<UserViewModel>();
    final user = userVm.users.firstWhereOrNull((u) => u.uid == uid);

    if (user == null) return 'Unknown';

    return '${user.firstName} ${user.lastName}'.trim();
  }

  Color _getAvatarColor(String initials) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final index = initials.hashCode % colors.length;
    return colors[index.abs()];
  }

  void _showAllMembersDialog() {
    final userVm = context.read<UserViewModel>();
    final authVm = context.read<AuthViewModel>();
    final currentUserId = authVm.uid;

    final isMobile = MediaQuery.of(context).size.width < 600;
    final allMembers = userVm.users.toList();
    final members = _isDesktop ? allMembers.skip(5).toList() : allMembers;

    // Create a local copy of selected UIDs for the dialog
    Set<String> tempSelectedUids = Set.from(_selectedAssigneeUids);

    if (isMobile) {
      // Show enhanced bottom sheet for mobile
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) => StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final colorScheme = Theme.of(context).colorScheme;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Enhanced Header with solid primary color background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar on blue background
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Filter by Member',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${members.length} team members',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Material(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => Navigator.pop(bottomSheetContext),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Selection counter chip
                        if (tempSelectedUids.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${tempSelectedUids.length} selected',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Enhanced Members list with better spacing and design
                  Expanded(
                    child: members.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No team members',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            itemCount: members.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = members[index];
                              final initials = _getAssigneeName(
                                context,
                                user.uid,
                              );
                              final color = _getAvatarColor(initials);
                              final isSelected = tempSelectedUids.contains(
                                user.uid,
                              );
                              final isCurrentUser = user.uid == currentUserId;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setBottomSheetState(() {
                                      if (isSelected) {
                                        tempSelectedUids.remove(user.uid);
                                      } else {
                                        tempSelectedUids.add(user.uid);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary.withOpacity(
                                              0.08,
                                            )
                                          : (isDarkMode
                                                ? Colors.grey.shade900
                                                : Colors.grey.shade50),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : (isDarkMode
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade200),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Avatar with selection indicator
                                        Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? colorScheme.primary
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor: color,
                                                radius: 24,
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Theme.of(
                                                        context,
                                                      ).scaffoldBackgroundColor,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),

                                        const SizedBox(width: 16),

                                        // User info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      isCurrentUser
                                                          ? 'You'
                                                          : '${user.firstName} ${user.lastName}'
                                                                .trim(),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                        color: isDarkMode
                                                            ? Colors.white
                                                            : Colors
                                                                  .grey
                                                                  .shade900,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isCurrentUser) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: colorScheme
                                                            .primary
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'ME',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: colorScheme
                                                              .primary,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                user.email,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Selection indicator
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: isSelected
                                                ? colorScheme.primary
                                                : Colors.grey.shade400,
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Enhanced Action buttons with better styling
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          if (tempSelectedUids.isNotEmpty)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setBottomSheetState(() {
                                    tempSelectedUids.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear_all, size: 20),
                                label: const Text('Clear'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          if (tempSelectedUids.isNotEmpty)
                            const SizedBox(width: 12),
                          Expanded(
                            flex: tempSelectedUids.isEmpty ? 1 : 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedAssigneeUids = tempSelectedUids;
                                  _isFilterActive =
                                      _selectedAssigneeUids.isNotEmpty;
                                  if (_isFilterActive) {
                                    _showOnlyMyIssues = false;
                                  }
                                });
                                Navigator.pop(bottomSheetContext);
                              },
                              icon: Icon(
                                tempSelectedUids.isEmpty
                                    ? Icons.filter_list_off
                                    : Icons.filter_alt,
                                size: 20,
                              ),
                              label: Text(
                                'Apply (${tempSelectedUids.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Show dialog for web/desktop
      showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'More Members',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(dialogContext),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select members to filter tasks',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),

                  // Grid of members
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final user = members[index];
                        final initials = _getAssigneeName(context, user.uid);
                        final color = _getAvatarColor(initials);
                        final isSelected = tempSelectedUids.contains(user.uid);
                        final isCurrentUser = user.uid == currentUserId;

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                tempSelectedUids.remove(user.uid);
                              } else {
                                tempSelectedUids.add(user.uid);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1)
                                  : (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color,
                                      radius: 28,
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isCurrentUser
                                      ? 'You'
                                      : '${user.firstName} ${user.lastName}'
                                            .trim(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (tempSelectedUids.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              tempSelectedUids.clear();
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedAssigneeUids = tempSelectedUids;
                            _isFilterActive = _selectedAssigneeUids.isNotEmpty;
                            if (_isFilterActive) {
                              _showOnlyMyIssues = false;
                            }
                          });
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          tempSelectedUids.isEmpty
                              ? 'Show All'
                              : 'Apply Filter (${tempSelectedUids.length})',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  List<TaskModel> _getFilteredTasks(List<TaskModel> tasks) {
    var filtered = tasks;

    // Apply "Only My Issues" filter
    if (_showOnlyMyIssues) {
      final currentUserId = context.read<AuthViewModel>().uid;
      filtered = filtered
          .where((task) => task.assignedUserUid == currentUserId)
          .toList();
    }
    // Apply assignee filter (from clicking circles) - multi-select
    else if (_isFilterActive && _selectedAssigneeUids.isNotEmpty) {
      filtered = filtered
          .where((task) => _selectedAssigneeUids.contains(task.assignedUserUid))
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(_searchQuery) ||
            task.description.toLowerCase().contains(_searchQuery) ||
            'TICKET-${task.id}'.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // REPLACE only the _taskCard() method in dashboard_screen.dart with this.
  // Everything else in that file stays exactly the same.
  // ─────────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────────
  // REPLACE only the _taskCard() method in dashboard_screen.dart with this.
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _taskCard(
    BuildContext context,
    TaskModel task, {
    Color? accentColor,
    bool isDragging = false,
  }) {
    final assigneeName = _getAssigneeName(context, task.assignedUserUid);
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    final avatarColor = _getAvatarColor(assigneeName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Format points label: "3 pts" or "1 pt" or "1.5 pts"
    String? pointsLabel;
    if (task.storyPoints != null) {
      final pts = task.storyPoints!;
      final ptsStr = pts == pts.truncateToDouble()
          ? pts.toInt().toString()
          : pts.toStringAsFixed(1);
      pointsLabel = '$ptsStr ${pts == 1.0 ? 'PT' : 'PTS'}';
    }

    return InkWell(
      onTap: isDragging
          ? null
          : () {
              final project = context.read<ProjectViewModel>().byId(
                task.projectId,
              );
              if (project == null) return;
              showDialog(
                context: context,
                builder: (dialogCtx) => ChangeNotifierProvider.value(
                  value: context.read<TaskViewModel>(),
                  child: Consumer<TaskViewModel>(
                    builder: (_, taskVm, __) {
                      final liveTask = taskVm.tasks.firstWhere(
                        (t) => t.id == task.id,
                        orElse: () => task,
                      );
                      return TaskDetailDialog(
                        task: liveTask,
                        project: project,
                        taskVm: taskVm,
                      );
                    },
                  ),
                ),
              );
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──────────────────────────────────────────────────
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Description ────────────────────────────────────────────
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // ── Bottom row ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ticket chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TICKET-${task.id}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Story points pill — neutral, minimal, won't clash with any theme
                  if (pointsLabel != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            pointsLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Assignee avatar
                  Tooltip(
                    message: _getFullName(context, task.assignedUserUid),
                    child: CircleAvatar(
                      backgroundColor: avatarColor,
                      radius: 14,
                      child: Text(
                        assigneeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPageControllerChange() {
    if (!_shouldTrackPageChanges) return;

    if (_pageController.hasClients && _pageController.page != null) {
      final newPage = _pageController.page!.round();
      if (_currentPage != newPage) {
        _currentPage = newPage;
      }
    }
  }

  @override
  void dispose() {
    ProjectSocketService().removeListener(_handleSocketEvent);
    _pageController.removeListener(_onPageControllerChange);
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setInitialPage(TaskViewModel vm) {
    if (_initialPageSet) return;
    if (!_pageController.hasClients) return;

    for (int i = 0; i < sections.length; i++) {
      final status = sections[i];
      final count = vm.byStatus(status).length;

      if (count > 0) {
        _pageController.jumpToPage(i);
        _currentPage = i;
        _initialPageSet = true;
        return;
      }
    }

    _pageController.jumpToPage(0);
    _currentPage = 0;
    _initialPageSet = true;
  }

  bool _isValidTransition(String from, String to) {
    if (from == to) return false;

    bool isValid = false;
    if (from == 'TODO') {
      isValid = to == 'IN_PROGRESS' || to == 'QA';
    } else if (from == 'IN_PROGRESS') {
      isValid = to == 'TODO' || to == 'QA';
    } else if (from == 'QA') {
      isValid = to == 'IN_PROGRESS' || to == 'TODO' || to == 'DONE';
    }
    return isValid;
  }

  Future<void> _handleAutoScroll(Offset position, BuildContext context) async {
    if (_isAutoScrolling || !_isDragging) return;

    final width = MediaQuery.of(context).size.width;
    const edgeSize = 100;
    const hoverDelay = Duration(milliseconds: 200);

    final isLeft = position.dx < edgeSize;
    final isRight = position.dx > width - edgeSize;

    if (!isLeft && !isRight) {
      _edgeHoverStart = null;
      return;
    }

    _edgeHoverStart ??= DateTime.now();

    if (DateTime.now().difference(_edgeHoverStart!) < hoverDelay) return;
    if (_pageController.page == null) return;

    final currentPage = _pageController.page!.round();

    if (isLeft && currentPage > 0) {
      _isAutoScrolling = true;
      _edgeHoverStart = null;
      await _pageController.animateToPage(
        currentPage - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      _isAutoScrolling = false;
    } else if (isRight && currentPage < sections.length - 1) {
      _isAutoScrolling = true;
      _edgeHoverStart = null;
      await _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      _isAutoScrolling = false;
    }
  }

  void _showAccessRevokedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (alertContext) => AlertDialog(
        title: const Text('Access removed'),
        content: const Text('You are no longer a member of this project.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(alertContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(BuildContext context, String status, TaskViewModel vm) {
    final color = Theme.of(context).colorScheme.primary;

    final allTasks = vm.byStatus(status);
    final tasks = _getFilteredTasks(allTasks);

    // Status icons
    IconData statusIcon;
    switch (status) {
      case 'TODO':
        statusIcon = Icons.assignment_outlined;
        break;
      case 'IN_PROGRESS':
        statusIcon = Icons.pending_actions;
        break;
      case 'QA':
        statusIcon = Icons.bug_report_outlined;
        break;
      case 'DONE':
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusIcon = Icons.circle_outlined;
    }

    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) {
        return _isValidTransition(details.data.status, status);
      },
      onAcceptWithDetails: (details) {
        final task = details.data;
        _isDragging = false;
        _edgeHoverStart = null;
        _shouldTrackPageChanges = false;

        vm.updateTaskStatus(taskId: task.id, status: status);

        _shouldTrackPageChanges = true;
      },
      onLeave: (_) {
        _edgeHoverStart = null;
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.all(8.0), // Changed from Padding to margin
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: isHovering
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tasks list - FIXED: Added proper scrolling
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _showOnlyMyIssues ||
                                      _isFilterActive ||
                                      _searchQuery.isNotEmpty
                                  ? 'No matching tasks'
                                  : 'No tasks',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: tasks.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (_, i) {
                          final task = tasks[i];

                          return Draggable<TaskModel>(
                            data: task,
                            onDragStarted: () => _isDragging = true,
                            onDragEnd: (_) {
                              _isDragging = false;
                              _edgeHoverStart = null;
                            },
                            onDraggableCanceled: (_, __) {
                              _isDragging = false;
                              _edgeHoverStart = null;
                            },
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: kIsWeb
                                    ? _isDesktop
                                          ? (MediaQuery.of(context).size.width -
                                                    96) /
                                                4 // 4 columns
                                          : (MediaQuery.of(context).size.width -
                                                    56) /
                                                2 // 2 columns (tablet)
                                    : 280,
                                child: _taskCard(
                                  context,
                                  task,
                                  accentColor: color,
                                  isDragging: true,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _taskCard(context, task),
                            ),
                            child: _taskCard(context, task, accentColor: color),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileFilters(BuildContext context) {
    return Row(
      children: [
        // Filter button for mobile
        InkWell(
          onTap: _showAllMembersDialog,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isFilterActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFilterActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isFilterActive ? Icons.filter_alt : Icons.filter_list,
                  size: 18,
                  color: _isFilterActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  _isFilterActive
                      ? '${_selectedAssigneeUids.length}'
                      : 'Filter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isFilterActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // "Only My Issues" button - icon only for mobile
        InkWell(
          onTap: () {
            setState(() {
              _showOnlyMyIssues = !_showOnlyMyIssues;
              if (_showOnlyMyIssues) {
                _selectedAssigneeUids.clear();
                _isFilterActive = false;
              }
            });
          },
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _showOnlyMyIssues
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100),
              shape: BoxShape.circle,
              border: Border.all(
                color: _showOnlyMyIssues
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
            child: Icon(
              _showOnlyMyIssues ? Icons.person : Icons.person_outline,
              size: 18,
              color: _showOnlyMyIssues
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFilters(
    BuildContext context,
    List members,
    String? currentUserId,
  ) {
    final displayMembers = members.take(5).toList();
    final remainingCount = members.length - 5;

    return Row(
      children: [
        // Member avatars - clickable filters (multi-select) with overlapping effect
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringAvatars = true),
          onExit: (_) => setState(() => _isHoveringAvatars = false),
          child: SizedBox(
            width: _isHoveringAvatars
                ? displayMembers.length * 42.0 +
                      (remainingCount > 0 ? 42.0 : 8.0)
                : displayMembers.length * 28.0 +
                      (remainingCount > 0 ? 40.0 : 12.0),
            height: 40,
            child: Stack(
              children: [
                ...displayMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  final initials = _getAssigneeName(context, user.uid);
                  final color = _getAvatarColor(initials);
                  final isSelected =
                      _selectedAssigneeUids.contains(user.uid) &&
                      !_showOnlyMyIssues;
                  final isCurrentUser = user.uid == currentUserId;

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    left: _isHoveringAvatars ? index * 42.0 : index * 28.0,
                    child: Tooltip(
                      message:
                          '${user.firstName} ${user.lastName}'.trim() +
                          (isCurrentUser ? ' (You)' : ''),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedAssigneeUids.contains(user.uid)) {
                              _selectedAssigneeUids.remove(user.uid);
                            } else {
                              _selectedAssigneeUids.add(user.uid);
                            }
                            _isFilterActive = _selectedAssigneeUids.isNotEmpty;
                            if (_isFilterActive) {
                              _showOnlyMyIssues = false;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade900
                                  : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                backgroundColor: color,
                                radius: 19,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: color, width: 3),
                                  ),
                                ),
                              if (isSelected)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                if (remainingCount > 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    left: _isHoveringAvatars
                        ? displayMembers.length * 42.0
                        : displayMembers.length * 28.0,
                    child: InkWell(
                      onTap: _showAllMembersDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade900
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 4),

        // "Only My Issues" text button
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showOnlyMyIssues = !_showOnlyMyIssues;
              if (_showOnlyMyIssues) {
                _selectedAssigneeUids.clear();
                _isFilterActive = false;
              }
            });
          },
          icon: Icon(
            _showOnlyMyIssues ? Icons.person : Icons.person_outline,
            size: 18,
          ),
          label: const Text('Only My Issues'),
          style: TextButton.styleFrom(
            foregroundColor: _showOnlyMyIssues
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade600,
            backgroundColor: _showOnlyMyIssues
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: _showOnlyMyIssues
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final userVm = context.watch<UserViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final currentUserId = authVm.uid;
    final members = userVm.users.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search bar with flexible width
          Flexible(
            flex: 3,
            child: Container(
              height: 38,
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 18,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey.shade500,
                            size: 16,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Filters - always inline
          if (members.isNotEmpty)
            _isMobile
                ? _buildMobileFilters(context)
                : _isTablet
                ? _buildMobileFilters(context)
                : _buildDesktopFilters(context, members, currentUserId),

          const Spacer(),

          // Active filter badge
          if (_isFilterActive && _selectedAssigneeUids.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedAssigneeUids.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => setState(() {
                      _selectedAssigneeUids.clear();
                      _isFilterActive = false;
                    }),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(TaskViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Row 1: TODO + IN_PROGRESS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 420,
                  child: _buildColumn(context, 'TODO', vm),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 420,
                  child: _buildColumn(context, 'IN_PROGRESS', vm),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: QA + DONE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 420,
                  child: _buildColumn(context, 'QA', vm),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 420,
                  child: _buildColumn(context, 'DONE', vm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TaskViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!_initialPageSet && vm.tasks.isNotEmpty && !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setInitialPage(vm);
      });
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Consumer<ProjectViewModel>(
          builder: (context, projectVm, _) {
            final project = projectVm.byId(widget.projectId);
            return Text(
              project?.name ?? 'Dashboard',
              style: const TextStyle(fontWeight: FontWeight.bold),
            );
          },
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Project details',
            icon: const Icon(Icons.work_outline),
            onPressed: () async {
              final userVm = context.read<UserViewModel>();

              try {
                await userVm.loadProjectMembers(widget.projectId);

                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (_) =>
                      ProjectDetailsDialog(projectId: widget.projectId),
                );
              } catch (_) {
                if (!mounted) return;
                _showAccessRevokedDialog();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              child: const Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Theme Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                Navigator.pop(context);
                await context.read<AuthViewModel>().logout();
              },
            ),
          ],
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter bar
                _buildFilterBar(context),

                // Main content
                Expanded(
                  child: kIsWeb
                      ? _isDesktop
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: sections.map((status) {
                                    return Expanded(
                                      child: _buildColumn(context, status, vm),
                                    );
                                  }).toList(),
                                ),
                              )
                            : _buildTabletLayout(vm)
                      : Listener(
                          onPointerMove: (e) =>
                              _handleAutoScroll(e.position, context),
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const ClampingScrollPhysics(),
                            padEnds: false,
                            itemCount: sections.length,
                            onPageChanged: (page) {
                              _currentPage = page;
                            },
                            itemBuilder: (_, index) {
                              final status = sections[index];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: _buildColumn(context, status, vm),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final taskVm = context.read<TaskViewModel>();
          final userVm = context.read<UserViewModel>();

          try {
            await userVm.loadProjectMembers(widget.projectId);

            if (!mounted) return;
            showDialog(
              context: context,
              builder: (_) =>
                  CreateTodoDialog(projectId: widget.projectId, taskVm: taskVm),
            );
          } catch (_) {
            if (!mounted) return;
            _showAccessRevokedDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        elevation: 4,
      ),
    );
  }
}
