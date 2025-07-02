import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/Themes/style.dart';
import 'package:hungerz/Components/textfield.dart';

class AddMoney extends StatelessWidget {
  const AddMoney({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addMoney!,
            style: Theme.of(context)
                .textTheme
                .headlineMedium!
                .copyWith(fontWeight: FontWeight.bold)),
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Add(),
    );
  }
}

class Add extends StatelessWidget {
  const Add({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        FadedSlideAnimation(
          beginOffset: Offset(0.0, 0.3),
          endOffset: Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Row(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .availableBalance!
                                  .toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                      letterSpacing: 0.67,
                                      color: kHintColor,
                                      fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '\$ 258.50',
                            style: listTitleTextStyle.copyWith(
                                fontSize: 35.0,
                                color: Colors.black,
                                letterSpacing: 0.18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Theme.of(context).cardColor,
                  thickness: 8.0,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              AppLocalizations.of(context)!
                                  .bankInfo!
                                  .toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.67,
                                      color: kHintColor),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        SmallTextFormField(
                          AppLocalizations.of(context)!
                              .accountHolderName!
                              .toUpperCase(),
                          'Declan Rice',
                        ),
                        SmallTextFormField(
                          AppLocalizations.of(context)!.bankName!.toUpperCase(),
                          'HBNC Bank of kertala',
                        ),
                        SmallTextFormField(
                          AppLocalizations.of(context)!
                              .branchCode!
                              .toUpperCase(),
                          '+1 987 654 3210',
                        ),
                        SmallTextFormField(
                          AppLocalizations.of(context)!
                              .accountNumber!
                              .toUpperCase(),
                          '4321 4567 6789 8901',
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: Theme.of(context).cardColor,
                  thickness: 8.0,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: SmallTextFormField(
                    AppLocalizations.of(context)!
                        .enterAmountToTransfer!
                        .toUpperCase(),
                    '\$ 500',
                  ),
                ),
                SizedBox(
                  height: 80,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomBar(
            text: "Send to Bank",
            onTap: () => Navigator.pop(context),
          ),
        )
      ],
    );
  }
}
