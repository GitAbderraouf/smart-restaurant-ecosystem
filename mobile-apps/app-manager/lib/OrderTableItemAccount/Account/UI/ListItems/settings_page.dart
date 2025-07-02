// import 'package:animation_wrappers/animation_wrappers.dart';
// import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart'; // Not used
// import 'package:hungerz_store/Components/bottom_bar.dart';
// // import 'package:hungerz_store/Routes/routes.dart'; // Routes not used
// // import 'package:hungerz_store/Themes/colors.dart'; // Not used (kTextColor was inside commented out code)
// // import 'package:hungerz_store/theme_cubit.dart'; // Not used

// // class ThemeList {
// //   final String? title;
// //   final String? subtitle;

// //   ThemeList({this.title, this.subtitle});
// // }

// class Settings extends StatefulWidget {
//   @override
//   _SettingsState createState() => _SettingsState();
// }

// class _SettingsState extends State<Settings> {
//   // bool sliderValue = false; // Not needed
//   // late ThemeCubit _themeCubit; // Not needed
//   // String? selectedTheme; // Not needed

//   @override
//   void initState() {
//     // _themeCubit = BlocProvider.of<ThemeCubit>(context); // Not needed
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).cardColor,
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         title: Text("Settings",
//             style: Theme.of(context)
//                 .textTheme
//                 .headlineMedium!
//                 .copyWith(fontWeight: FontWeight.bold)),
//         titleSpacing: 0,
//         leading: IconButton(
//           icon: Icon(
//             Icons.chevron_left,
//             size: 30,
//             color: Theme.of(context).secondaryHeaderColor,
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: FadedSlideAnimation(
//         child: Stack(
//           children: [
//             ListView(
//               physics: BouncingScrollPhysics(),
//               children: [
//                 // All theme-related UI commented out or removed
//                 SizedBox(
//                   height: 100,
//                 ),
//               ],
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: BottomBar(
//                   text: "Submit",
//                   onTap: () {
//                     Navigator.pop(context);
//                   }),
//             ),
//           ],
//         ),
//         beginOffset: Offset(0.0, 0.3),
//         endOffset: Offset(0, 0),
//         slideCurve: Curves.linearToEaseOut,
//       ),
//     );
//   }
// }
