import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hungerz_store/Components/bottom_bar.dart';
import 'package:hungerz_store/Components/textfield.dart';
import 'package:hungerz_store/Themes/colors.dart';

//Verification page that sends otp to the phone number entered on phone number page
class VerificationPage extends StatelessWidget {
  final VoidCallback onVerificationDone;

  VerificationPage(this.onVerificationDone);

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(
          "Verification",
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: OtpVerify(onVerificationDone),
    );
  }
}

//otp verification class
class OtpVerify extends StatefulWidget {
  final VoidCallback onVerificationDone;

  OtpVerify(this.onVerificationDone);

  @override
  _OtpVerifyState createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  final TextEditingController _controller = TextEditingController();

  // VerificationBloc _verificationBloc;
  bool isDialogShowing = false;
  int _counter = 20;
  late Timer _timer;

  _startTimer() {
    //shows timer
    _counter = 20; //time counter

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _counter > 0 ? _counter-- : _timer.cancel();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    verifyPhoneNumber();
  }

  void verifyPhoneNumber() {
    //verify phone number method using otp
    _startTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: <Widget>[
            Divider(
              color: Theme.of(context).cardColor,
              thickness: 8.0,
            ),
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Enter verification code sent on your number.",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 17,
                    color: Theme.of(context).secondaryHeaderColor,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              // child: EntryField(
              //  // controller: _controller,
              //   readOnly: false,
              //   label: AppLocalizations.of(context).verificationCode,
              //   maxLength: 6,
              //   keyboardType: TextInputType.number,
              //   initialValue: '123456',
              // ),
              child: EntryFormField(
                  "Verification Code",
                  '5 7 9 6 4 4'),
            ),
          ],
        ),
        PositionedDirectional(
          bottom: 0,
          start: 0,
          end: 0,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '00:$_counter min',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(side: BorderSide.none),
                        padding: EdgeInsets.all(24.0),
                      ),
                      child: Text(
                        "Resend",
                        style: TextStyle(
                          fontSize: 16.7,
                          color: kMainColor,
                        ),
                      ),
                      onPressed: _counter < 1
                          ? () {
                              verifyPhoneNumber();
                            }
                          : null),
                ],
              ),
              BottomBar(
                  text: "Verify & Continue",
                  onTap: () {
                    widget.onVerificationDone();
                  }),
            ],
          ),
        ),
      ],
    );
  }
}
