import 'package:flutter/material.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:google_fonts/google_fonts.dart';
//app theme

final ThemeData appTheme = ThemeData(
  fontFamily: 'ProductSans',
  scaffoldBackgroundColor: Colors.white,
  secondaryHeaderColor: kMainTextColor,
  primaryColor: kMainColor,
  primarySwatch: kMainSwatchColor,
  // checkboxTheme: CheckboxThemeData(
  //     checkColor: MaterialStateProperty.all(Colors.white),
  //     fillColor: MaterialStateProperty.all(kMainColor)),
  // switchTheme: SwitchThemeData(
  //   thumbColor: MaterialStateProperty.all(kMainColor),
  //   trackColor: MaterialStateProperty.all(Color(0x66D8A21B)),
  // ),
  //radioTheme: RadioThemeData(fillColor: MaterialStateProperty.all(kMainColor)),
  // toggleableActiveColor: kMainColor,
  unselectedWidgetColor: Colors.black,
  // bottomAppBarColor: kWhiteColor,
  dividerColor: Color(0x1f000000),
  disabledColor: kDisabledColor,
  // buttonColor: kMainColor,
  cardColor: kCardBackgroundColor,
  hintColor: kLightTextColor,
  indicatorColor: kMainColor,
  // accentColor: kMainColor,
  bottomAppBarTheme: BottomAppBarTheme(color: kMainColor),
  buttonTheme: ButtonThemeData(
    textTheme: ButtonTextTheme.normal,
    height: 33,
    padding: EdgeInsets.only(top: 0, bottom: 0, left: 16, right: 16),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30.0)),
        side: BorderSide(color: kMainColor)),
    alignedDropdown: false,
    buttonColor: kMainColor,
    disabledColor: kDisabledColor,
  ),
  appBarTheme: AppBarTheme(
    color: kTransparentColor,
    elevation: 0.0,
  ),
  //text theme which contains all text styles
  textTheme: GoogleFonts.openSansTextTheme().copyWith(
    //text style of 'Delivering almost everything' at phone_number page
    bodyLarge: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18.3,
    ),

    //text style of 'Everything.' at phone_number page
    bodyMedium: TextStyle(
      fontSize: 18.3,
      // letterSpacing: 1.0,
      color: kDisabledColor,
    ),

    //text style of button at phone_number page
    // button: TextStyle(
    //   fontSize: 13.3,
    //   color: kWhiteColor,
    // ),

    //text style of 'Got Delivered' at home page
    headlineMedium: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 16.7,
    ),

    //text style of we'll send verification code at register page
    titleLarge: TextStyle(
      color: kLightTextColor,
      fontSize: 13.3,
    ),

    //text style of 'everything you need' at home page
    // headline5: TextStyle(
    //   color: kDisabledColor,
    //   fontSize: 20.0,
    //   // letterSpacing: 0.5,
    // ),

    //text entry text style
    bodySmall: TextStyle(
      color: kMainTextColor,
      fontSize: 13.3,
    ),

    labelSmall: TextStyle(
      color: kLightTextColor,
      letterSpacing: 0.2,
    ),

    //text style of titles of card at home page
    displayMedium: TextStyle(
      color: kMainTextColor,
      fontSize: 12.0,
      fontWeight: FontWeight.bold,
      // letterSpacing: 0.5,
    ),
    titleSmall: TextStyle(
      color: kLightTextColor,
      fontSize: 15.0,
    ),
  ),
);

final ThemeData darkTheme = appTheme.copyWith(
  scaffoldBackgroundColor: kMainTextColor,
  secondaryHeaderColor: kWhiteColor,
  unselectedWidgetColor: Colors.white,
  primaryColor: kMainColor,
  // bottomAppBarColor: kMainTextColor,
  dividerColor: Color(0x1f000000),
  disabledColor: kDisabledColor,
  // buttonColor: kMainColor,
  cardColor: Color(0xff212321),
  hintColor: kLightTextColor,
  indicatorColor: kMainColor,
  // accentColor: kMainColor,
  bottomAppBarTheme: BottomAppBarTheme(color: kMainColor),
  buttonTheme: ButtonThemeData(
    textTheme: ButtonTextTheme.normal,
    height: 33,
    padding: EdgeInsets.only(top: 0, bottom: 0, left: 16, right: 16),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30.0)),
        side: BorderSide(color: kMainColor)),
    alignedDropdown: false,
    buttonColor: kMainColor,
    disabledColor: kDisabledColor,
  ),
  appBarTheme: AppBarTheme(
      color: kTransparentColor,
      elevation: 0.0,
      iconTheme: IconThemeData(color: Colors.white)),
  //text theme which contains all text styles
  textTheme: GoogleFonts.openSansTextTheme().copyWith(
    //text style of 'Delivering almost everything' at phone_number page
    bodyLarge: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18.3,
    ),

    //text style of 'Everything.' at phone_number page
    bodyMedium: TextStyle(
      fontSize: 18.3,
      // letterSpacing: 1.0,
      color: kDisabledColor,
    ),

    //text style of button at phone_number page
    // button: TextStyle(
    //   fontSize: 13.3,
    //   color: kWhiteColor,
    // ),

    //text style of 'Got Delivered' at home page
    headlineMedium: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16.7,
    ),

    //text style of we'll send verification code at register page
    titleLarge: TextStyle(
      color: kLightTextColor,
      fontSize: 13.3,
    ),

    //text style of 'everything you need' at home page
    headlineSmall: TextStyle(
      color: kDisabledColor,
      fontSize: 20.0,
      // letterSpacing: 0.5,
    ),

    //text entry text style
    bodySmall: TextStyle(
      color: Colors.white,
      fontSize: 13.3,
    ),

    labelSmall: TextStyle(color: kLightTextColor, letterSpacing: 0.2),

    //text style of titles of card at home page
    displayMedium: TextStyle(
      color: Colors.white,
      fontSize: 12.0,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
    titleSmall: TextStyle(
      color: kLightTextColor,
      fontSize: 15.0,
    ),
  ),
);

//text style of continue bottom bar
final TextStyle bottomBarTextStyle = GoogleFonts.openSans().copyWith(
  fontSize: 15.0,
  color: kWhiteColor,
  fontWeight: FontWeight.w400,
);

//text style of text input and account page list
final TextStyle inputTextStyle = GoogleFonts.openSans().copyWith(
  fontSize: 20.0,
  color: Colors.black,
);

final TextStyle listTitleTextStyle = GoogleFonts.openSans().copyWith(
  fontSize: 16.7,
  fontWeight: FontWeight.bold,
  color: kMainColor,
);

final TextStyle orderMapAppBarTextStyle = GoogleFonts.openSans().copyWith(
  fontSize: 13.3,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);
