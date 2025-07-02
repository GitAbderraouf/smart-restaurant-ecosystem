import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/Components/bottom_bar.dart';
import 'package:hungerz_store/Components/entry_field.dart';
import 'package:hungerz_store/Themes/colors.dart';
import 'package:hungerz_store/models/menu_item_model.dart';
import 'package:hungerz_store/services/menu_item_service.dart';

class EditItem extends StatefulWidget {
  final String itemId;

  const EditItem({Key? key, required this.itemId}) : super(key: key);

  @override
  _EditItemState createState() => _EditItemState();
}

class _EditItemState extends State<EditItem> {
  MenuItem? _detailedMenuItem;
  bool _isLoading = true;
  String _error = '';

  late bool _inStock;
  late String _stockStatusText;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final menuItemService = context.read<MenuItemService>();
      final item = await menuItemService.getMenuItemDetails(widget.itemId);
      final ingredients = await menuItemService.getIngredientsForMenuItem(widget.itemId);

      if (mounted) {
        setState(() {
          _detailedMenuItem = item.copyWith(ingredients: ingredients);
          _inStock = item.isAvailable;
          _stockStatusText = item.isAvailable ? "In Stock" : "Out of Stock";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load item details: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Item")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Item")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error, style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
          ),
        ),
      );
    }
    
    if (_detailedMenuItem == null) {
        return Scaffold(
            appBar: AppBar(title: const Text("Edit Item")),
            body: const Center(child: Text("Item details not found.")),
        );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 30,
            color: Theme.of(context).secondaryHeaderColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(_detailedMenuItem!.name,
            style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          Center(
            child: Text(
              _stockStatusText,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: _inStock ? kMainColor : kHintColor),
            ),
          ),
          Switch(
            activeColor: kMainColor,
            activeTrackColor: Colors.grey[200],
            value: _inStock,
            onChanged: (value) {
              setState(() {
                _inStock = value;
                _detailedMenuItem = _detailedMenuItem!.copyWith(isAvailable: value);
                _stockStatusText = _inStock ? "In Stock" : "Out of Stock";
              });
            },
          )
        ],
      ),
      body: Add(menuItem: _detailedMenuItem!),
    );
  }
}

class Add extends StatefulWidget {
  final MenuItem menuItem;

  const Add({Key? key, required this.menuItem}) : super(key: key);

  @override
  _AddState createState() => _AddState();
}

class _AddState extends State<Add> {
  final List<String> _allDietaryTags = [
    'vegetarian', 'vegan', 'glutenFree', 'lactoseFree'
  ];
  final List<String> _allHealthTags = [
    'low_carb', 'low_fat', 'low_sugar', 'low_sodium'
  ];

  late Map<String, bool> _selectedDietaryTags;
  late Map<String, bool> _selectedHealthTags;
  List<Ingredient> _currentIngredients = [];

  late TextEditingController _itemNameController;
  late TextEditingController _itemPriceController;
  late TextEditingController _itemCategoryController;
  late TextEditingController _itemDescriptionController;

  @override
  void initState() {
    super.initState();

    _itemNameController = TextEditingController(text: widget.menuItem.name);
    _itemPriceController = TextEditingController(text: widget.menuItem.price.toStringAsFixed(2));
    _itemCategoryController = TextEditingController(text: widget.menuItem.category);
    _itemDescriptionController = TextEditingController(text: widget.menuItem.description ?? '');

    _selectedDietaryTags = {
      for (var tag in _allDietaryTags) tag: widget.menuItem.dietaryInfo.contains(tag)
    };
    _selectedHealthTags = {
      for (var tag in _allHealthTags) tag: widget.menuItem.healthInfo.contains(tag)
    };
    _currentIngredients = List<Ingredient>.from(widget.menuItem.ingredients);
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _itemCategoryController.dispose();
    _itemDescriptionController.dispose();
    super.dispose();
  }

