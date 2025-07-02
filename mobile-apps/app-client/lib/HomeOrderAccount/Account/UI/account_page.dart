// import 'package:buy_this_app/buy_this_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart';
import 'package:hungerz/Components/list_tile.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Routes/routes.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.account!,
              style: Theme.of(context).textTheme.bodyLarge),
          centerTitle: true,
        ),
        body: Account(),
      );
}

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String? number;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // late ThemeCubit _themeCubit;
    // _themeCubit = BlocProvider.of<ThemeCubit>(context);
    return ListView(
      children: <Widget>[
        UserDetails(),
        Divider(
          color: Theme.of(context).cardColor,
          thickness: 8.0,
        ),
        BuildListTile(
          small: true,
          image: 'images/account/ic_menu_wallet.png',
          text: AppLocalizations.of(context)!.wallet,
          onTap: () => Navigator.pushNamed(context, PageRoutes.wallet),
        ),
        AddressTile(),
        BuildListTile(
          small: true,
          image: 'images/account/ic_menu_favorite.png',
          text: AppLocalizations.of(context)!.fav,
          onTap: () =>
              Navigator.pushNamed(context, PageRoutes.favourite), // favourite
        ),
        BuildListTile(
            small: true,
            image: 'images/account/ic_menu_tncact.png',
            text: AppLocalizations.of(context)!.tnc,
            onTap: () => Navigator.pushNamed(context, PageRoutes.tncPage)),
        BuildListTile(
            small: true,
            image: 'images/account/ic_menu_supportact.png',
            text: AppLocalizations.of(context)!.support,
            onTap: () => Navigator.pushNamed(context, PageRoutes.supportPage,
                arguments: number)),
        BuildListTile(
          small: true,
          image: 'images/account/ic_menu_setting.png',
          text: AppLocalizations.of(context)!.settings,
          onTap: () => Navigator.pushNamed(context, PageRoutes.settings),
        ),
        LogoutTile(),
        // if (AppConfig.isDemoMode)
        //     BuyThisApp.button(
        //       AppConfig.appName,
        //       'https://dashboard.vtlabs.dev/projects/envato-referral-buy-link?project_slug=hungerz_flutter',
        //     ),
        //   if (AppConfig.isDemoMode)
        //     Divider(
        //       color: Theme.of(context).cardColor,
        //       thickness: 5.0,
        //     ),
        //   if (AppConfig.isDemoMode)
        //     _themeCubit.isDark
        //           ? BuyThisApp.developerRowOpusDark(
        //               Colors.transparent, Theme.of(context).primaryColorLight)
        //           : BuyThisApp.developerRowOpus(
        //               Colors.transparent, Theme.of(context).secondaryHeaderColor),
      ],
    );
  }
}

class AddressTile extends StatelessWidget {
  const AddressTile({super.key});

  @override
  Widget build(BuildContext context) => BuildListTile(
        small: true,
        image: 'images/account/ic_menu_addressact.png',
        text: AppLocalizations.of(context)!.saved,
        onTap: () =>
            Navigator.pushNamed(context, PageRoutes.savedAddressesPage),
      );
}

class LogoutTile extends StatelessWidget {
  const LogoutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BuildListTile(
      small: true,
      image: 'images/account/ic_menu_logoutact.png',
      text: AppLocalizations.of(context)!.logout,
      onTap: () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.loggingOut!),
          content: Text(AppLocalizations.of(context)!.areYouSure!),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: kTransparentColor)),
              ),
              child: Text(
                AppLocalizations.of(context)!.no!,
                style: TextStyle(
                  color: kMainColor,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: kTransparentColor)),
              ),
              onPressed: () => Phoenix.rebirth(context),
              child: Text(
                AppLocalizations.of(context)!.yes!,
                style: TextStyle(
                  color: kMainColor,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class UserDetails extends StatelessWidget {
  const UserDetails({super.key});
  
  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.read<AuthCubit>().state;
    String name="";
    String email="";
    String number="";
    if (authState is Authenticated) {
      number = authState.user.mobileNumber;
      email = authState.user.email!;
      name = authState.user.fullName!;
    } 
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('\n$name',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 20)),
          Text('\n$number',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Color(0xff9a9a9a))),
          SizedBox(
            height: 5.0,
          ),
          Text(email,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: Color(0xff9a9a9a))),
        ],
      ),
    );
  }
}
