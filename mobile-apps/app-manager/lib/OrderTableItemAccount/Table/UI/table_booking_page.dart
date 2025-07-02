import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/Themes/colors.dart';
import 'package:hungerz_store/cubits/reservation_cubit.dart';
import 'package:hungerz_store/models/reservation_model.dart';
import 'package:hungerz_store/services/reservation_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/foundation.dart';

class TableBookingPageWithProvider extends StatelessWidget {
  const TableBookingPageWithProvider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReservationCubit(context.read<ReservationService>())..fetchAllReservations(),
      child: const TableBookingPage(),
    );
  }
}

class TableBookingPage extends StatefulWidget {
  const TableBookingPage({Key? key}) : super(key: key);

  @override
  State<TableBookingPage> createState() => _TableBookingPageState();
}

class _TableBookingPageState extends State<TableBookingPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isRefreshing = false;

  late final AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Changed to 4 tabs
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    _refreshAnimationController.forward().then((_) {
      _refreshAnimationController.reset();
    });
    
    await context.read<ReservationCubit>().fetchAllReservations();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('[TableBookingPage] BUILD METHOD EXECUTED - LOGS SHOULD BE WORKING!');
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: BlocBuilder<ReservationCubit, ReservationState>(
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(state),
              _buildUpcomingTab(state),
              _buildCompletedTab(state),
              _buildCalendarTab(state), // New calendar tab
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      title: const Text(
        'Table Reservations',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
            ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
          icon: AnimatedBuilder(
            animation: _refreshAnimationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimationController.value * 2 * 3.14,
            child: Icon(
                    _isRefreshing ? Icons.hourglass_top : Icons.refresh_rounded,
              color: kMainColor,
            ),
                );
              },
          ),
          onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Refresh',
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: kMainColor,
        indicatorWeight: 3,
        labelColor: kMainColor,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Upcoming'),
          Tab(text: 'Completed'),
          Tab(text: 'Calendar'), // New calendar tab
        ],
      ),
    );
  }

  Widget _buildDashboardTab(ReservationState state) {
    if (state is ReservationLoading) {
      return _buildLoadingView();
    } else if (state is ReservationLoaded) {
      return _buildDashboardContent(state);
    } else if (state is ReservationError) {
      return _buildErrorView(state.message);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildDashboardContent(ReservationLoaded state) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(state),
            const SizedBox(height: 24),
            _buildTodaySection(state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ReservationLoaded state) {
    final stats = state.stats;
    final totalRevenueValue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final averageRevenueValue = (stats['averageRevenue'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6, // Increased aspect ratio to prevent overflow
          children: [
            _buildStatCard(
              'Today\'s Bookings',
              '${stats['todayReservations'] ?? 0}',
              Icons.calendar_today_rounded,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Guests',
              '${stats['todayGuests'] ?? 0}',
              Icons.people_rounded,
              Colors.green,
            ),
            _buildStatCard(
              'Revenue',
              '${totalRevenueValue.toStringAsFixed(2)} DA',
              Icons.attach_money_rounded,
              Colors.purple,
            ),
            _buildStatCard(
              'Avg. Revenue',
              '${averageRevenueValue.toStringAsFixed(2)} DA',
              Icons.trending_up_rounded,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18), // Reduced icon size
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8), // Fixed spacing instead of Spacer
          Flexible( // Wrapped in Flexible to prevent overflow
                  child: Text(
              value,
              style: const TextStyle(
                fontSize: 18, // Reduced font size
                          fontWeight: FontWeight.bold,
                color: Colors.black87,
                        ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          Flexible( // Wrapped in Flexible to prevent overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11, // Reduced font size
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(ReservationLoaded state) {
    final todayReservations = state.confirmedReservations.where((res) =>
        res.reservationTime.day == DateTime.now().day &&
        res.reservationTime.month == DateTime.now().month &&
        res.reservationTime.year == DateTime.now().year).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const Text(
          'Today\'s Reservations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (todayReservations.isEmpty)
          _buildEmptyState('No reservations for today', Icons.event_note_rounded)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayReservations.length,
            itemBuilder: (context, index) => _buildReservationCard(
              todayReservations[index],
              isUpcoming: true,
          ),
          ),
      ],
    );
  }

  Widget _buildUpcomingTab(ReservationState state) {
    if (state is ReservationLoading) {
      return _buildLoadingView();
    } else if (state is ReservationLoaded) {
      return _buildReservationsList(state.confirmedReservations, isUpcoming: true);
    } else if (state is ReservationError) {
      return _buildErrorView(state.message);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildCompletedTab(ReservationState state) {
    if (state is ReservationLoading) {
      return _buildLoadingView();
    } else if (state is ReservationLoaded) {
      return _buildReservationsList(state.completedReservations, isUpcoming: false);
    } else if (state is ReservationError) {
      return _buildErrorView(state.message);
    }
    return const Center(child: CircularProgressIndicator());
  }

  // New Calendar Tab
  Widget _buildCalendarTab(ReservationState state) {
    if (state is ReservationLoading) {
      return _buildLoadingView();
    } else if (state is ReservationLoaded) {
      return _buildCalendarView(state);
    } else if (state is ReservationError) {
      return _buildErrorView(state.message);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildCalendarView(ReservationLoaded state) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeSelector(),
            const SizedBox(height: 24),
            _buildDateRangeStats(state),
            const SizedBox(height: 24),
            _buildFilteredReservations(state),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
          return Container(
      padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'From',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateSelector(
                  'To',
                  _endDate,
                  (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _applyDateFilter(),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Apply Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
            ),
          );
  }

  Widget _buildDateSelector(String label, DateTime date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeStats(ReservationLoaded state) {
    final filteredReservations = _getFilteredReservations(state);
    final totalReservations = filteredReservations.length;
    final totalGuests = filteredReservations.fold<int>(0, (sum, res) => sum + res.guests);
    final totalRevenue = filteredReservations.fold<double>(0, (sum, res) => sum + res.totalRevenue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stats for ${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Reservations',
                  totalReservations.toString(),
                  Icons.event_rounded,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Guests',
                  totalGuests.toString(),
                  Icons.people_rounded,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Revenue',
                  '\$${totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money_rounded,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
      );
    }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilteredReservations(ReservationLoaded state) {
    final filteredReservations = _getFilteredReservations(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reservations in Date Range',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (filteredReservations.isEmpty)
          _buildEmptyState('No reservations in selected date range', Icons.event_available_rounded)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredReservations.length,
            itemBuilder: (context, index) => _buildReservationCard(
              filteredReservations[index],
              isUpcoming: filteredReservations[index].status != 'completed',
            ),
          ),
      ],
    );
  }

  List<Reservation> _getFilteredReservations(ReservationLoaded state) {
    final allReservations = [
      ...state.confirmedReservations,
      ...state.completedReservations,
    ];

    return allReservations.where((reservation) {
      final reservationDate = reservation.reservationTime;
      return reservationDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
             reservationDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => b.reservationTime.compareTo(a.reservationTime));
  }

  void _applyDateFilter() {
    setState(() {}); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Date filter applied to calendar view'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildReservationsList(List<Reservation> reservations, {required bool isUpcoming}) {
    if (reservations.isEmpty) {
      return _buildEmptyState(
        isUpcoming ? 'No upcoming reservations' : 'No completed reservations',
        isUpcoming ? Icons.event_available_rounded : Icons.history_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
        itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
              position: index,
          duration: const Duration(milliseconds: 300),
              child: SlideAnimation(
            verticalOffset: 30,
                child: FadeInAnimation(
              child: _buildReservationCard(reservations[index], isUpcoming: isUpcoming),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation, {required bool isUpcoming}) {
    return Slidable(
      key: ValueKey(reservation.id),
      endActionPane: isUpcoming ? ActionPane(
        motion: const BehindMotion(),
              children: [
                SlidableAction(
            onPressed: (_) => _markCompleted(reservation),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
            icon: Icons.check_rounded,
                  label: 'Complete',
            borderRadius: BorderRadius.circular(12),
                ),
              ],
      ) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(reservation.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            child: Icon(
                isUpcoming ? Icons.schedule_rounded : Icons.check_circle_rounded,
                color: _getStatusColor(reservation.status),
            ),
          ),
            title: Text(
              'Table ${reservation.table?.tableId ?? "N/A"}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                      Expanded( // Fixed overflow with Expanded
                    child: Text(
                          '${reservation.reservationDateDisplay} • ${reservation.reservationTimeDisplay}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                      Icon(Icons.people_rounded, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                      Text(
                      '${reservation.guests} guests',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ],
              ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(reservation.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
            ),
              child: Text(
                reservation.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(reservation.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
              ),
            ),
          ),
          children: [
              _buildExpandedContent(reservation, isUpcoming),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(Reservation reservation, bool isUpcoming) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          _buildDetailRow(
            Icons.schedule_rounded,
            'Reservation Time',
                        '${reservation.reservationDateDisplay} at ${reservation.reservationTimeDisplay}',
                  ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.people_rounded,
            'Guests',
            '${reservation.guests} people',
                  ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.restaurant_menu_rounded,
            'Pre-selected Menu',
            (reservation.preSelectedMenu as List?)?.isNotEmpty == true
                ? (reservation.preSelectedMenu as List).map((item) => item.name).join(', ')
                : 'None selected',
                  ),
          if (reservation.status == 'completed') ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.attach_money_rounded,
              'Total Revenue',
              '\$${reservation.totalRevenue.toStringAsFixed(2)}',
                          valueColor: Colors.green,
                        ),
                      ],
                  const SizedBox(height: 16),
          // Fixed button layout to prevent overflow
          Column(
                    children: [
                      if (isUpcoming) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditDialog(reservation),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMainColor,
                          side: BorderSide(color: kMainColor),
                        ),
                          ),
                        ),
                        const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showCancelDialog(reservation),
                        icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          ),
                      ),
                    ),
                  ],
                        ),
                      ] else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceiptDialog(reservation),
                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                          label: const Text('View Receipt'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMainColor,
                      side: BorderSide(color: kMainColor),
                    ),
                          ),
                        ),
                    ],
                  ),
                ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox( // Fixed width instead of Expanded to prevent overflow
          width: 80,
          child: Text(
            '$title:',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded( // Only the value gets expanded space
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            softWrap: true,
              ),
            ),
          ],
    );
  }

  Widget _buildLoadingView() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[300],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey[600]!;
    }
  }

  // Helper method for marking reservation as completed
  void _markCompleted(Reservation reservation) {
    context.read<ReservationCubit>().markReservationCompleted(reservation.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reservation ${reservation.table?.tableId ?? 'N/A'} marked as completed.'),
        backgroundColor: Colors.green,
      ),
          );
    }

  // Helper method for showing edit dialog
  void _showEditDialog(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Reservation'),
        content: const Text('Edit feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper method for showing cancel confirmation dialog
  void _showCancelDialog(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ReservationCubit>().cancelReservation(reservation.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservation cancelled.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  // Helper method for showing receipt dialog
  void _showReceiptDialog(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reservation Receipt'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('Table: ${reservation.table?.tableId ?? 'N/A'}'),
              Text('Guests: ${reservation.guests}'),
              Text('Time: ${reservation.reservationTimeDisplay}'),
              Text('Revenue: \$${reservation.totalRevenue.toStringAsFixed(2)}'),
              // Add more receipt details here if available in Reservation model
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// External StatelessWidget for StatCard (remains outside _TableBookingPageState)
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isPositive;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.isPositive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// External StatelessWidget for EmptyState (remains outside _TableBookingPageState)
class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final AnimationController? animation; // Made nullable as it's not always used

  const _EmptyState({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Added to prevent unbounded height issues
        children: [
          if (animation != null) // Conditionally show Lottie animation
            Lottie.asset(
              'assets/animations/empty_state.json',
              controller: animation,
              height: 150, // Reduced height slightly
            )
          else
            Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}