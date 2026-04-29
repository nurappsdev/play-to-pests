// import 'package:flutter/material.dart';
//
// class MainMenuScreen extends StatelessWidget {
//   static const String _startImagePath = 'debImg/startImg.png';
//
//   final VoidCallback onStartPressed;
//   final VoidCallback onPest3dPressed;
//
//
//   const MainMenuScreen({
//     super.key,
//     required this.onStartPressed,
//     required this.onPest3dPressed,
//
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: GestureDetector(
//         onTap: onStartPressed,
//         child: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('assets/images/start_screen_bg.png'),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child:  Center(
//             child: Column(
//
//               children: [
//                 // Optionally add "Tap to Start" text if needed,
//                 // though the design seems to be just the image.
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
