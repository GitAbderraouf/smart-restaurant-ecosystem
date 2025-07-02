import 'package:equatable/equatable.dart';

class WalletTransactionModel extends Equatable {
  final double amount; // Requis
  final String type; // Requis, Enum: "credit", "debit"
  final String description; // Requis
  final DateTime? date;

  const WalletTransactionModel({
    required this.amount,
    required this.type,
    required this.description,
    this.date,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      amount: (json['amount'] as num).toDouble(), // Requis
      type: json['type'] as String, // Requis
      description: json['description'] as String, // Requis
      date: json['date'] == null ? null : DateTime.tryParse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type,
      'description': description,
      'date': date?.toIso8601String(),
    };
  }

  WalletTransactionModel copyWith({
    double? amount,
    String? type,
    String? description,
    DateTime? date,
  }) {
    return WalletTransactionModel(
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }


  @override
  List<Object?> get props => [amount, type, description, date];
}