import 'package:flutter/material.dart';
import 'package:hungerz_store/Components/bottom_bar.dart';
import 'package:hungerz_store/Components/entry_field.dart';
import 'package:hungerz_store/Components/textfield.dart';
import 'dart:async';
import 'dart:io'; // Import for File
import 'dart:convert'; // Import for jsonEncode
import 'package:http/http.dart' as http; // Import http package
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:hungerz_store/models/menu_item_model.dart';
import 'package:hungerz_store/cubits/ingredient_cubit.dart';
import 'package:hungerz_store/cubits/ingredient_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/Themes/colors.dart';
import 'package:hungerz_store/services/menu_item_service.dart'; // Will be used later
import 'package:hungerz_store/Config/app_config.dart'; // For baseUrl
import 'package:http_parser/http_parser.dart'; // Import for MediaType

// Helper class to hold selected ingredient details including quantity controller
class SelectedIngredientDisplay {
  Ingredient ingredient;
  double quantity;
  TextEditingController quantityController;

  SelectedIngredientDisplay({required this.ingredient, this.quantity = 1.0})
      : quantityController = TextEditingController(text: quantity.toStringAsFixed(ingredient.unit?.toLowerCase() == "piece" || ingredient.unit?.toLowerCase() == "pièce" || ingredient.unit?.toLowerCase() == "unit" || ingredient.unit?.toLowerCase() == "unité" || ingredient.unit?.toLowerCase() == "tranche" ? 0 : 1));

  void dispose() {
    quantityController.dispose();
  }
}

// AddItem StatefulWidget now just provides a scaffold or basic structure if needed,
// or can be removed if all logic moves to Add widget. For simplicity,
// let's assume AddItem becomes simpler and Add widget handles AppBar and body.

class AddItem extends StatelessWidget { // Changed to StatelessWidget
  @override
  Widget build(BuildContext context) {
    // If Add widget will now include its own Scaffold and AppBar,
    // AddItem might just be a wrapper or directly return Add().
    // For this refactor, Add() will manage its own Scaffold.
    return Add();
  }
}

class Add extends StatefulWidget {
  @override
  _AddState createState() => _AddState();
}

class _AddState extends State<Add> {
  final _formKey = GlobalKey<FormState>(); // For form validation

  // Item Info Controllers
  late TextEditingController _itemNameController;
  late TextEditingController _itemCategoryController;
  late TextEditingController _itemPriceController;
  // No description field currently, can be added if needed

  // Stock Status (moved from _AddItemState)
  bool isAvailable = false; // Renamed from inStock for clarity with backend
  String stockStatus = "Out of Stock";


  // Dietary and Health Info Booleans
  bool isVegetarian = false;
  bool isVegan = false;
  bool isGlutenFree = false;
  bool isLactoseFree = false;
  bool isLowCarb = false;
  bool isLowFat = false;
  bool isLowSugar = false;
  bool isLowSodium = false;

  // Ingredients
  Set<String> _selectedIngredientIds = {};
  List<SelectedIngredientDisplay> _detailedSelectedIngredients = [];
  List<Ingredient> _allFetchedIngredients = [];

