import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:hungerz/Config/app_config.dart';
import 'dart:async';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String getLocalizationFor(String key) {
    return (AppConfig.languagesSupported[locale.languageCode]!.values[key] ?? (AppConfig
                .languagesSupported[AppConfig.languageDefault]!.values[key] ?? key));
  }

  String? get vegetableText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['vegetableText'];
  }

  String? get foodText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['foodText'];
  }

  String? get youreAlmostin {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['youreAlmostin'];
  }

  String? get meatText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['meatText'];
  }

  String? get medicineText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['medicineText'];
  }

  String? get petText {
    return AppConfig.languagesSupported[locale.languageCode]!.values['petText'];
  }

  String? get customText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['customText'];
  }

  String? get invalidNumber {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['invalidNumber'];
  }

  String? get networkError {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['networkError'];
  }

  String? get register {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['register'];
  }

  String? get invalidName {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['invalidName'];
  }

  String? get invalidEmail {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['invalidEmail'];
  }

  String? get invalidNameAndEmail {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['invalidNameAndEmail'];
  }

  String? get fullName {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['fullName'];
  }

  String? get emailAddress {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['emailAddress'];
  }

  String? get mobileNumber {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['mobileNumber'];
  }

  String? get verificationText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['verificationText'];
  }

  String? get verification {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['verification'];
  }

  String? get checkNetwork {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['checkNetwork'];
  }

  String? get invalidOTP {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['invalidOTP'];
  }

  String? get enterVerification {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['enterVerification'];
  }

  String? get verificationCode {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['verificationCode'];
  }

  String? get resend {
    return AppConfig.languagesSupported[locale.languageCode]!.values['resend'];
  }

  String? get offlineText {
    return AppConfig.languagesSupported[locale.languageCode]!.values['resend'];
  }

  String? get onlineText {
    return AppConfig.languagesSupported[locale.languageCode]!.values['resend'];
  }

  String? get goOnline {
    return AppConfig.languagesSupported[locale.languageCode]!.values['resend'];
  }

  String? get goOffline {
    return AppConfig.languagesSupported[locale.languageCode]!.values['resend'];
  }

  String? get orders {
    return AppConfig.languagesSupported[locale.languageCode]!.values['orders'];
  }

  String? get ride {
    return AppConfig.languagesSupported[locale.languageCode]!.values['ride'];
  }

  String? get earnings {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['earnings'];
  }

  String? get location {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['earnings'];
  }

  String? get grant {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['earnings'];
  }

  String? get homeText1 {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['homeText1'];
  }

  String? get homeText2 {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['homeText2'];
  }

  String? get bodyText1 {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['bodyText1'];
  }

  String? get bodyText2 {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['bodyText2'];
  }

  String? get mobileText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['mobileText'];
  }

  String? get continueText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['continueText'];
  }

  String? get homeText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['homeText'];
  }

  String? get money {
    return AppConfig.languagesSupported[locale.languageCode]!.values['money'];
  }

  String? get account {
    return AppConfig.languagesSupported[locale.languageCode]!.values['account'];
  }

  String? get orderText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['orderText'];
  }

  String? get tnc {
    return AppConfig.languagesSupported[locale.languageCode]!.values['tnc'];
  }

  String? get support {
    return AppConfig.languagesSupported[locale.languageCode]!.values['support'];
  }

  String? get aboutUs {
    return AppConfig.languagesSupported[locale.languageCode]!.values['aboutUs'];
  }

  String? get login {
    return AppConfig.languagesSupported[locale.languageCode]!.values['login'];
  }

  String? get noLoginText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['noLoginText'];
  }

  String? get logout {
    return AppConfig.languagesSupported[locale.languageCode]!.values['logout'];
  }

  String? get loggingOut {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['loggingOut'];
  }

  String? get areYouSure {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['areYouSure'];
  }

  String? get yes {
    return AppConfig.languagesSupported[locale.languageCode]!.values['yes'];
  }

  String? get no {
    return AppConfig.languagesSupported[locale.languageCode]!.values['no'];
  }

  String? get aboutDelivoo {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['aboutDelivoo'];
  }

  String? get saved {
    return AppConfig.languagesSupported[locale.languageCode]!.values['saved'];
  }

  String? get booked {
    return AppConfig.languagesSupported[locale.languageCode]!.values['booked'];
  }

  String? get thankstb {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['thankstb'];
  }

  String? get savedText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['savedText'];
  }

  String? get notLogin {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['notLogin'];
  }

  String? get loginText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['loginText'];
  }

  String? get ourVision {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['ourVision'];
  }

  String? get rebook {
    return AppConfig.languagesSupported[locale.languageCode]!.values['rebook'];
  }

  String? get cancel {
    return AppConfig.languagesSupported[locale.languageCode]!.values['cancel'];
  }

  String? get companyPolicy {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['companyPolicy'];
  }

  String? get booking {
    return AppConfig.languagesSupported[locale.languageCode]!.values['booking'];
  }

  String? get pe {
    return AppConfig.languagesSupported[locale.languageCode]!.values['pe'];
  }

  String? get per {
    return AppConfig.languagesSupported[locale.languageCode]!.values['per'];
  }

  String? get pers {
    return AppConfig.languagesSupported[locale.languageCode]!.values['pers'];
  }

  String? get termsOfUse {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['termsOfUse'];
  }

  String? get perso {
    return AppConfig.languagesSupported[locale.languageCode]!.values['perso'];
  }

  String? get date {
    return AppConfig.languagesSupported[locale.languageCode]!.values['date'];
  }

  String? get da {
    return AppConfig.languagesSupported[locale.languageCode]!.values['da'];
  }

  String? get dat {
    return AppConfig.languagesSupported[locale.languageCode]!.values['dat'];
  }

  String? get datee {
    return AppConfig.languagesSupported[locale.languageCode]!.values['datee'];
  }

  String? get dateee {
    return AppConfig.languagesSupported[locale.languageCode]!.values['dateee'];
  }

  String? get dateeee {
    return AppConfig.languagesSupported[locale.languageCode]!.values['dateeee'];
  }

  String? get person {
    return AppConfig.languagesSupported[locale.languageCode]!.values['person'];
  }

  String? get select {
    return AppConfig.languagesSupported[locale.languageCode]!.values['select'];
  }

  String? get pastt {
    return AppConfig.languagesSupported[locale.languageCode]!.values['pastt'];
  }

  String? get upcomming {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['upcomming'];
  }

  String? get message {
    return AppConfig.languagesSupported[locale.languageCode]!.values['message'];
  }

  String? get tabletext {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['tabletext'];
  }

  String? get enterMessage {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['enterMessage'];
  }

  String? get orWrite {
    return AppConfig.languagesSupported[locale.languageCode]!.values['orWrite'];
  }

  String? get yourWords {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['yourWords'];
  }

  String? get online {
    return AppConfig.languagesSupported[locale.languageCode]!.values['online'];
  }

  String? get recent {
    return AppConfig.languagesSupported[locale.languageCode]!.values['recent'];
  }

  String? get vegetable {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['vegetable'];
  }

  String? get upload {
    return AppConfig.languagesSupported[locale.languageCode]!.values['upload'];
  }

  String? get updateInfo {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['updateInfo'];
  }

  String? get instruction {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['instruction'];
  }

  String? get cod {
    return AppConfig.languagesSupported[locale.languageCode]!.values['cod'];
  }

  String? get backToHome {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['backToHome'];
  }

  String? get viewEarnings {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['viewEarnings'];
  }

  String? get yourEarnings {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['yourEarnings'];
  }

  String? get youDrived {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['youDrived'];
  }

  String? get viewOrderInfo {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['viewOrderInfo'];
  }

  String? get delivered {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['delivered'];
  }

  String? get thankYou {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['thankYou'];
  }

  String? get newDeliveryTask {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['newDeliveryTask'];
  }

  String? get orderInfo {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['orderInfo'];
  }

  String? get close {
    return AppConfig.languagesSupported[locale.languageCode]!.values['close'];
  }

  String? get direction {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['direction'];
  }

  String? get store {
    return AppConfig.languagesSupported[locale.languageCode]!.values['store'];
  }

  String? get markPicked {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['markPicked'];
  }

  String? get markDelivered {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['markDelivered'];
  }

  String? get acceptDelivery {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['acceptDelivery'];
  }

  String? get address {
    return AppConfig.languagesSupported[locale.languageCode]!.values['address'];
  }

  String? get storeAddress {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['storeAddress'];
  }

  String? get search {
    return AppConfig.languagesSupported[locale.languageCode]!.values['search'];
  }

  String? get sandwich {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['sandwich'];
  }

  String? get chicken {
    return AppConfig.languagesSupported[locale.languageCode]!.values['chicken'];
  }

  String? get juice {
    return AppConfig.languagesSupported[locale.languageCode]!.values['juice'];
  }

  String? get cheese {
    return AppConfig.languagesSupported[locale.languageCode]!.values['cheese'];
  }

  String? get apply {
    return AppConfig.languagesSupported[locale.languageCode]!.values['apply'];
  }

  String? get add {
    return AppConfig.languagesSupported[locale.languageCode]!.values['add'];
  }

  String? get viewCart {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['viewCart'];
  }

  String? get placed {
    return AppConfig.languagesSupported[locale.languageCode]!.values['placed'];
  }

  String? get thanks {
    return AppConfig.languagesSupported[locale.languageCode]!.values['thanks'];
  }

  String? get confirm {
    return AppConfig.languagesSupported[locale.languageCode]!.values['confirm'];
  }

  String? get selectPayment {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['selectPayment'];
  }

  String? get amount {
    return AppConfig.languagesSupported[locale.languageCode]!.values['amount'];
  }

  String? get card {
    return AppConfig.languagesSupported[locale.languageCode]!.values['card'];
  }

  String? get credit {
    return AppConfig.languagesSupported[locale.languageCode]!.values['credit'];
  }

  String? get debit {
    return AppConfig.languagesSupported[locale.languageCode]!.values['debit'];
  }

  String? get cash {
    return AppConfig.languagesSupported[locale.languageCode]!.values['cash'];
  }

  String? get other {
    return AppConfig.languagesSupported[locale.languageCode]!.values['other'];
  }

  String? get paypal {
    return AppConfig.languagesSupported[locale.languageCode]!.values['paypal'];
  }

  String? get payU {
    return AppConfig.languagesSupported[locale.languageCode]!.values['payU'];
  }

  String? get stripe {
    return AppConfig.languagesSupported[locale.languageCode]!.values['stripe'];
  }

  String? get setLocation {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['setLocation'];
  }

  String? get enterLocation {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['enterLocation'];
  }

  String? get saveAddress {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['saveAddress'];
  }

  String? get addressLabel {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['addressLabel'];
  }

  String? get office {
    return AppConfig.languagesSupported[locale.languageCode]!.values['office'];
  }

  String? get addNew {
    return AppConfig.languagesSupported[locale.languageCode]!.values['addNew'];
  }

  String? get submit {
    return AppConfig.languagesSupported[locale.languageCode]!.values['submit'];
  }

  String? get change {
    return AppConfig.languagesSupported[locale.languageCode]!.values['change'];
  }

  String? get pay {
    return AppConfig.languagesSupported[locale.languageCode]!.values['pay'];
  }

  String? get deliver {
    return AppConfig.languagesSupported[locale.languageCode]!.values['deliver'];
  }

  String? get service {
    return AppConfig.languagesSupported[locale.languageCode]!.values['service'];
  }

  String? get sub {
    return AppConfig.languagesSupported[locale.languageCode]!.values['sub'];
  }

  String? get paymentInfo {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['paymentInfo'];
  }

  String? get pickup {
    return AppConfig.languagesSupported[locale.languageCode]!.values['pickup'];
  }

  String? get process {
    return AppConfig.languagesSupported[locale.languageCode]!.values['process'];
  }

  String? get custom {
    return AppConfig.languagesSupported[locale.languageCode]!.values['custom'];
  }

  String? get storeFound {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['storeFound'];
  }

  String? get send {
    return AppConfig.languagesSupported[locale.languageCode]!.values['send'];
  }

  String? get pickupText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['pickupText'];
  }

  String? get pickupAddress {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['pickupAddress'];
  }

  String? get dropText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['dropText'];
  }

  String? get drop {
    return AppConfig.languagesSupported[locale.languageCode]!.values['drop'];
  }

  String? get packageText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['packageText'];
  }

  String? get package {
    return AppConfig.languagesSupported[locale.languageCode]!.values['package'];
  }

  String? get deliveryCharge {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['deliveryCharge'];
  }

  String? get done {
    return AppConfig.languagesSupported[locale.languageCode]!.values['done'];
  }

  String? get vegetables {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['vegetables'];
  }

  String? get fruits {
    return AppConfig.languagesSupported[locale.languageCode]!.values['fruits'];
  }

  String? get herbs {
    return AppConfig.languagesSupported[locale.languageCode]!.values['herbs'];
  }

  String? get dairy {
    return AppConfig.languagesSupported[locale.languageCode]!.values['dairy'];
  }

  String? get paperDocuments {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['paperDocuments'];
  }

  String? get flowersChocolates {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['flowersChocolates'];
  }

  String? get sports {
    return AppConfig.languagesSupported[locale.languageCode]!.values['sports'];
  }

  String? get clothes {
    return AppConfig.languagesSupported[locale.languageCode]!.values['clothes'];
  }

  String? get electronic {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['electronic'];
  }

  String? get household {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['household'];
  }

  String? get glass {
    return AppConfig.languagesSupported[locale.languageCode]!.values['glass'];
  }

  String? get or {
    return AppConfig.languagesSupported[locale.languageCode]!.values['or'];
  }

  String? get continueWith {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['continueWith'];
  }

  String? get facebook {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['facebook'];
  }

  String? get google {
    return AppConfig.languagesSupported[locale.languageCode]!.values['google'];
  }

  String? get apple {
    return AppConfig.languagesSupported[locale.languageCode]!.values['apple'];
  }

  String? get wallet {
    return AppConfig.languagesSupported[locale.languageCode]!.values['wallet'];
  }

  String? get settings {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['settings'];
  }

  String? get buyThisApp {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['buy_this_app'];
  }

  String? get availableBalance {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['availableBalance'];
  }

  String? get addMoney {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['addMoney'];
  }

  String? get accountHolderName {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['accountHolderName'];
  }

  String? get bankName {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['bankName'];
  }

  String? get branchCode {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['branchCode'];
  }

  String? get accountNumber {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['accountNumber'];
  }

  String? get enterAmountToTransfer {
    return AppConfig.languagesSupported[locale.languageCode]!
        .values['enterAmountToTransfer'];
  }

  String? get bankInfo {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['bankInfo'];
  }

  String? get display {
    return AppConfig.languagesSupported[locale.languageCode]!.values['display'];
  }

  String? get darkMode {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['darkMode'];
  }

  String? get darkText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['darkText'];
  }

  String? get selectLanguage {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['language'];
  }

  String? get name1 {
    return AppConfig.languagesSupported[locale.languageCode]!.values['name1'];
  }

  String? get name2 {
    return AppConfig.languagesSupported[locale.languageCode]!.values['name2'];
  }

  String? get name3 {
    return AppConfig.languagesSupported[locale.languageCode]!.values['name3'];
  }

  String? get name4 {
    return AppConfig.languagesSupported[locale.languageCode]!.values['name4'];
  }

  String? get name5 {
    return AppConfig.languagesSupported[locale.languageCode]!.values['name5'];
  }

  String? get content1 {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['content1'];
  }

  String? get content2 {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['content2'];
  }

  String? get past {
    return AppConfig.languagesSupported[locale.languageCode]!.values['past'];
  }

  String? get rate {
    return AppConfig.languagesSupported[locale.languageCode]!.values['rate'];
  }

  String? get deliv {
    return AppConfig.languagesSupported[locale.languageCode]!.values['deliv'];
  }

  String? get how {
    return AppConfig.languagesSupported[locale.languageCode]!.values['how'];
  }

  String? get withR {
    return AppConfig.languagesSupported[locale.languageCode]!.values['withR'];
  }

  String? get addReview {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['addReview'];
  }

  String? get writeReview {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['writeReview'];
  }

  String? get feedback {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['feedback'];
  }

  String? get hey {
    return AppConfig.languagesSupported[locale.languageCode]!.values['hey'];
  }

  String? get lightText {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['lightText'];
  }

  String? get lightMode {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['lightMode'];
  }

