// import 'package:flutter/material.dart';

// class Review {
//   final String? title;
//   final double rating;
//   final String date;
//   final String? content;

//   Review(this.title, this.rating, this.date, this.content);
// }

// class ReviewPage extends StatefulWidget {
//   @override
//   _ReviewPageState createState() => _ReviewPageState();
// }

// class _ReviewPageState extends State<ReviewPage> {
//   @override
//   Widget build(BuildContext context) {
//     final List<Review> listOfReviews = [
//       Review(
//           "User Name 1", 4.0, '5 April, 20', "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
//       Review(
//           "User Name 2", 5.0, '23 Feb, 20', "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
//       Review(
//           "User Name 3", 4.0, '16 May, 20', "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
//       Review(
//           "User Name 1", 5.0, '13 Feb, 20', "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
//       Review(
//           "User Name 3", 4.0, '11 June, 20', "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
//       Review(
//           "User Name 2", 5.0, '13 Feb, 20', "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
//       Review(
//           "User Name 1", 4.0, '26 April, 20', "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
//     ];
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(70.0),
//         child: AppBar(
//           flexibleSpace: Container(
//             padding: EdgeInsets.only(left: 60),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 SizedBox(
//                   height: 30,
//                 ),
//                 Text(
//                   "Store Rating",
//                   style: Theme.of(context).textTheme.bodyLarge,
//                 ),
//                 SizedBox(
//                   height: 8.0,
//                 ),
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.star,
//                       color: Color(0xff7ac81e),
//                       size: 14,
//                     ),
//                     SizedBox(width: 8.0),
//                     Text('4.2',
//                         style: Theme.of(context)
//                             .textTheme
//                             .labelSmall!
//                             .copyWith(color: Color(0xff7ac81e))),
//                     SizedBox(width: 8.0),
//                     Text('148 reviews',
//                         style: Theme.of(context).textTheme.labelSmall),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           titleSpacing: 0,
//           leading: IconButton(
//             icon: Icon(
//               Icons.chevron_left,
//               size: 30,
//             color: Theme.of(context).secondaryHeaderColor,
//             ),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//         ),
//       ),
//       body: ListView.builder(
//           itemCount: listOfReviews.length,
//           itemBuilder: (context, index) {
//             return Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Divider(
//                     color: Theme.of(context).cardColor,
//                     thickness: 6.7,
//                   ),
//                   Text(
//                     listOfReviews[index].title!,
//                     style: Theme.of(context)
//                         .textTheme
//                         .headlineMedium!
//                         .copyWith(fontSize: 15.0),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.symmetric(vertical: 8.0),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.star,
//                           color: Color(0xff7ac81e),
//                           size: 13,
//                         ),
//                         SizedBox(width: 8.0),
//                         Text(listOfReviews[index].rating.toString(),
//                             style: Theme.of(context).textTheme.bodySmall!.copyWith(
//                                   color: Color(0xff7ac81e),
//                                 )),
//                         Spacer(),
//                         Text(
//                           listOfReviews[index].date,
//                           style: Theme.of(context).textTheme.bodySmall!.copyWith(
//                               fontSize: 11.7, color: Color(0xffd7d7d7)),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Text(
//                     listOfReviews[index].content!,
//                     textAlign: TextAlign.justify,
//                     style: Theme.of(context)
//                         .textTheme
//                         .bodySmall!
//                         .copyWith(color: Color(0xff6a6c74)),
//                   )
//                 ],
//               ),
//             );
//           }),
//     );
//   }
// }