  // Image
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false; // For loading indicator on submission

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController();
    _itemCategoryController = TextEditingController();
    _itemPriceController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final ingredientCubit = context.read<IngredientCubit>();
        if (ingredientCubit.state is IngredientInitial) {
          ingredientCubit.fetchAllMasterIngredients();
        }
        ingredientCubit.stream.listen((state) {
          if (state is IngredientLoaded && mounted) {
            setState(() {
              _allFetchedIngredients = List<Ingredient>.from(state.ingredients);
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemCategoryController.dispose();
    _itemPriceController.dispose();
    for (var item in _detailedSelectedIngredients) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, 
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _handleSelectedIngredients(Set<String> newSelectedIdsFromDialog) {
    List<SelectedIngredientDisplay> newDetailedList = [];

    for (String id in newSelectedIdsFromDialog) {
      SelectedIngredientDisplay? existingItem;
      try {
        existingItem = _detailedSelectedIngredients.firstWhere(
            (item) => item.ingredient.id == id);
      } catch (e) {
        existingItem = null;
      }

      if (existingItem != null) {
        newDetailedList.add(existingItem);
      } else {
        Ingredient? ingredient;
        try {
            ingredient = _allFetchedIngredients.firstWhere(
            (ing) => ing.id == id);
        } catch (e) {
            ingredient = null;
        }

        if (ingredient != null) {
          newDetailedList.add(SelectedIngredientDisplay(ingredient: ingredient, quantity: _isCountableUnit(ingredient.unit) ? 0.0 : 1.0 ));
        }
      }
    }
    for (var oldDetailedItem in _detailedSelectedIngredients) {
      if (!newSelectedIdsFromDialog.contains(oldDetailedItem.ingredient.id)) {
        oldDetailedItem.dispose();
      }
    }
    setState(() {
      _detailedSelectedIngredients = newDetailedList;
      _selectedIngredientIds = newSelectedIdsFromDialog; 
    });
  }

  void _showSelectIngredientsDialog() async {
    final ingredientCubit = context.read<IngredientCubit>();
    if (ingredientCubit.state is IngredientInitial || _allFetchedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loading ingredients...'), duration: Duration(seconds: 1)),
      );
      await ingredientCubit.fetchAllMasterIngredients();
      if (ingredientCubit.state is! IngredientLoaded) {
         await Future.delayed(Duration(milliseconds: 1500)); 
      }
       if (ingredientCubit.state is IngredientLoaded) {
         _allFetchedIngredients = (ingredientCubit.state as IngredientLoaded).ingredients;
       } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load ingredients. Please try again.')),
          );
          return; 
       }
    }
     if (ingredientCubit.state is IngredientLoaded && _allFetchedIngredients.isEmpty && (ingredientCubit.state as IngredientLoaded).ingredients.isNotEmpty) {
        _allFetchedIngredients = (ingredientCubit.state as IngredientLoaded).ingredients;
     }

    final Set<String>? result = await showDialog<Set<String>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _IngredientSelectionDialogContent(
          allIngredients: _allFetchedIngredients, 
          initiallySelectedIds: Set<String>.from(_selectedIngredientIds),
        );
      },
    );

    if (result != null) {
      _handleSelectedIngredients(result);
    }
  }
  
  bool _isCountableUnit(String? unit) {
    if (unit == null) return false;
    String lowerUnit = unit.toLowerCase();
    return lowerUnit == "piece" || 
           lowerUnit == "pièce" || 
           lowerUnit == "unit" || 
           lowerUnit == "unité" ||
           lowerUnit == "tranche";
  }

