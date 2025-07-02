import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz_ordering/Components/colorButton.dart';
import 'package:hungerz_ordering/Components/textfield.dart';
import 'package:hungerz_ordering/Pages/verification.dart';

class LoginUi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadedSlideAnimation(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "ENTERED REGISTERED",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 16,
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      "PHONE NUMBER TO START",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 16,
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.phone_android,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text("PHONE NUMBER",
                        style: TextStyle(color: Colors.grey[600]))
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(left: 35),
                  child: Column(
                    children: [
                      EntryField("+1 984 596 4521"),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Text(
                            "We'll send Verification code on given number",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Verification()));
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: 35),
                    child: Row(
                      children: [
                        ColorButton("CONTINUE"),
                      ],
                    ),
                  ),
                ),
                Spacer()
              ],
            ),
          ),
        ),
        beginOffset: Offset(0, 0.3),
        endOffset: Offset(0, 0),
        fadeCurve: Curves.linearToEaseOut,
        slideCurve: Curves.linearToEaseOut,
      ),
    );
  }
}
