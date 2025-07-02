import 'dart:async';
import 'package:animation_wrappers/animation_wrappers.dart'; // Gardé
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour formatters
import 'package:flutter_bloc/flutter_bloc.dart'; // Ajouté
import 'package:hungerz/Components/bottom_bar.dart'; // Gardé
// import 'package:hungerz/Components/textfield.dart'; // Remplacé (EntryField)
import 'package:hungerz/Locale/locales.dart'; // Gardé
//import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart'; // Ajouté
import 'package:hungerz/Auth/login_navigator.dart'; // Pour routeName

// --- VerificationPage ---
class VerificationPage extends StatelessWidget {
  final String phoneNumber; // Reçoit le numéro
  // Suppression de onVerificationDone
  const VerificationPage({required this.phoneNumber, super.key});
  static const String routeName = LoginRoutes.verification;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // Gardé
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(
          AppLocalizations.of(context)!.verification!, // Gardé
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 18), // Gardé
        ),
      ),
      body: FadedSlideAnimation( // Gardé
        beginOffset: const Offset(0.0, 0.3),
        endOffset: Offset.zero,
        slideCurve: Curves.linearToEaseOut,
        child: OtpVerify(phoneNumber: phoneNumber), // Passe le numéro
      ),
    );
  }
}

// --- OtpVerify ---
class OtpVerify extends StatefulWidget {
  final String phoneNumber; // Reçoit le numéro
  // Suppression de onVerificationDone
  const OtpVerify({required this.phoneNumber, super.key});

  @override
  _OtpVerifyState createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  // Renommé _controller en _otpController
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Ajouté pour validation OTP
  bool _isLoading = false; // Chargement bouton Vérifier
  bool _isResending = false; // Chargement bouton Renvoyer
  int _counter = 20;
  Timer? _timer;