  List<Widget> _buildSelectedIngredientRows() {
    List<Widget> ingredientWidgets = [];
    for (int i = 0; i < _detailedSelectedIngredients.length; i++) {
      final item = _detailedSelectedIngredients[i];
      bool isCountable = _isCountableUnit(item.ingredient.unit);

      ingredientWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.ingredient.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 40,
                    child: TextFormField(
                      controller: item.quantityController,
                      keyboardType: isCountable 
                          ? TextInputType.number 
                          : TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Qty",
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: kMainColor),
                          borderRadius: BorderRadius.circular(4)
                        ),
                      ),
                      onChanged: (value) {
                        if (isCountable) {
                          int? newQuantity = int.tryParse(value);
                          item.quantity = (newQuantity != null && newQuantity >= 0) ? newQuantity.toDouble() : 0.0;
                          item.quantityController.text = item.quantity.toInt().toString();
                           // Ensure cursor position is maintained if possible, or at least doesn't jump unnecessarily.
                          item.quantityController.selection = TextSelection.fromPosition(TextPosition(offset: item.quantityController.text.length));
                        } else {
                          double? newQuantity = double.tryParse(value);
                          item.quantity = (newQuantity != null && newQuantity >= 0) ? newQuantity : 0.0;
                          item.quantityController.text = item.quantity.toStringAsFixed(1);
                          item.quantityController.selection = TextSelection.fromPosition(TextPosition(offset: item.quantityController.text.length));
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(item.ingredient.unit ?? "", style: TextStyle(fontSize: 14)),
                  Spacer(),
                  if (isCountable)
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: kMainColor, size: 26),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      tooltip: "Decrease Quantity",
                      onPressed: () {
                        setState(() {
                          if (item.quantity > 0) {
                            item.quantity--;
                            item.quantityController.text = item.quantity.toInt().toString();
                          }
                        });
                      },
                    ),
                  if (isCountable) SizedBox(width: 4), 
                  if (isCountable)
                    IconButton(
                      icon: Icon(Icons.add_circle, color: kMainColor, size: 26), 
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      tooltip: "Increase Quantity",
                      onPressed: () {
                        setState(() {
                          item.quantity++;
                          item.quantityController.text = item.quantity.toInt().toString();
                        });
                      },
                    ),
                  if (isCountable) SizedBox(width: 8), 
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 26), 
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    tooltip: "Remove Ingredient",
                    onPressed: () {
                      String removedId = item.ingredient.id;
                      item.dispose();
                      setState(() {
                        _detailedSelectedIngredients.removeAt(i);
                        _selectedIngredientIds.remove(removedId);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        )
      );
      if (i < _detailedSelectedIngredients.length - 1) {
        ingredientWidgets.add(Divider(thickness: 0.5, height: 1, color: Colors.grey[300]));
      }
    }
    return ingredientWidgets;
  }

  Future<void> _submitAddItemForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please correct the errors in the form.')),
      );
      return;
    }

    if (_selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image for the item.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> ingredientsData = [];
    for (var selectedIng in _detailedSelectedIngredients) {
      double? quantity = double.tryParse(selectedIng.quantityController.text);
      if (quantity != null && quantity > 0) {
        ingredientsData.add({
          'id': selectedIng.ingredient.id,
          'quantity': quantity,
          'unit': selectedIng.ingredient.unit ?? '', // Ensure unit is always sent
        });
      }
    }
    
    if (ingredientsData.isEmpty && _detailedSelectedIngredients.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please ensure all selected ingredients have a valid quantity greater than 0.'))
        );
        setState(() { _isLoading = false; });
        return;
    }


    List<String> dietaryInfo = [];
    if (isVegetarian) dietaryInfo.add("Vegetarian");
    if (isVegan) dietaryInfo.add("Vegan");
    if (isGlutenFree) dietaryInfo.add("GlutenFree");
    if (isLactoseFree) dietaryInfo.add("LactoseFree");

    List<String> healthInfo = [];
    if (isLowCarb) healthInfo.add("Low_carb");
    if (isLowFat) healthInfo.add("Low_fat");
    if (isLowSugar) healthInfo.add("Low_sugar");
    if (isLowSodium) healthInfo.add("Low_sodium");


    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/menu-items/'), // Ensure this uses AppConfig.baseUrl
    );

    request.fields['name'] = _itemNameController.text;
    request.fields['category'] = _itemCategoryController.text; // Assuming a category text field
    request.fields['price'] = _itemPriceController.text;
    request.fields['isAvailable'] = isAvailable.toString();
    request.fields['dietaryInfo'] = jsonEncode(dietaryInfo);
    request.fields['healthInfo'] = jsonEncode(healthInfo);
    request.fields['ingredients'] = jsonEncode(ingredientsData);
    
    // Log the request fields for debugging
    print('Request fields: ${request.fields}');


    if (_selectedImageFile != null) {
      String filePath = _selectedImageFile!.path;
      String fileName = filePath.split('/').last;
      String fileExtension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

      MediaType? contentType;
      if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = MediaType('image', 'jpeg');
      } else if (fileExtension == 'png') {
        contentType = MediaType('image', 'png');
      }
      // Add more types if needed, e.g., gif, webp

      http.MultipartFile multipartFile = await http.MultipartFile.fromPath(
        'imageFile', // This 'imageFile' MUST match the backend Multer field name
        filePath,
        filename: fileName, // Explicitly set filename
        contentType: contentType, // Explicitly set contentType
      );
      print('MultipartFile - filename: ${multipartFile.filename}, contentType: ${multipartFile.contentType}, length: ${await multipartFile.length}');
      request.files.add(multipartFile);
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Log response status and body
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');


      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item added successfully!')),
        );
        // Optionally, clear the form or navigate away
        _itemNameController.clear();
        _itemCategoryController.clear();
        _itemPriceController.clear();
        setState(() {
          _selectedImageFile = null;
          _detailedSelectedIngredients.forEach((element) => element.dispose());
          _detailedSelectedIngredients.clear();
          _selectedIngredientIds.clear();
          isVegetarian = false;
          isVegan = false;
          isGlutenFree = false;
          isLactoseFree = false;
          isLowCarb = false;
          isLowFat = false;
          isLowSugar = false;
          isLowSodium = false;
          isAvailable = false;
          stockStatus = "Out of Stock";
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: $e')),
      );
       print('Error sending request: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold( // Add widget now has its own Scaffold
      appBar: AppBar(
        title: Text("Add Item", style: Theme.of(context).textTheme.bodyLarge),
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 30, color: Theme.of(context).secondaryHeaderColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
            child: Text(
                stockStatus,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                    .copyWith(color: isAvailable ? kMainColor : kHintColor),
              ),
            ),
          ),
          Switch(
            activeColor: kMainColor,
            activeTrackColor: Colors.grey[200],
            value: isAvailable,
            onChanged: (value) {
              setState(() {
                isAvailable = value;
                stockStatus = isAvailable ? "In Stock" : "Out of Stock";
              });
            },
          )
        ],
      ),
      body: Form( // Wrap ListView with Form
        key: _formKey,
        child: Stack(
          children: <Widget>[
            ListView(
              padding: EdgeInsets.only(bottom: 70), // Space for the BottomBar
              children: <Widget>[
                Divider(color: Theme.of(context).cardColor, thickness: 6.7),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text("ITEM IMAGE", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor)),
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 99.0,
                        width: 99.0,
                              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: Colors.grey.shade300, width: 1)),
                              child: _selectedImageFile != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(7.0), child: Image.file(_selectedImageFile!, fit: BoxFit.cover, height: 99.0, width: 99.0))
                                  : Icon(Icons.image_outlined, size: 40, color: kHintColor),
                      ),
                      SizedBox(width: 24.0),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(children: [Icon(Icons.camera_alt, color: kMainColor, size: 25.0), SizedBox(width: 14.3), Text("Upload Photo", style: Theme.of(context).textTheme.bodySmall!.copyWith(color: kMainColor))]),
                  ),
                ],
              ),
            ),
                    ],
                  ),
                ),
                Divider(color: Theme.of(context).cardColor, thickness: 8.0),
                Padding( // ITEM INFO Section
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text("ITEM INFO", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: EntryField(
                    controller: _itemNameController,
                    textCapitalization: TextCapitalization.words,
                    hint: "Enter item title",
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: EntryField(
                    controller: _itemCategoryController,
                    textCapitalization: TextCapitalization.words,
                    hint: "Select item category",
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: EntryField(
                    controller: _itemPriceController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    hint: "Enter Item Price",
                  ),
                ),
                Divider(color: Theme.of(context).cardColor, thickness: 8.0),
                // DIETARY & HEALTH INFORMATION Section (existing unchanged code)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text("DIETARY & HEALTH INFORMATION", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("DIETARY INFORMATION", style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      CheckboxListTile(title: Text("Vegetarian"), value: isVegetarian, onChanged: (bool? newValue) { setState(() { isVegetarian = newValue!; }); }, activeColor: kMainColor, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true),
                      CheckboxListTile(title: Text("Vegan"), value: isVegan, onChanged: (bool? newValue) { setState(() { isVegan = newValue!; }); }, activeColor: kMainColor, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true),
                      CheckboxListTile(title: Text("Gluten-Free"), value: isGlutenFree, onChanged: (bool? newValue) { setState(() { isGlutenFree = newValue!; }); }, activeColor: kMainColor, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true),
                      CheckboxListTile(title: Text("Lactose-Free"), value: isLactoseFree, onChanged: (bool? newValue) { setState(() { isLactoseFree = newValue!; }); }, activeColor: kMainColor, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true),
                      SizedBox(height: 10),
                      Text("HEALTH INFORMATION", style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      CheckboxListTile(title: Text("Low Carb"), value: isLowCarb, onChanged: (bool? newValue) { setState(() { isLowCarb = newValue!; }); }, activeColor: kMainColor, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true),
                      CheckboxListTile(title: Text("Low Fat"), value: isLowFat, onChanged: (bool? newValue) { setState(() { isLowFat = newValue!; }); }, activeColor: kMainColor, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true),
                      CheckboxListTile(title: Text("Low Sugar"), value: isLowSugar, onChanged: (bool? newValue) { setState(() { isLowSugar = newValue!; }); }, activeColor: kMainColor, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true),
                      CheckboxListTile(title: Text("Low Sodium"), value: isLowSodium, onChanged: (bool? newValue) { setState(() { isLowSodium = newValue!; }); }, activeColor: kMainColor, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero, dense: true),
                    ],
                  ),
                ),
                Divider(color: Theme.of(context).cardColor, thickness: 8.0),
                // INGREDIENTS Section (existing unchanged code)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text("INGREDIENTS", style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.67, color: kHintColor)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(icon: Icon(Icons.edit_note, size: 20), label: Text("Manage Ingredients"), onPressed: _showSelectIngredientsDialog, style: ElevatedButton.styleFrom(backgroundColor: kMainColor, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                      SizedBox(height: 16),
                      _detailedSelectedIngredients.isEmpty
                        ? Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text("No ingredients selected. Click 'Manage Ingredients' to add.", style: TextStyle(color: kHintColor, fontStyle: FontStyle.italic)))
                        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: _buildSelectedIngredientRows()),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomBar(
                text: _isLoading ? "Adding Item..." : "Add Item to Store",
                onTap: _isLoading 
                    ? () {} // Provide an empty function if disabled
                    : () { _submitAddItemForm(); }, 
              ),
            )
          ],
        ),
      ),
    );
  }
}

