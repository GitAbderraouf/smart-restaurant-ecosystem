import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:hungerz/Auth/login_navigator.dart';
import 'package:hungerz/Components/entry_field.dart';
import 'package:hungerz/Locale/locales.dart';

class MobileInput extends StatefulWidget {
  const MobileInput({super.key});

  @override
  _MobileInputState createState() => _MobileInputState();
}

class _MobileInputState extends State<MobileInput> {
  final TextEditingController _controller = TextEditingController();
  String? isoCode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Color(0xffF9F9FD)),
      child: Row(
        children: <Widget>[
          CountryCodePicker(
            onChanged: (value) {
              isoCode = value.code;
            },
            builder: (value) => buildButton(value),
            initialSelection: '+213',
            textStyle: Theme.of(context).textTheme.bodySmall,
            showFlag: false,
            showFlagDialog: true,
            favorite: ['+91', 'US'],
          ),
          SizedBox(
            width: 10.0,
          ),
          //takes phone number as input
          Expanded(
            child: EntryField(
              controller: _controller,
              keyboardType: TextInputType.number,
              readOnly: false,
              hint: AppLocalizations.of(context)!.mobileText,
              maxLength: 10,
              border: InputBorder.none,
            ),
          ),

          //if phone number
          // is valid, button gets enabled and takes to register screen
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                AppLocalizations.of(context)!.continueText!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, LoginRoutes.signUp);
            },
          ),
        ],
      ),
    );
  }

  buildButton(CountryCode? isoCode) {
    return Row(
      children: <Widget>[
        Text(
          '$isoCode',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
