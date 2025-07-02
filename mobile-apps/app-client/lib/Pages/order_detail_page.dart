// lib/Pages/order_details_page.dart (Nouveau fichier)

// lib/Pages/order_details_page.dart

// lib/Pages/order_details_page.dart

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hungerz/Locale/locales.dart'; // Supprimé
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/models/order_details_model.dart';
 // Assurez-vous que ce modèle est à jour (avec currentUserRating)
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hungerz/cubits/rating_cubit/rating_cubit.dart'; // Assurez-vous que le chemin est correct
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderDetailsModel order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final Map<String, double> _itemRatings = {}; 
  final Map<String, double> _initialItemRatings = {}; 

  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  static const LatLng _defaultCenter = LatLng(36.7753623, 3.0601882); // Alger centre

  @override
  void initState() {
    super.initState();
    widget.order.items.forEach((item) {
      final existingRating = item.currentUserRating ?? 0.0;
      _itemRatings[item.menuItemId] = existingRating;
      _initialItemRatings[item.menuItemId] = existingRating; 
    });

    if (widget.order.deliveryAddress != null &&
        widget.order.deliveryAddress!.latitude != null &&
        widget.order.deliveryAddress!.longitude != null) {
           _setDeliveryMarker(LatLng(
               widget.order.deliveryAddress!.latitude!,
               widget.order.deliveryAddress!.longitude!));
    }
  }

  void _setDeliveryMarker(LatLng position) {
    if (!mounted) return;
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('deliveryAddress'),
          position: position,
          infoWindow: InfoWindow(
            title: "Adresse de livraison", // Texte direct
            snippet: widget.order.deliveryAddress?.address ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void _updateRating(String menuItemId, double rating) {
    setState(() {
      _itemRatings[menuItemId] = rating;
    });
  }

  void _submitRatings() {
    final Map<String, double> ratingsToSubmit = {};
    _itemRatings.forEach((menuItemId, currentRating) {
      final initialRating = _initialItemRatings[menuItemId] ?? 0.0;
      if (currentRating > 0 && currentRating != initialRating) {
        ratingsToSubmit[menuItemId] = currentRating;
      } else if (currentRating > 0 && initialRating == 0.0) { 
         ratingsToSubmit[menuItemId] = currentRating;
      }
    });

    if (ratingsToSubmit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez noter ou modifier la note d'au moins un article.")), // Texte direct
      );
      return;
    }

    print("Soumission des notations: $ratingsToSubmit pour la commande ${widget.order.id}");
    context.read<RatingCubit>().submitRatings(
      orderId: widget.order.id,
      ratings: ratingsToSubmit,
    );
  }

  @override
  Widget build(BuildContext context) {
    const String currency = 'DA'; 

    LatLng initialCameraPosition = _defaultCenter;
    if (widget.order.deliveryAddress != null &&
        widget.order.deliveryAddress!.latitude != null &&
        widget.order.deliveryAddress!.longitude != null) {
      initialCameraPosition = LatLng(
          widget.order.deliveryAddress!.latitude!,
          widget.order.deliveryAddress!.longitude!);
    }

    bool hasNewOrChangedRatings = false;
    _itemRatings.forEach((menuItemId, currentRating) {
        final initialRating = _initialItemRatings[menuItemId] ?? 0.0;
        if (currentRating > 0 && currentRating != initialRating) {
            hasNewOrChangedRatings = true;
        } else if (currentRating > 0 && initialRating == 0.0) {
            hasNewOrChangedRatings = true;
        }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la commande'), // Texte direct
        centerTitle: true,
        elevation: 0.5,
      ),
      body: BlocListener<RatingCubit, RatingState>(
        listener: (context, state) {
          if (state is RatingSubmissionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notations soumises avec succès!'), backgroundColor: Colors.green), // Texte direct
            );
            _itemRatings.forEach((key, value) {
                if(value > 0) _initialItemRatings[key] = value;
            });
            if (mounted) { // Vérifier si le widget est toujours monté avant d'appeler setState
              setState(() {}); 
            }
          } else if (state is RatingSubmissionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Échec de la soumission des notations: ${state.error}"), backgroundColor: Colors.red), // Texte direct
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderStatusSection(context, widget.order),
              SizedBox(height: 20),
              if (widget.order.orderType.toLowerCase() == 'delivery' && widget.order.deliveryAddress != null)
                _buildMapView(context, initialCameraPosition)
              else if (widget.order.orderType.toLowerCase() == 'delivery' && widget.order.deliveryAddress == null)
                 _buildMapPlaceholder(context, message: "Adresse de livraison non disponible") // Texte direct
              else
                 SizedBox.shrink(),
              SizedBox(height: 20),
              _buildProductsSection(context, widget.order.items),
              SizedBox(height: 20),
              _buildOrderSummarySection(context, widget.order, currency),
              SizedBox(height: 20),
              if (widget.order.status.toLowerCase() == "delivered")
                Center(
                  child: BlocBuilder<RatingCubit, RatingState>(
                    builder: (context, state) {
                      if (state is RatingSubmissionInProgress) {
                        return CircularProgressIndicator(color: kMainColor);
                      }
                      return ElevatedButton.icon(
                        icon: Icon(Icons.star_outline, color: Colors.white),
                        label: Text("Soumettre les notations", style: TextStyle(color: Colors.white)), // Texte direct
                        onPressed: hasNewOrChangedRatings ? _submitRatings : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kMainColor,
                          disabledBackgroundColor: Colors.grey[400], 
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusSection(BuildContext context, OrderDetailsModel order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "ID Commande: ${order.id.length > 8 ? order.id.substring(0, 8) : order.id}...", // Texte direct
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    _getOrderStatusText(order.status), 
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: _getOrderStatusColor(order.status),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildDetailRow(context, "Type de paiement", order.paymentMethod.toUpperCase(), icon: Icons.payment), // Texte direct
            SizedBox(height: 8),
            _buildDetailRow(context, "Date de commande", DateFormat('d MMM yy, HH:mm', 'fr_FR').format(order.createdAt.toLocal()), icon: Icons.calendar_today_outlined), // Texte direct, format français
             if (order.deliveryAddress != null && order.orderType.toLowerCase() == 'delivery') ...[
                SizedBox(height: 8),
                _buildDetailRow(context, "Adresse de livraison", order.deliveryAddress!.address, icon: Icons.location_on_outlined), // Texte direct
             ]
          ],
        ),
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    status = status.toLowerCase();
    switch (status) {
      case 'pending': return Colors.orange.shade400;
      case 'confirmed': return Colors.blue.shade400;
      case 'preparing': return Colors.deepPurple.shade300;
      case 'out_for_delivery': return Colors.teal.shade300;
      case 'delivered': return Colors.green.shade500;
      case 'cancelled': return Colors.red.shade400;
      default: return Colors.grey.shade400;
    }
  }

  String _getOrderStatusText(String status) {
    status = status.toLowerCase();
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'out_for_delivery': return 'En livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status[0].toUpperCase() + status.substring(1);
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
          SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildMapView(BuildContext context, LatLng initialPosition) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 15.0,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            if (!_mapController.isCompleted) {
                 _mapController.complete(controller);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context, {String? message}) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 50, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              message ?? "Carte non disponible", // Texte direct
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        )
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context, List<OrderItemModel> items) { 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Produits", // Texte direct
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildProductItem(context, item); 
          },
          separatorBuilder: (context, index) => Divider(height: 16, thickness: 0.5),
        ),
      ],
    );
  }

  Widget _buildProductItem(BuildContext context, OrderItemModel item) { 
    const String currency = 'DA'; 
    final double currentDisplayRating = _itemRatings[item.menuItemId] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: item.image != null && item.image!.isNotEmpty
                  ? Image.network(
                      item.image!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.fastfood_outlined, color: Colors.grey[300])),
                    )
                  : Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.fastfood_outlined, color: Colors.grey[300])),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${item.quantity} x ${item.name}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (item.addons != null && item.addons!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        item.addons!.map((a) => a.name ?? '').where((name) => name.isNotEmpty).join(', '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    "${item.total.toStringAsFixed(2)} $currency",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kMainColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.order.status.toLowerCase() == "delivered") ...[
          SizedBox(height: 12),
          Text(
            (_initialItemRatings[item.menuItemId] ?? 0.0) > 0 
                ? "Votre note précédente :" // Texte direct
                : "Noter cet article :",  // Texte direct
            style: Theme.of(context).textTheme.bodyMedium
          ),
          SizedBox(height: 8),
          RatingBar.builder(
            initialRating: currentDisplayRating, 
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemPadding: EdgeInsets.symmetric(horizontal: 2.0),
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              _updateRating(item.menuItemId, rating);
            },
            itemSize: 30.0,
            glow: false,
          ),
        ]
      ],
    );
  }

  Widget _buildOrderSummarySection(BuildContext context, OrderDetailsModel order, String currency) { 
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Détails de la commande", // Texte direct
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildSummaryRow(context, "Sous-total", "${order.subtotal.toStringAsFixed(2)} $currency"), // Texte direct
            SizedBox(height: 8),
            _buildSummaryRow(context, "Frais de livraison", "${order.deliveryFee.toStringAsFixed(2)} $currency"), // Texte direct
            SizedBox(height: 8),
            Divider(height: 16, thickness: 0.8),
            _buildSummaryRow(context, "Total", "${order.total.toStringAsFixed(2)} $currency", isTotal: true), // Texte direct
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTotal ? Colors.black : Colors.grey[700],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isTotal ? kMainColor : Colors.black87,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 17 : 15,
              ),
        ),
      ],
    );
  }
}