  List<Widget> _buildTagCheckboxes(String groupTitle, List<String> allTags, Map<String, bool> selectedTags) {
    List<Widget> checkboxes = [];
    checkboxes.add(Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
      child: Text(groupTitle.toUpperCase(), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: kHintColor, fontWeight: FontWeight.bold)),
    ));
    checkboxes.addAll(allTags.map((tag) {
      return CheckboxListTile(
        title: Text(tag[0].toUpperCase() + tag.substring(1)),
        value: selectedTags[tag],
        onChanged: (bool? value) {
          setState(() {
            selectedTags[tag] = value!;
          });
        },
        activeColor: kMainColor,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      );
    }).toList());
    return checkboxes;
  }
  
  void _addIngredientField() {
    setState(() {
      _currentIngredients.add(Ingredient(id: DateTime.now().millisecondsSinceEpoch.toString(), name: '', quantity: 0.0, unit: ''));
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _currentIngredients.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ListView(
          padding: EdgeInsets.only(bottom: 70, left: 16, right: 16),
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("ITEM IMAGE", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor)),
                  SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 99.0, width: 99.0,
                        child: widget.menuItem.image != null && widget.menuItem.image!.isNotEmpty
                            ? Image.network(widget.menuItem.image!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Image.asset('images/2.png'))
                            : Image.asset('images/2.png'),
                      ),
                      SizedBox(width: 24.0),
                      Icon(Icons.camera_alt, color: kMainColor, size: 25.0),
                      SizedBox(width: 14.3),
                      Text("Upload Photo", style: Theme.of(context).textTheme.bodySmall!.copyWith(color: kMainColor)),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Theme.of(context).cardColor, thickness: 8.0, height: 8),

                Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text("ITEM INFO", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor))),
            EntryField(controller: _itemNameController, textCapitalization: TextCapitalization.words, hint: "Enter item title"),
            EntryField(controller: _itemCategoryController, suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.black), textCapitalization: TextCapitalization.words, hint: "Select item category"),
            EntryField(controller: _itemPriceController, textCapitalization: TextCapitalization.words, hint: "Item Price (Main)", keyboardType: TextInputType.numberWithOptions(decimal: true)),
            Divider(color: Theme.of(context).cardColor, thickness: 8.0, height: 24),

            Text("FOOD TYPE", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor)),
            ..._buildTagCheckboxes("Dietary Information", _allDietaryTags, _selectedDietaryTags),
            SizedBox(height: 10),
            ..._buildTagCheckboxes("Health Information", _allHealthTags, _selectedHealthTags),
            Divider(color: Theme.of(context).cardColor, thickness: 8.0, height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("INGREDIENTS", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor)),
                TextButton.icon(
                  icon: Icon(Icons.add_circle_outline, color: kMainColor, size: 18),
                  label: Text("ADD MORE", style: TextStyle(fontWeight: FontWeight.bold, color: kMainColor, fontSize: 10, letterSpacing: 0.5)),
                  onPressed: _addIngredientField,
                ),
              ],
            ),
            if (_currentIngredients.isEmpty)
                Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("No ingredients for this item. Click 'ADD MORE' to create one.", style: Theme.of(context).textTheme.bodySmall),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _currentIngredients.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_currentIngredients[index].name.isNotEmpty ? _currentIngredients[index].name : "Ingredient ${index + 1}", 
                                 style: Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 4),
                        Row(
                          children: [
                                Expanded(child: EntryField(hint: "Qty", initialValue: _currentIngredients[index].quantity.toString(), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                                SizedBox(width: 8),
                                Expanded(child: EntryField(hint: "Unit", initialValue: _currentIngredients[index].unit)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade700), onPressed: () => _removeIngredientField(index)),
                    ],
                  ),
                );
              },
            ),
            Divider(color: Theme.of(context).cardColor, thickness: 8.0, height: 24),

                Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text("ITEM DESCRIPTION", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor))),
            EntryField(controller: _itemDescriptionController, maxLength: 250, maxLines: 5, hint: "Add Description"),
            Divider(color: Theme.of(context).cardColor, thickness: 8.0, height: 24),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomBar(
            text: "Update info",
            onTap: () {
              Navigator.pop(context);
            },
          ),
        )
      ],
    );
  }
}
