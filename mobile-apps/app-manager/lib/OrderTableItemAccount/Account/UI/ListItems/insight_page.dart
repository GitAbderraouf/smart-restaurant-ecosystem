import 'package:flutter/material.dart';
// import 'package:hungerz_store/Locale/locales.dart'; // Removed
import 'package:hungerz_store/Routes/routes.dart';
import 'package:hungerz_store/Themes/colors.dart';

class InsightPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Insight", // Was AppLocalizations.of(context)!.insight!
            style: Theme.of(context).textTheme.bodyLarge),
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
        actions: <Widget>[
          Row(
            children: <Widget>[
              Text(
                "TODAY", // Was AppLocalizations.of(context)!.today!.toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontSize: 15.0,
                    letterSpacing: 1.5,
                    color: Theme.of(context).primaryColor),
              ),
              IconButton(
                icon: Icon(Icons.arrow_drop_down),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  /*....*/
                },
              )
            ],
          )
        ],
      ),
      body: Insight(),
    );
  }
}

class Insight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(bottom: 10),
      children: <Widget>[
        Divider(
          color: Theme.of(context).cardColor,
          thickness: 8.0,
        ),
        Padding(
          padding: EdgeInsets.only(left: 40.0, right: 40, top: 10),
          child: Row(
            children: <Widget>[
              Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '32',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Text(
                    "Orders", // Was AppLocalizations.of(context)!.orders!,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold, color: kTextColor),
                  ),
                ],
              ),
              Spacer(),
              Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '229',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Text(
                    "Items Sold", // Was AppLocalizations.of(context)!.itemSold!,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold, color: kTextColor),
                  ),
                ],
              ),
              Spacer(),
              Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '\$494.50',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Text(
                    "Earnings", // Was AppLocalizations.of(context)!.earnings! (used for the stat value, not uppercase title here)
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold, color: kTextColor),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: kMainColor,
                        borderRadius: BorderRadius.circular(5)),
                  )
                ],
              ),
            ],
          ),
        ),
        Divider(
          color: Theme.of(context).cardColor,
          thickness: 6.7,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("EARNINGS", // Was AppLocalizations.of(context)!.earnings!.toUpperCase()
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontSize: 15.0, letterSpacing: 1.5)),
              Center(
                child: Image(
                  image: AssetImage("images/graph.png"),
                  height: 200.0,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, PageRoutes.walletPage),
                child: Center(
                  child: Text(
                    "VIEW ALL", // Was AppLocalizations.of(context)!.viewAll!.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: kMainColor,
                        letterSpacing: 1.33,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: Theme.of(context).cardColor,
          thickness: 6.7,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("Top Selling Items", // Was AppLocalizations.of(context)!.top!
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).secondaryHeaderColor,
                      letterSpacing: 0.77)),
              Text("Based on total orders", // Was AppLocalizations.of(context)!.total!
                  style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: <Widget>[
              Image(
                image: AssetImage("images/2.png"),
                height: 61.3,
                width: 61.3,
              ),
              SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Sandwich", // Was AppLocalizations.of(context)!.sandwich!
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 15.0, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.0),
                  Text('188 ' + "Sales", // Was AppLocalizations.of(context)!.sales!
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontSize: 11.7)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            children: <Widget>[
              Image(
                image: AssetImage("images/4.png"),
                height: 61.3,
                width: 61.3,
              ),
              SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Chicken", // Was AppLocalizations.of(context)!.chicken!
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 15.0, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.0),
                  Text('179 ' + "Sales", // Was AppLocalizations.of(context)!.sales!
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontSize: 11.7)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: <Widget>[
              Image(
                image: AssetImage("images/5.png"),
                height: 61.3,
                width: 61.3,
              ),
              SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Burger", // Was AppLocalizations.of(context)!.burger!
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 15.0, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.0),
                  Text('154 ' + "Sales", // Was AppLocalizations.of(context)!.sales!
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontSize: 11.7)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            children: <Widget>[
              Image(
                image: AssetImage("images/4.png"),
                height: 61.3,
                width: 61.3,
              ),
              SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Chicken", // Was AppLocalizations.of(context)!.chicken! (repeated item)
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 15.0, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.0),
                  Text('179 ' + "Sales", // Was AppLocalizations.of(context)!.sales!
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontSize: 11.7)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: <Widget>[
              Image(
                image: AssetImage("images/5.png"),
                height: 61.3,
                width: 61.3,
              ),
              SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Burger", // Was AppLocalizations.of(context)!.burger! (repeated item)
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 15.0, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.0),
                  Text('154 ' + "Sales", // Was AppLocalizations.of(context)!.sales!
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontSize: 11.7)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