//
  String? get fav {
    return AppConfig.languagesSupported[locale.languageCode]!.values['fav'];
  }

  String? get enterAmountToAdd {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['enterAmountToAdd'];
  }

  String? get addVia {
    return AppConfig.languagesSupported[locale.languageCode]!.values['addVia'];
  }

  String? get type {
    return AppConfig.languagesSupported[locale.languageCode]!.values['type'];
  }

  String? get quick {
    return AppConfig.languagesSupported[locale.languageCode]!.values['quick'];
  }

  String? get best {
    return AppConfig.languagesSupported[locale.languageCode]!.values['best'];
  }

  String? get offer {
    return AppConfig.languagesSupported[locale.languageCode]!.values['offer'];
  }

  String? get burger {
    return AppConfig.languagesSupported[locale.languageCode]!.values['burger'];
  }

  String? get pizza {
    return AppConfig.languagesSupported[locale.languageCode]!.values['pizza'];
  }

  String? get frankie {
    return AppConfig.languagesSupported[locale.languageCode]!.values['frankie'];
  }

  String? get csandwich {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['csandwich'];
  }

  String? get stater {
    return AppConfig.languagesSupported[locale.languageCode]!.values['stater'];
  }

  String? get mainCourse {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['mainCourse'];
  }

  String? get customize {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['customize'];
  }

  String? get veg {
    return AppConfig.languagesSupported[locale.languageCode]!.values['veg'];
  }

  String? get nonVeg {
    return AppConfig.languagesSupported[locale.languageCode]!.values['nonVeg'];
  }

  String? get buy {
    return AppConfig.languagesSupported[locale.languageCode]!.values['buy'];
  }

  String? get buy1 {
    return AppConfig.languagesSupported[locale.languageCode]!.values['buy1'];
  }

  String? get seeAll {
    return AppConfig.languagesSupported[locale.languageCode]!.values['seeAll'];
  }

  String? get nearyou {
    return AppConfig.languagesSupported[locale.languageCode]!.values['nearyou'];
  }

  String? get fast {
    return AppConfig.languagesSupported[locale.languageCode]!.values['fast'];
  }

  String? get sea {
    return AppConfig.languagesSupported[locale.languageCode]!.values['sea'];
  }

  String? get chinese {
    return AppConfig.languagesSupported[locale.languageCode]!.values['chinese'];
  }

  String? get desert {
    return AppConfig.languagesSupported[locale.languageCode]!.values['desert'];
  }

  String? get storee {
    return AppConfig.languagesSupported[locale.languageCode]!.values['storee'];
  }

  String? get jesica {
    return AppConfig.languagesSupported[locale.languageCode]!.values['jesica'];
  }

  String? get fish {
    return AppConfig.languagesSupported[locale.languageCode]!.values['fish'];
  }

  String? get seven {
    return AppConfig.languagesSupported[locale.languageCode]!.values['seven'];
  }

  String? get operum {
    return AppConfig.languagesSupported[locale.languageCode]!.values['operum'];
  }

  String? get orderTextt {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['orderTextt'];
  }

  String? get englishh {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['englishh'];
  }

  String? get arabicc {
    return AppConfig.languagesSupported[locale.languageCode]!.values['arabicc'];
  }

  String? get frenchh {
    return AppConfig.languagesSupported[locale.languageCode]!.values['frenchh'];
  }

  String? get indonesiann {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['indonesiann'];
  }

  String? get portuguesee {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['portuguesee'];
  }

  String? get spanishh {
    return AppConfig
        .languagesSupported[locale.languageCode]!.values['spanishh'];
  }

  static List<Locale> getSupportedLocales() {
    List<Locale> toReturn = [];
    for (String langCode in AppConfig.languagesSupported.keys) {
      toReturn.add(Locale(langCode));
    }
    return toReturn;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppConfig.languagesSupported.keys.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    // Returning a SynchronousFuture here because an async "load" operation
    // isn't needed to produce an instance of AppLocalizations.
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
