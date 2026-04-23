import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/system/contactCubit.dart';
import 'package:eschool/data/models/system/contact.dart';
import 'package:eschool/data/repositories/system/contactRepository.dart';
import 'package:eschool/ui/widgets/system/contactCard.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();

  static Widget routeInstance() {
    return BlocProvider(
      create: (context) => ContactCubit(ContactRepository()),
      child: const ContactScreen(),
    );
  }
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedStatus;
  String _selectedSort = 'newest'; // newest or oldest

  @override
  void initState() {
    super.initState();
    
    // Load contacts on init
    Future.microtask(() {
      context.read<ContactCubit>().loadContacts(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildAppBar(BuildContext context) {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              left: 10,
              top: -2,
              child: const CustomBackButton(),
            ),
            Positioned(
              top: -1,
              child: Text(
                "Pesan & Laporan",
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari pesan atau laporan...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              onChanged: (value) {
                setState(() {}); // Only update UI, filtering is done client-side
              },
            ),
          ),
          const SizedBox(height: 12.0),

          // Jenis Filter
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 14.0,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4.0),
                Text(
                  'Jenis',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildCompactFilterChip(
                  'Semua',
                  _selectedType == null,
                  () => _setFilter(type: null),
                  icon: Icons.grid_view_rounded,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildCompactFilterChip(
                  'Pertanyaan',
                  _selectedType == 'inquiry',
                  () => _setFilter(type: 'inquiry'),
                  icon: Icons.help_outline_rounded,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildCompactFilterChip(
                  'Laporan',
                  _selectedType == 'report',
                  () => _setFilter(type: 'report'),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Status Filter
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Row(
              children: [
                Icon(
                  Icons.label_outlined,
                  size: 14.0,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4.0),
                Text(
                  'Status',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildCompactFilterChip(
                  'Semua',
                  _selectedStatus == null,
                  () => _setFilter(status: null),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildCompactFilterChip(
                  'Baru',
                  _selectedStatus == 'new',
                  () => _setFilter(status: 'new'),
                  icon: Icons.fiber_new_rounded,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildCompactFilterChip(
                  'Dibalas',
                  _selectedStatus == 'replied',
                  () => _setFilter(status: 'replied'),
                  icon: Icons.mark_email_read_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 16.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'newest',
                          child: Text('Urutkan: Terbaru'),
                        ),
                        DropdownMenuItem(
                          value: 'oldest',
                          child: Text('Urutkan: Terlama'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _setSort(value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterChip(String label, bool isSelected, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 7.0),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.0,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4.0),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setFilter({String? type, String? status}) {
    setState(() {
      // Only update the parameter that was explicitly passed
      if (type != null) {
        _selectedType = type;
      } else if (status == null && type == null) {
        // Reset both if both are null
        _selectedType = type;
        _selectedStatus = status;
      }
      
      if (status != null) {
        _selectedStatus = status;
      } else if (type == null && status == null) {
        // Already handled above
      }
    });
    // Filtering is done client-side in _buildContactListSliver
  }

  void _setSort(String sort) {
    setState(() {
      _selectedSort = sort;
    });
    // Sorting is done client-side in _buildContactListSliver
  }

  Widget _buildContactListSliver(ContactState state) {
    if (state is ContactError) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.0,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  state.errorMessage,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    context.read<ContactCubit>().refreshContacts();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is ContactLoaded) {
      // Apply client-side filtering
      var filteredContacts = List<Contact>.from(state.allContacts);
      
      // Filter by type
      if (_selectedType != null) {
        filteredContacts = filteredContacts.where((contact) => contact.type == _selectedType).toList();
      }
      
      // Filter by status
      if (_selectedStatus != null) {
        filteredContacts = filteredContacts.where((contact) => contact.status == _selectedStatus).toList();
      }
      
      // Filter by search query
      final searchQuery = _searchController.text.trim().toLowerCase();
      if (searchQuery.isNotEmpty) {
        filteredContacts = filteredContacts.where((contact) {
          return contact.subject.toLowerCase().contains(searchQuery) ||
                 contact.message.toLowerCase().contains(searchQuery);
        }).toList();
      }
      
      // Apply client-side sorting
      if (_selectedSort == 'newest') {
        filteredContacts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        filteredContacts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      
      if (filteredContacts.isEmpty) {
        // Check if there are any filters or search active
        final hasActiveFilters = _selectedType != null || 
                                  _selectedStatus != null || 
                                  _searchController.text.trim().isNotEmpty;
        
        return SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasActiveFilters ? Icons.search_off_rounded : Icons.inbox_outlined,
                    size: 64.0,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    hasActiveFilters ? 'Tidak Ada Hasil' : 'Belum Ada Pesan',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    hasActiveFilters 
                        ? 'Tidak ada pesan yang sesuai dengan pencarian atau filter Anda.'
                        : 'Anda belum mengirim pesan atau laporan apapun.',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  if (!hasActiveFilters)
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(Routes.submitContact);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Kirim Pesan'),
                    ),
                ],
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= filteredContacts.length) {
              // Load more indicator
              context.read<ContactCubit>().loadMoreContacts();
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final contact = filteredContacts[index];
            return FadeInUp(
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: index * 50),
              child: ContactCard(
                contact: contact,
                onTap: () {
                  Get.toNamed('/contact-details', arguments: {'contactId': contact.id});
                },
              ),
            );
          },
          childCount: filteredContacts.length + (state.contactResponse.hasMorePages ? 1 : 0),
        ),
      );
    }

    return const SliverToBoxAdapter(
      child: SizedBox.shrink(),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(
            height: Utils.getScrollViewTopPadding(
              context: context,
              appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
            ),
          ),
          // Filter skeleton
          _buildFilterSkeleton(),
          // Contact list skeleton
          ...List.generate(5, (index) => _buildContactCardSkeleton()),
          // Bottom padding agar tidak mentok ke navigation bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFilterSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar skeleton
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          // Filter chips skeleton
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCardSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 70,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    // Refresh to get all contacts, filtering is done client-side
    await context.read<ContactCubit>().loadContacts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Content with scrollable filter
          Align(
            alignment: Alignment.topCenter,
            child: BlocBuilder<ContactCubit, ContactState>(
              builder: (context, state) {
                if (state is ContactLoading) {
                  return _buildShimmerLoading();
                }
                
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Theme.of(context).colorScheme.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      // Top padding for app bar
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: Utils.getScrollViewTopPadding(
                            context: context,
                            appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                          ),
                        ),
                      ),
                      
                      // Filter Section (now scrollable)
                      SliverToBoxAdapter(
                        child: FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          child: _buildFilterSection(),
                        ),
                      ),
                      
                      // Contact List
                      _buildContactListSliver(state),
                      
                      // Bottom padding agar tidak mentok ke navigation bar
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 80.0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // App Bar
          _buildAppBar(context),
        ],
      ),
    );
  }
}
