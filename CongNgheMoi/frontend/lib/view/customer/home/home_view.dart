import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/round_textfield.dart';

import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/category_cell.dart';
import '../../../common_widget/popular_resutaurant_row.dart';
import '../../../common_widget/recent_item_row.dart';
import '../../../common_widget/view_all_title_row.dart';
import '../menu/all_dishes_view.dart';
import '../menu/item_details_view.dart';
import '../menu/menu_items_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController txtSearch = TextEditingController();
  late Future<_HomeData> homeFuture;
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    txtSearch.addListener(_onSearchChanged);
    homeFuture = _loadHomeData();
  }

  @override
  void dispose() {
    txtSearch.removeListener(_onSearchChanged);
    txtSearch.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = txtSearch.text;
    if (value == _searchQuery) {
      return;
    }
    setState(() {
      _searchQuery = value;
    });
  }

  Future<_HomeData> _loadHomeData() async {
    try {
      final results = await Future.wait<dynamic>([
        ServiceCall.fetchGet(SVKey.svCanteenCategories, isToken: true),
        ServiceCall.fetchGet(SVKey.svCanteens, isToken: true),
        ServiceCall.fetchGet(SVKey.svCanteenDishes, isToken: true),
      ]);

      final categoriesData = results[0] is Map ? results[0]['data'] : results[0];
      final categories = (categoriesData as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map)).toList();

      final canteensData = results[1] is Map ? results[1]['data'] : results[1];
      final canteens = (canteensData as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map)).toList();

      final dishesData = results[2] is Map ? results[2]['data'] : results[2];
      final dishes = (dishesData as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map)).toList();

      return _HomeData(
        categories: categories,
        canteens: canteens,
        dishes: dishes,
      );
    } catch (e) {
      print("HomeData fetch error: $e");
      return _HomeData(categories: [], canteens: [], dishes: []);
    }
  }

  Map<String, dynamic> _categoryLogo(String value) {
    final normalized = value.toLowerCase();

    if (normalized.contains('an nhanh') || normalized.contains('fast') || normalized.contains('snack')) {
      return {
        "icon": Icons.fastfood_rounded,
        "bgColor": const Color(0xFFFFE1D6),
      };
    }

    if (normalized.contains('do uong') || normalized.contains('đồ uống') || normalized.contains('drink') || normalized.contains('beverage')) {
      return {
        "icon": Icons.local_drink_rounded,
        "bgColor": const Color(0xFFDDF3FF),
      };
    }

    if (normalized.contains('tra sua') || normalized.contains('trà sữa') || normalized.contains('tea') || normalized.contains('coffee')) {
      return {
        "icon": Icons.emoji_food_beverage_rounded,
        "bgColor": const Color(0xFFEDE3FF),
      };
    }

    if (normalized.contains('trang mieng') || normalized.contains('tráng miệng') || normalized.contains('dessert')) {
      return {
        "icon": Icons.icecream_rounded,
        "bgColor": const Color(0xFFFFE7F1),
      };
    }

    if (normalized.contains('com') || normalized.contains('cơm') || normalized.contains('meal')) {
      return {
        "icon": Icons.rice_bowl_rounded,
        "bgColor": const Color(0xFFFFF0CF),
      };
    }

    if (normalized.contains('pho') || normalized.contains('phở') || normalized.contains('bun') || normalized.contains('bún') || normalized.contains('mi') || normalized.contains('mì')) {
      return {
        "icon": Icons.ramen_dining_rounded,
        "bgColor": const Color(0xFFFFF4DA),
      };
    }

    if (normalized.contains('chay') || normalized.contains('vegetarian') || normalized.contains('vegan')) {
      return {
        "icon": Icons.eco_rounded,
        "bgColor": const Color(0xFFE6F7DF),
      };
    }

    if (normalized.contains('hai san') || normalized.contains('hải sản') || normalized.contains('seafood')) {
      return {
        "icon": Icons.set_meal_rounded,
        "bgColor": const Color(0xFFDFF4F8),
      };
    }

    return {
      "icon": Icons.restaurant_menu_rounded,
      "bgColor": const Color(0xFFFFE8D9),
    };
  }

  List<Map<String, dynamic>> _buildCategoryCards(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) {
      return [];
    }

    return categories.take(8).map((item) {
      final categoryName = item["categoryName"]?.toString() ?? 'Category';
      final logo = _categoryLogo(categoryName);
      return {
        "icon": logo["icon"],
        "bgColor": logo["bgColor"],
        "name": categoryName,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildRestaurantCards(List<Map<String, dynamic>> canteens) {
    return canteens.take(10).map((item) {
      return {
        "imageUrl": item["logoUrl"]?.toString() ?? item["bannerUrl"]?.toString(),
        "name": item["name"]?.toString() ?? '',
        "rate": item["totalDishes"]?.toString() ?? '0',
        "rating": "Dishes",
        "type": item["location"]?.toString() ?? '',
        "food_type": item["openHours"]?.toString() ?? '',
        "canteenId": item["id"],
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildDishCards(List<Map<String, dynamic>> dishes) {
    return dishes.take(20).map((item) {
      final price = (item["price"] as num?)?.toDouble();
      final rate = (item["rate"] as num?)?.toDouble() ?? 0.0;
      final luotDanhGia = (item["rating"] as num?)?.toInt() ?? 0;
      final sold = (item["soLuongDaBan"] as num?)?.toInt() ?? 0;
      return {
        "imageUrl":     item["imageUrl"]?.toString(),
        "name":         item["name"]?.toString() ?? '',
        "price":        price,
        "soLuongDaBan": sold,
        // rate & rating dùng cho sao
        "rate":         rate > 0 ? rate.toStringAsFixed(1) : '',
        "rating":       luotDanhGia > 0 ? '$luotDanhGia' : '',
        "type":         item["categoryName"]?.toString() ?? '',
        "food_type":    item["canteenName"]?.toString() ?? '',
        "dishId":       item["id"],
        // giữ full object để ItemDetailsView dùng
        "id":           item["id"],
        "description":  item["description"]?.toString() ?? '',
        "canteenName":  item["canteenName"]?.toString() ?? '',
        "categoryName": item["categoryName"]?.toString() ?? '',
      };
    }).toList();
  }

  String _normalizeText(String value) {
    final lower = value.toLowerCase().trim();
    return lower
        .replaceAll('đ', 'd')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ắ', 'a')
        .replaceAll('ằ', 'a')
        .replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a')
        .replaceAll('ặ', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ấ', 'a')
        .replaceAll('ầ', 'a')
        .replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ế', 'e')
        .replaceAll('ề', 'e')
        .replaceAll('ể', 'e')
        .replaceAll('ễ', 'e')
        .replaceAll('ệ', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ố', 'o')
        .replaceAll('ồ', 'o')
        .replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o')
        .replaceAll('ộ', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ớ', 'o')
        .replaceAll('ờ', 'o')
        .replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o')
        .replaceAll('ợ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ứ', 'u')
        .replaceAll('ừ', 'u')
        .replaceAll('ử', 'u')
        .replaceAll('ữ', 'u')
        .replaceAll('ự', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y');
  }

  List<Map<String, dynamic>> _filterBySelectedCategory(
    List<Map<String, dynamic>> dishes,
  ) {
    final selected = _selectedCategory;
    if (selected == null || selected.isEmpty) {
      return dishes;
    }

    final normalizedSelected = _normalizeText(selected);
    return dishes.where((dish) {
      final category = dish['type']?.toString() ?? '';
      final normalizedObjCategory = _normalizeText(category);
      return normalizedObjCategory == normalizedSelected || normalizedObjCategory.contains(normalizedSelected) || normalizedSelected.contains(normalizedObjCategory);
    }).toList();
  }

  List<Map<String, dynamic>> _filterDishesBySearch(
    List<Map<String, dynamic>> dishes,
    bool onlyByProductName,
  ) {
    final query = _normalizeText(_searchQuery);
    if (query.isEmpty) {
      return dishes;
    }

    return dishes.where((dish) {
      final name = _normalizeText(dish['name']?.toString() ?? '');
      if (onlyByProductName) {
        return name.contains(query);
      }
      final canteen = _normalizeText(dish['food_type']?.toString() ?? '');
      final category = _normalizeText(dish['type']?.toString() ?? '');
      return name.contains(query) || canteen.contains(query) || category.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _filterRestaurantsBySearch(
    List<Map<String, dynamic>> restaurants,
  ) {
    final query = _normalizeText(_searchQuery);
    if (query.isEmpty) {
      return restaurants;
    }

    return restaurants.where((restaurant) {
      final name = _normalizeText(restaurant['name']?.toString() ?? '');
      final location = _normalizeText(restaurant['type']?.toString() ?? '');
      final openHours = _normalizeText(restaurant['food_type']?.toString() ?? '');
      return name.contains(query) || location.contains(query) || openHours.contains(query);
    }).toList();
  }

  List<String> _buildSearchSuggestions(
    List<Map<String, dynamic>> dishes,
    List<Map<String, dynamic>> restaurants,
    bool includeRestaurants,
  ) {
    final query = _normalizeText(_searchQuery);
    if (query.isEmpty) {
      return [];
    }

    final dishNames = dishes
        .map((e) => e['name']?.toString() ?? '')
        .where((e) => e.isNotEmpty);
    final restaurantNames = restaurants
        .map((e) => e['name']?.toString() ?? '')
        .where((e) => e.isNotEmpty);

    final allNames = <String>{
      ...dishNames,
      if (includeRestaurants) ...restaurantNames,
    };

    final suggestions = allNames
        .where((name) => _normalizeText(name).startsWith(query))
        .toList()
      ..sort();
    return suggestions.take(8).toList();
  }

  void _openDishDetail(Map<String, dynamic> dish) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailsView(dishObj: dish),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: homeFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final categories = _buildCategoryCards(data?.categories ?? []);
        final restaurants = _buildRestaurantCards(data?.canteens ?? []);
        final allDishes = _buildDishCards(data?.dishes ?? []);
        final categoryDishes = _filterBySelectedCategory(allDishes);
        final isCategorySelected =
            _selectedCategory != null && _selectedCategory!.isNotEmpty;
        final dishes = _filterDishesBySearch(
          categoryDishes,
          isCategorySelected,
        );
        final restaurantResults =
            isCategorySelected ? <Map<String, dynamic>>[] : _filterRestaurantsBySearch(restaurants);
        final searchSuggestions = _buildSearchSuggestions(
          categoryDishes,
          restaurants,
          !isCategorySelected,
        );

        return Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 46),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Good morning ${ServiceCall.userPayload[KKey.name] ?? ""}!",
                            style: TextStyle(
                              color: TColor.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        RoundTextfield(
                          hintText: isCategorySelected
                              ? "Tim mon an trong danh muc"
                              : "Tìm món ăn hoặc căn tin",
                          controller: txtSearch,
                          left: Container(
                            alignment: Alignment.center,
                            width: 30,
                            child: Image.asset(
                              "assets/img/search.png",
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                        if (_searchQuery.trim().isNotEmpty && searchSuggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: searchSuggestions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: TColor.placeholder.withValues(alpha: 0.25),
                              ),
                              itemBuilder: (context, index) {
                                final suggestion = searchSuggestions[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    suggestion,
                                    style: TextStyle(
                                      color: TColor.primaryText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onTap: () {
                                    txtSearch.text = suggestion;
                                    txtSearch.selection = TextSelection.fromPosition(
                                      TextPosition(offset: txtSearch.text.length),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: categories.length,
                      itemBuilder: ((context, index) {
                        final cObj = categories[index];
                        return CategoryCell(
                          cObj: cObj,
                          isSelected: _normalizeText(
                                cObj['name']?.toString() ?? '',
                              ) ==
                              _normalizeText(_selectedCategory ?? ''),
                          onTap: () {
                            final category = cObj['name']?.toString() ?? '';
                            setState(() {
                              final isCurrent =
                                  _normalizeText(_selectedCategory ?? '') ==
                                      _normalizeText(category);
                              _selectedCategory = isCurrent ? null : category;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                  if (!isCategorySelected) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ViewAllTitleRow(
                        title: "Popular Restaurants",
                        onView: () {},
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: CircularProgressIndicator(),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: restaurantResults.length,
                        itemBuilder: ((context, index) {
                          final pObj = restaurantResults[index];
                          return PopularRestaurantRow(
                            pObj: pObj,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenuItemsView(mObj: pObj),
                                ),
                              );
                            },
                          );
                        }),
                      ),

                  ],
                  if (!isCategorySelected && _searchQuery.trim().isNotEmpty && restaurantResults.isEmpty && dishes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Text(
                        "Khong tim thay mon an hoac can tin phu hop",
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ViewAllTitleRow(
                      title: isCategorySelected ? "Mon an" : "Recent Items",
                      onView: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllDishesView(
                              initialCategory:
                                  isCategorySelected ? _selectedCategory : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (dishes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        isCategorySelected
                            ? "Khong tim thay mon trong danh muc da chon"
                            : "Khong co mon phu hop",
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: dishes.length,
                      itemBuilder: ((context, index) {
                        final rObj = dishes[index];
                        return RecentItemRow(
                          rObj: rObj,
                          onTap: () => _openDishDetail(rObj),
                        );
                      }),
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeData {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> canteens;
  final List<Map<String, dynamic>> dishes;

  _HomeData({
    required this.categories,
    required this.canteens,
    required this.dishes,
  });
}
