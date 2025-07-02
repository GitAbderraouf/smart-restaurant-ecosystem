import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Pages/reservation_page.dart';
import 'package:hungerz/Pages/qr_scanner_page.dart';
import 'package:hungerz/Routes/routes.dart';
import 'package:hungerz/Themes/colors.dart';


class BookingRow extends StatefulWidget {
  const BookingRow({super.key});

  @override
  _BookingRowState createState() => _BookingRowState();
}

class _BookingRowState extends State<BookingRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRScannerPage(
                    onScan: (scannedValue, userId) {
                      // Handle the scanned value (e.g., send to backend via Socket.IO)
                      print('Scanned QR: $scannedValue, User ID: $userId');
                      // TODO: Emit Socket.IO event here
                    },
                  ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(12.0),
              color: Theme.of(context).cardColor,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset("images/scan.png", scale: 3),
                SizedBox(width: 8),
                Expanded(
                  child: Text("SCAN & CONNECT",
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(fontSize: 11)),
                ),
              ]),
            ),
          ),
        ),
        SizedBox(width: 10.0),
        Expanded(
          child: InkWell(
            onTap: () {
              // showModalBottomSheet(
              //   isScrollControlled: true,
              //   context: context,
              //   builder: (context) {
              //     return Container(
              //       child: BottomWidget(),
              //     );
              //   },
              // );
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReservationPage()
                  ));
            },
            child: Container(
              padding: EdgeInsets.all(12.0),
              color: Theme.of(context).cardColor,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset("images/tablebooking.png", scale: 3),
                SizedBox(width: 8),
                Text("BOOK A TABLE",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(fontSize: 11)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class Datee {
  final String image;
  final String title;

  Datee(this.image, this.title);
}

class Time {
  final String image;
  final String title;

  Time(this.image, this.title);
}

class Cat {
  final String? title;

  Cat(this.title);
}

class BottomWidget extends StatefulWidget {
  const BottomWidget({super.key});

  @override
  _BottomWidgetState createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
  int forIndex = 0;
  int dateIndex = 0;
  int timeIndex = 0;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final List<Cat> cat = [
      Cat(AppLocalizations.of(context)!.pe),
      Cat(AppLocalizations.of(context)!.per),
      Cat(AppLocalizations.of(context)!.pers),
      Cat(AppLocalizations.of(context)!.perso),
      Cat(AppLocalizations.of(context)!.person),
    ];
    final List<Datee> datee = [
      Datee('k', "20 Jun"),
      Datee('k', "21 Jun"),
      Datee('k', "22 Jun"),
      Datee('k', "23 Jun"),
      Datee('k', "24 Jun"),
    ];
    final List<Time> time = [
      Time('k', "09:00 am"),
      Time('k', "09:00 am"),
      Time('k', "9:30 am"),
      Time('k', "10:00 am"),
      Time('k', "10:30 am"),
    ];
    return FadedSlideAnimation(
      beginOffset: Offset(0.0, 0.3),
      endOffset: Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: 30),
            Row(
              children: [
                SizedBox(width: 20),
                Text(
                  AppLocalizations.of(context)!.tabletext!.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      letterSpacing: 1.5),
                ),
              ],
            ),
            SizedBox(height: 25),
            Row(
              children: [
                SizedBox(width: 20),
                Text(
                  AppLocalizations.of(context)!.booking!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              height: 35.0,
              margin: EdgeInsets.only(left: 12),
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: cat.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          forIndex = index;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Container(
                            height: 33.3,
                            width: 83.3,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: forIndex == index
                                      ? kMainColor
                                      : Colors.white),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              color: forIndex == index
                                  ? Color(0xffFFEEC8)
                                  : Colors.white,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cat[index].title!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: forIndex == index ? 13 : 12.0),
                            )),
                      ),
                    );
                  }),
            ),
            SizedBox(
              height: 25,
            ),
            Row(children: [
              SizedBox(
                width: 20,
              ),
              Text(
                "Select Date",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontSize: 14.0, fontWeight: FontWeight.bold),
              )
            ]),
            SizedBox(height: 20),
            Container(
              height: 35.0,
              margin: EdgeInsets.only(left: 12),
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: cat.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          dateIndex = index;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Container(
                            height: 33.3,
                            width: 83.3,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: dateIndex == index
                                      ? kMainColor
                                      : Colors.white),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              color: dateIndex == index
                                  ? Color(0xffFFEEC8)
                                  : Colors.white,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              datee[index].title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: dateIndex == index ? 13 : 12.0),
                            )),
                      ),
                    );
                  }),
            ),
            SizedBox(
              height: 25,
            ),
            Row(
              children: [
                SizedBox(
                  width: 20,
                ),
                Text(
                  "Select Time",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontSize: 14.0, fontWeight: FontWeight.bold),
                )
              ],
            ),
            SizedBox(height: 20),
            Container(
              height: 35.0,
              margin: EdgeInsets.only(left: 12),
              child: ListView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: cat.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          timeIndex = index;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Container(
                            height: 33.3,
                            width: 83.3,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: timeIndex == index
                                      ? kMainColor
                                      : Colors.white),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              color: timeIndex == index
                                  ? Color(0xffFFEEC8)
                                  : Colors.white,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              time[index].title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: timeIndex == index ? 13 : 12.0),
                            )),
                      ),
                    );
                  }),
            ),
            SizedBox(height: 25),
            Row(children: [
              SizedBox(
                width: 20,
              ),
              Text(
                "Add Note",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontSize: 14.0, fontWeight: FontWeight.bold),
              )
            ]),
            SizedBox(height: 20),
            Container(
              height: 100,
              margin: const EdgeInsets.only(left: 20.0, right: 20.0),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36.0),
                child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: "i.g for my Anniversary",
                        hintStyle:
                            TextStyle(fontSize: 14, color: Colors.grey[400]),
                        border: InputBorder.none)),
              ),
            ),
            SizedBox(height: 20),
            BottomBar(
              text: 'Book A Table',
              onTap: () => Navigator.pushNamed(context, PageRoutes.tablebooked),
            )
          ],
        ),
      ),
    );
  }
}
