import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../../../../shared/design/design_tokens.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const _avatarTints = <Color>[
    Color(0xFFBBD6F4),
    Color(0xFFB8E4D0),
    Color(0xFFE4C4B8),
    Color(0xFFD4B8E4),
    Color(0xFFC8C8C8),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _pill({
    required Widget child,
    required Color background,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final notifier = ref.read(userProvider.notifier);

    final filteredUsers = state.users.where((user) {
      final query = _searchQuery.toLowerCase();
      return user.email.toLowerCase().contains(query) || 
             (user.whatsappNumber?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: surface,
      body: RefreshIndicator(
        color: primary,
        onRefresh: () => notifier.loadUsers(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Users', style: GoogleFonts.publicSans(fontSize: 26, fontWeight: FontWeight.w700, color: onSurface)),
              const SizedBox(height: 4),
              Text(
                'WORKSPACE MANAGEMENT',
                style: GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 11 * 0.05,
                  color: onSurfaceVar,
                ),
              ),
              const SizedBox(height: 4),
              Text('Team Directory', style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w700, color: onSurface)),
              const SizedBox(height: 20),
              
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x05191C1D), blurRadius: 20, offset: Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by email or phone...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search_rounded, color: onSurfaceVar, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ) 
                      : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              if (state.isLoading && state.users.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator(color: primary)),
                )
              else if (state.users.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'No users yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar),
                    ),
                  ),
                )
              else if (filteredUsers.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: outlineGhost),
                        const SizedBox(height: 16),
                        Text(
                          'No results found for "$_searchQuery"',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final tint = user.isActive ? _avatarTints[index % _avatarTints.length] : const Color(0xFFC8C8C8);

                    final role = user.role.toUpperCase();
                    final channelsCount = user.assignments.length;
                    final channelLabel = channelsCount == 1 ? 'Channel' : 'Channels';

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/admin/users/${user.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: tint.withOpacity(0.65),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: user.isActive ? primary : onSurfaceVar,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _pill(
                                        background: const Color(0xFFE8F0FB),
                                        child: Text(
                                          role,
                                          style: GoogleFonts.epilogue(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: primary,
                                            letterSpacing: 10 * 0.05,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _pill(
                                        background: surfaceLow,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.grid_view_rounded, size: 12, color: onSurfaceVar),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$channelsCount $channelLabel',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: onSurfaceVar),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () => context.push('/admin/users/new'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