// _IngredientSelectionDialogContent class remains unchanged
// ... (ensure _IngredientSelectionDialogContent is here)
class _IngredientSelectionDialogContent extends StatefulWidget {
  final List<Ingredient> allIngredients;
  final Set<String> initiallySelectedIds;

  const _IngredientSelectionDialogContent({
    Key? key,
    required this.allIngredients,
    required this.initiallySelectedIds,
  }) : super(key: key);

  @override
  _IngredientSelectionDialogContentState createState() =>
      _IngredientSelectionDialogContentState();
}

class _IngredientSelectionDialogContentState
    extends State<_IngredientSelectionDialogContent> {
  late Set<String> _tempSelectedIds;
  String _searchQuery = '';
  List<Ingredient> _filteredIngredients = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = Set<String>.from(widget.initiallySelectedIds);
    _filterIngredients(); 
  }

  void _filterIngredients() {
    if (_searchQuery.isEmpty) {
      _filteredIngredients = List<Ingredient>.from(widget.allIngredients);
    } else {
      _filteredIngredients = widget.allIngredients
          .where((ingredient) =>
              ingredient.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Ingredient"),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              onChanged: (value) {
                            setState(() {
                  _searchQuery = value;
                  _filterIngredients();
                            });
                          },
              decoration: InputDecoration(
                labelText: 'Search Ingredients',
                hintText: 'Type to search...',
                prefixIcon: Icon(Icons.search, color: kMainColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: kMainColor),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded( 
              child: _filteredIngredients.isEmpty && widget.allIngredients.isNotEmpty 
                  ? Center(child: Text(_searchQuery.isNotEmpty ? "No ingredients match your search." : "No ingredients available."))
                  : _filteredIngredients.isEmpty && widget.allIngredients.isEmpty
                    ? Center(child: Text("No ingredients available to select from.")) 
                    : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _filteredIngredients[index];
                        final bool isSelected = _tempSelectedIds.contains(ingredient.id);
                        return CheckboxListTile(
                          title: Text(
                            '${ingredient.name}${ingredient.unit != null ? " (${ingredient.unit})" : ""}',
                            style: TextStyle(fontSize: 14), 
                          ),
                          value: isSelected,
                          onChanged: (bool? newValue) {
                            setState(() {
                              if (newValue == true) {
                                _tempSelectedIds.add(ingredient.id);
                              } else {
                                _tempSelectedIds.remove(ingredient.id);
                              }
                            });
                          },
                          activeColor: kMainColor,
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true, 
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text("Cancel", style: TextStyle(color: kMainColor)),
          onPressed: () {
            Navigator.of(context).pop(); 
          },
        ),
        ElevatedButton(
          child: Text("Done"),
          style: ElevatedButton.styleFrom(backgroundColor: kMainColor),
          onPressed: () {
            Navigator.of(context).pop(_tempSelectedIds); 
          },
        ),
      ],
    );
  }
}
