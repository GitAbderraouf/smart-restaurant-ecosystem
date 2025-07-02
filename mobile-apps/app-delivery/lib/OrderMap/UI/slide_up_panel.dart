import 'package:flutter/material.dart';
// import 'package:hungerz_delivery/Locale/locales.dart'; // Removed
import 'package:hungerz_delivery/Themes/colors.dart';

class OrderInfoContainer extends StatefulWidget {
  final List<String?> itemName;

  OrderInfoContainer(this.itemName);

  @override
  _OrderInfoContainerState createState() => _OrderInfoContainerState();
}

class _OrderInfoContainerState extends State<OrderInfoContainer> {
  List<double> prices = [
    3.00,
    4.50,
    2.50,
  ];

  double sum() {
    double total = 0.00;
    for (int i = 0; i < prices.length; i++) {
      total += prices[i];
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      height: MediaQuery.of(context).size.width-140,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: widget.itemName.length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: ListTile(
                    title: Text(
                      widget.itemName[index]!,
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.w500, fontSize: 15.0),
                    ),
                    trailing: FittedBox(
                      child: Row(
                        children: [
                          Text('1',style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(fontSize: 15.0),),
                          SizedBox(width: 40.0,),
                          Text(
                            '\$ ${prices[index]}0',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(fontSize: 15.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 50.0,
            color: kMainColor,
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Cash on Delivery", // AppLocalizations.of(context)!.cod!,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(color: kWhiteColor),
                  ),
                  Text(
                    '\$ 11.50',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: kWhiteColor,fontWeight: FontWeight.bold),
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}
