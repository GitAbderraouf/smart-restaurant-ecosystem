import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/Themes/colors.dart';
import 'package:hungerz_store/cubits/menu_item_cubit.dart';
import 'package:hungerz_store/models/menu_item_model.dart';
import 'package:hungerz_store/services/menu_item_service.dart';
import 'package:hungerz_store/Pages/edititem.dart';
import 'package:hungerz_store/Routes/routes.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ItemsPageProvider extends StatelessWidget {
  const ItemsPageProvider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MenuItemCubit(context.read<MenuItemService>()),
      child: ItemsPage(),
    );
  }
}

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> with TickerProviderStateMixin {
  TabController? _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotateAnimation;
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize FAB animation controller
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _fabRotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeInOutBack,
      ),
    );
    
    // Start FAB animation after a short delay
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) _fabAnimationController.forward();
    });
    
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<MenuItemCubit>();
      if (cubit.state is MenuItemInitial && cubit.categoryApiKeys.isNotEmpty) {
        cubit.fetchMenuItemsForCategory(cubit.categoryApiKeys.first);
      }
    });
  }

  void _initTabController(List<String> categories, String selectedCategoryKey) {
    final cubit = context.read<MenuItemCubit>();
    int initialIndex = cubit.categoryApiKeys.indexOf(selectedCategoryKey);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(
      length: categories.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        final currentIndexInCubit = cubit.categoryApiKeys.indexOf(cubit.state is MenuItemLoaded 
            ? (cubit.state as MenuItemLoaded).selectedCategory 
            : cubit.state is MenuItemLoading 
              ? (cubit.state as MenuItemLoading).selectedCategory 
              : cubit.categoryApiKeys.first);
              
        if (_tabController!.index != currentIndexInCubit) {
          final selectedApiKey = cubit.categoryApiKeys[_tabController!.index];
          cubit.fetchMenuItemsForCategory(selectedApiKey);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuItemCubit = context.watch<MenuItemCubit>();

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: kCardBackgroundColor,
      appBar: _buildAppBar(menuItemCubit),
      body: BlocBuilder<MenuItemCubit, MenuItemState>(
        builder: (context, state) {
          if (state is MenuItemInitial || (state is MenuItemLoading && state.menuItemsIfAny.isEmpty)) {
            return _buildLoadingAnimation();
          }
          if (state is MenuItemError) {
            return _buildErrorView(state);
          }
          if (state is MenuItemLoaded || (state is MenuItemLoading && state.menuItemsIfAny.isNotEmpty)) {
            final items = state is MenuItemLoaded ? state.menuItems : (state as MenuItemLoading).menuItemsIfAny;
            if (items.isEmpty && !(state is MenuItemLoading)) {
              return _buildEmptyItemsView();
            }
            if (items.isEmpty && state is MenuItemLoading) {
              return _buildLoadingAnimation();
            }
            return _buildItemsList(items);
          }
          return Center(
                    child: Text(
              "Select a category to see items",
              style: TextStyle(
                fontSize: 16,
                color: kLightTextColor,
                fontWeight: FontWeight.w500
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildAnimatedFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(MenuItemCubit menuItemCubit) {
    return PreferredSize(
      preferredSize: Size.fromHeight(120.0),
      child: Builder(
        builder: (context) {
          List<String> displayCategories = menuItemCubit.categories;
          String? currentSelectedApiKey;
          final currentState = menuItemCubit.state;

          if (currentState is MenuItemLoading) {
            currentSelectedApiKey = currentState.selectedCategory;
          } else if (currentState is MenuItemLoaded) {
            currentSelectedApiKey = currentState.selectedCategory;
          } else if (currentState is MenuItemError) {
            currentSelectedApiKey = currentState.selectedCategory ?? 
                (menuItemCubit.categoryApiKeys.isNotEmpty ? menuItemCubit.categoryApiKeys.first : null);
          } else if (currentState is MenuItemInitial && menuItemCubit.categoryApiKeys.isNotEmpty) {
            currentSelectedApiKey = menuItemCubit.categoryApiKeys.first;
          }
          
          if (_tabController == null && displayCategories.isNotEmpty && currentSelectedApiKey != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && (_tabController == null || _tabController!.length != displayCategories.length)) {
                _initTabController(displayCategories, currentSelectedApiKey!);
                setState(() {});
              }
            });
          }
          
          if (_tabController != null && currentSelectedApiKey != null) {
            int targetIndex = menuItemCubit.categoryApiKeys.indexOf(currentSelectedApiKey);
            if (targetIndex != -1 && _tabController!.index != targetIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _tabController!.index != targetIndex) {
                  _tabController?.animateTo(targetIndex);
                }
              });
            }
          }
          
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                            children: [
                  AppBar(
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    title: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Text(
                        "Products",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          letterSpacing: 0.5,
                          color: kMainColor,
                        ),
                      )
                      .animate()
                      .scale(
                        begin: Offset(0.8, 0.8),
                        end: Offset(1.0, 1.0),
                      )
                      .fadeIn(duration: 300.ms),
                    ),
                  ),
                  if (_tabController == null || displayCategories.isEmpty)
                                Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          color: kMainColor,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 48,
                      margin: EdgeInsets.symmetric(vertical: 2),
                      child: TabBar(
                        controller: _tabController,
                        tabs: displayCategories.map((cat) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Tab(
                              child: Text(
                                cat.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        isScrollable: true,
                        labelColor: kMainColor,
                        unselectedLabelColor: kLightTextColor,
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorPadding: EdgeInsets.symmetric(vertical: 8),
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: kMainColor.withOpacity(0.12),
                          border: Border.all(color: kMainColor, width: 1.5),
                        ),
                      ),
                    ),
                                    ],
                                  ),
                                ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1500),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kMainColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                            ),
                          ],
                        ),
              child: CircularProgressIndicator(
                color: kMainColor,
                strokeWidth: 4,
              ),
            )
            .animate()
            .scale(
              begin: Offset(0.8, 0.8),
              end: Offset(1.0, 1.0),
            )
            .fadeIn(duration: 300.ms),
          ),
          SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1500),
            tween: Tween(begin: 0, end: 1),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              );
            },
            child: Text(
              "Loading products...",
                                style: TextStyle(
                fontSize: 16,
                color: kMainColor,
                fontWeight: FontWeight.w500,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms),
                              )
                            ],
                          ),
    );
  }

  Widget _buildErrorView(MenuItemError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 800),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[400],
                      size: 60,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kMainTextColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kLightTextColor,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final cubit = context.read<MenuItemCubit>();
                        String categoryToFetch = state.selectedCategory ?? 
                            (cubit.categoryApiKeys.isNotEmpty ? cubit.categoryApiKeys.first : 'burgers');
                        cubit.fetchMenuItemsForCategory(categoryToFetch);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Try Again',
                                style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .scale(
                begin: Offset(0.0, 0.0),
                end: Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),
          )],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsView() {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 800),
        tween: Tween(begin: 0, end: 1),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: value,
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kMainColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                                ),
                              ],
                            ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 50,
                color: kMainColor,
              ),
            )
            .animate()
            .scale(
              begin: Offset(0.0, 0.0),
              end: Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 400.ms),
            SizedBox(height: 24),
            Text(
              "No items in this category",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kMainTextColor,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms),
            SizedBox(height: 8),
                              Text(
              "Tap + to add new products",
                                style: TextStyle(
                fontSize: 15,
                color: kLightTextColor,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms),
                            ],
                          ),
                        ),
    );
  }

  Widget _buildItemsList(List<MenuItem> items) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.only(top: 12, bottom: 80),
        physics: BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildMenuItemCard(context: context, item: items[index], index: index),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard({required BuildContext context, required MenuItem item, required int index}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Hero(
        tag: 'menu_item_${item.id}',
        child: Material(
          elevation: 2,
          shadowColor: Colors.black12,
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => EditItem(itemId: item.id),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildFoodImage(item),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                            _buildFoodTypeIndicator(item),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                              Text(
                          'DA ${item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: kMainColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        _buildAvailabilityStatus(context, item),
                      ],
                    ),
                  ),
                  _buildAvailabilitySwitch(item),
                                    ],
                                  ),
                                ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodImage(MenuItem item) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 3),
                            ),
                          ],
                        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: item.image != null && item.image!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: item.image!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kMainColor,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'images/2.png',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                'images/2.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildFoodTypeIndicator(MenuItem item) {
    final Color activeColor = item.isAvailable ? Colors.green.shade700 : Colors.red.shade700;
    final Color borderColor = item.isAvailable ? Colors.green.shade700 : Colors.red.shade700;

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
                ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityStatus(BuildContext context, MenuItem item) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: item.isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        item.isAvailable ? 'In Stock' : 'Out of Stock',
        style: TextStyle(
          color: item.isAvailable ? Colors.green[700] : Colors.red[700],
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAvailabilitySwitch(MenuItem item) {
    return Transform.scale(
      scale: 0.8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: item.isAvailable ? kMainColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        ),
        child: Switch(
          value: item.isAvailable,
          onChanged: (value) {
            // Implement update functionality when ready
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value ? 'Item set to available' : 'Item set to unavailable'),
          backgroundColor: kMainColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.all(10),
                duration: Duration(seconds: 1),
              ),
            );
          },
          activeColor: kMainColor,
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          trackOutlineColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.grey.shade200;
            }
            if (states.contains(MaterialState.selected)) {
              return kMainColor.withOpacity(0.5);
            }
            return Colors.grey.shade400;
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Transform.rotate(
            angle: _fabRotateAnimation.value * 2 * 3.14159,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, PageRoutes.addItem);
              },
              label: Text(
                "Add Item",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: Icon(Icons.add, color: Colors.white),
              backgroundColor: kMainColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        );
      },
    );
  }
}

extension MenuItemLoadingStateExtension on MenuItemLoading {
  List<MenuItem> get menuItemsIfAny => []; 
}