  // --- Timer Logic (inchangé) ---
  _startTimer() {
    _timer?.cancel();
    _counter = 20;
     if (mounted) setState(() {});
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() { _counter > 0 ? _counter-- : timer.cancel(); });
        if (_counter <= 0) timer.cancel();
      } else { timer.cancel(); }
    });
  }

  @override
  void initState() {
    super.initState();
    _startTimer(); // Démarre le compteur pour le renvoi
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- Logique pour soumettre l'OTP ---
  void _submitOtp() {
    // Utiliser la clé de formulaire pour valider
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }
     FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; });

    final otp = _otpController.text.trim();
    // Appel au Cubit pour vérification finale
    context.read<AuthCubit>().completeOtpVerification(otp, widget.phoneNumber)
      .catchError((e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur inattendue.")));}) // TODO: Localize
      .whenComplete((){ if(mounted) setState(() { _isLoading = false; }); });
    // La navigation vers Home est gérée par le listener global
  }

  // --- Logique pour renvoyer l'OTP ---
  void _resendOtp() {
        final authCubit = context.read<AuthCubit>();
    final currentState = authCubit.state;

    // Déclarer userId *avant* le if pour qu'il soit accessible après
    String? userId; // Déclaré ici, initialement null

    if (currentState is GoogleSignInSuccessfulNeedsPhone) {
      // Assigner la valeur si l'état est correct
      userId = currentState.userId; // userId (de portée externe) reçoit la valeur
      print("SocialLogin: userId récupéré depuis l'état: $userId");
    }
     if (_counter > 0 || _isResending) return;
     setState(() { _isResending = true; });

     // Appel au Cubit pour redemander l'envoi (réutilise submitPhoneNumber)
     context.read<AuthCubit>().submitPhoneNumber(widget.phoneNumber,userId: userId) // userId est optionnel
        .then((_){
             if(mounted && context.read<AuthCubit>().state is! AuthError) {
                 print("Nouvel OTP demandé via resend.");
                 _startTimer(); // Redémarrer le compteur
             }
        })
        .catchError((e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors du renvoi.")));}) // TODO: Localize
        .whenComplete((){ if(mounted) setState(() { _isResending = false; }); });
  }


  @override
  Widget build(BuildContext context) {
    // Ajout Listener pour erreurs/loading
    return BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
             if (state is AuthError) {
                 if(mounted) FocusScope.of(context).unfocus();
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                 );
                 if ((_isLoading || _isResending) && mounted) {
                    setState(() { _isLoading = false; _isResending = false; });
                 }
             } else if (state is! AuthLoading && (_isLoading || _isResending) && mounted) {
                 setState(() { _isLoading = false; _isResending = false; });
             }
             // Pas de navigation ici
         },
      child: Stack( // Gardé
        children: [
           Padding( // Padding global
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Form( // Ajout Form
              key: _formKey,
              child: Column( // Gardé (retiré Container hauteur fixe et SingleChildScroll)
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Retiré Divider
                  Padding( // Gardé
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0), // Ajusté padding
                    child: Text(
                      AppLocalizations.of(context)!.enterVerification!, // Gardé
                      style: Theme.of(context).textTheme.titleLarge!.copyWith( // Gardé
                          fontSize: 22,
                          color: Theme.of(context).secondaryHeaderColor),
                    ),
                  ),
                  Text( // Ajouté pour afficher le numéro
                      "Entrez le code envoyé au ${widget.phoneNumber}", // TODO: Localize
                      style: Theme.of(context).textTheme.bodyMedium,
                   ),
                  const SizedBox(height: 30),

                  // --- Remplacement de EntryField ---
                  // Utilisez ceci ou adaptez votre EntryField si possible
                  TextFormField(
                      controller: _otpController, // Connecté au controller
                      keyboardType: TextInputType.number,
                      maxLength: 6, // Longueur OTP
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold), // Style OTP
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.verificationCode, // Gardé
                          counterText: "",
                          hintText: "------",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                       validator: (value){ // Ajout validation
                           if (value == null || value.trim().isEmpty) return "Code requis"; // TODO: Localize
                           if (value.length < 6) return "6 chiffres requis"; // TODO: Localize
                           return null;
                       },
                  ),
                  // --- Fin Remplacement ---

                  const Spacer(), // Gardé

                  // --- Compteur et Renvoyer ---
                  Row( // Gardé
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding( // Gardé
                        padding: const EdgeInsets.symmetric(horizontal: 0.0), // Ajusté
                        child: Text(
                          '00:${_counter.toString().padLeft(2, '0')}', // Gardé
                           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                               color: _counter > 0 ? Colors.grey : Theme.of(context).colorScheme.secondary
                           ),
                        ),
                      ),
                      TextButton( // Gardé
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0), // Ajusté padding
                          ),
                          // Logique onPressed modifiée pour appeler _resendOtp
                          onPressed: (_counter > 0 || _isResending) ? null : _resendOtp,
                          child: FadedScaleAnimation( // Gardé
                             fadeDuration: const Duration(milliseconds: 800),
                            child: _isResending // Afficher indicateur
                             ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                             : Text(
                                AppLocalizations.of(context)!.resend!, // Gardé
                                 style: TextStyle(
                                  fontSize: 16.7,
                                  color: (_counter > 0 || _isResending) ? Colors.grey : Theme.of(context).primaryColor,
                                ),
                              ),
                          )),
                    ],
                  ),
                   const SizedBox(height: 70) // Espace pour BottomBar
                ],
              ),
            ),
          ),
          // --- Utilisation de votre BottomBar ---
          Align( // Gardé
            alignment: Alignment.bottomCenter,
            child: BottomBar( // Gardé
                text: _isLoading
                    ? ( "Chargement...") // Gardé
                    : (AppLocalizations.of(context)!.continueText ?? "Continuer"), // Gardé
                // Modifié pour appeler _submitOtp
                onTap: _isLoading ? (){} : _submitOtp,
             ),
          ),
        ],
      ),
    );
  }
}