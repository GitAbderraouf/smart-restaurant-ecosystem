import 'package:flutter/material.dart';
import 'package:hungerz_store/Components/bottom_bar.dart';
import 'package:hungerz_store/Components/custom_appbar.dart';
import 'package:hungerz_store/Routes/routes.dart';
import 'package:hungerz_store/Themes/colors.dart';

class OrderInfo extends StatefulWidget {
  @override
  _OrderInfoState createState() => _OrderInfoState();
}

class _OrderInfoState extends State<OrderInfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(110.0),
        child: CustomAppBar(
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
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(0.0),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              // padding: EdgeInsets.only(top: 12.0),
              child: ListTile(
                title: Text(
                  'RAMY',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontSize: 14, letterSpacing: 0.07),
                ),
                subtitle: Text(
                  'AE5587 | June 20, 11:35 am',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontSize: 11.7, letterSpacing: 0.06),
                ),
                trailing: FittedBox(
                  fit: BoxFit.fill,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.message,
                          color: kMainColor,
                          size: 20.0,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, PageRoutes.chatPage);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.phone,
                          color: kMainColor,
                          size: 20.0,
                        ),
                        onPressed: () {
                          /*.......*/
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              Divider(
                color: Theme.of(context).cardColor,
                thickness: 8.0,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text("Items",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Color(0xffadadad),
                          fontWeight: FontWeight.bold)),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/ic_veg.png',
                        scale: 2.5,
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      Text(
                        "Sandwich",
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 15.0),
                      ),
                      Spacer(),
                      Text(
                        '1',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.w500, fontSize: 15.0),
                      ),
                      SizedBox(
                        width: 50.0,
                      ),
                      Text(
                        '\$ 5.00',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 13.3),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 35.0,
                      ),
                      Text(
                        "Cheese",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 13.3),
                      ),
                      Spacer(),
                      Text(
                        '\$ 3.00',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 13.3),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                color: Theme.of(context).cardColor,
                thickness: 1.0,
              ),
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/ic_nonveg.png',
                        scale: 2.5,
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      Text(
                        "Chicken",
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 15.0),
                      ),
                      Spacer(),
                      Text(
                        '1',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.w500, fontSize: 15.0),
                      ),
                      SizedBox(
                        width: 50.0,
                      ),
                      Text(
                        '\$ 7.00',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 13.3),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                color: Theme.of(context).cardColor,
                thickness: 1.0,
              ),
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/ic_veg.png',
                        scale: 2.5,
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      Text(
                        "Juice",
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 15.0),
                      ),
                      Spacer(),
                      Text(
                        '1',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.w500, fontSize: 15.0),
                      ),
                      SizedBox(
                        width: 50.0,
                      ),
                      Text(
                        '\$ 4.50',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 13.3),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Divider(
                color: Theme.of(context).cardColor,
                thickness: 8.0,
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                child: Text("PAYMENT",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: kDisabledColor, fontWeight: FontWeight.bold)),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Subtotal",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '\$ 19.50',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ]),
              ),
              Divider(
                color: Theme.of(context).cardColor,
                thickness: 1.0,
              ),
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Service Fee",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '\$ 1.50',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ]),
              ),
              Divider(
                color: Theme.of(context).cardColor,
                thickness: 1.0,
              ),
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 20.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Cash on Delivery",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$ 21.00',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ]),
              ),
              SizedBox(
                height: 7.0,
              ),
              Container(
                height: 180.0,
                color: Theme.of(context).cardColor,
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                InkWell(
                  onTap: () => Navigator.pushNamed(context, PageRoutes.track),
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 22.0,
                        backgroundImage: AssetImage('images/profile.jpg'),
                      ),
                      title: Text(
                        'rezki',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontSize: 15.0, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Delivery Partner",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(fontSize: 11.7, letterSpacing: 0.06),
                      ),
                      trailing: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.navigation,
                          color: kMainColor,
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                ),
                BottomBar(
                    text: "Mark as Ready",
                    onTap: () {
                      Navigator.pop(context);
                    })
              ],
            ),
          )
        ],
      ),
    );
  }
}
