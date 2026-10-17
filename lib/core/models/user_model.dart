import 'relationship_mode.dart';

class UserModel {
  final String id;
  final String name;
  final String? partnerId;
  final String? partnerName;
  final String inviteCode;
  final bool isPaired;
  final DateTime relationshipStartDate;
  final RelationshipMode mode;
  final bool isPremium;
  final String myTimeZone;
  final String partnerTimeZone;
  final DateTime? nextReunionDate;
  final String? reunionLocation;
  final DateTime? lastThinkingOfYou;
  final String? lastThinkingSender;

  UserModel({
    required this.id,
    required this.name,
    this.partnerId,
    this.partnerName,
    required this.inviteCode,
    this.isPaired = false,
    required this.relationshipStartDate,
    this.mode = RelationshipMode.longDistance,
    this.isPremium = false,
    this.myTimeZone = 'Europe/Istanbul',
    this.partnerTimeZone = 'Europe/London',
    this.nextReunionDate,
    this.reunionLocation,
    this.lastThinkingOfYou,
    this.lastThinkingSender,
  });

  int get daysTogether {
    return DateTime.now().difference(relationshipStartDate).inDays;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? partnerId,
    String? partnerName,
    String? inviteCode,
    bool? isPaired,
    DateTime? relationshipStartDate,
    RelationshipMode? mode,
    bool? isPremium,
    String? myTimeZone,
    String? partnerTimeZone,
    DateTime? nextReunionDate,
    String? reunionLocation,
    DateTime? lastThinkingOfYou,
    String? lastThinkingSender,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      inviteCode: inviteCode ?? this.inviteCode,
      isPaired: isPaired ?? this.isPaired,
      relationshipStartDate: relationshipStartDate ?? this.relationshipStartDate,
      mode: mode ?? this.mode,
      isPremium: isPremium ?? this.isPremium,
      myTimeZone: myTimeZone ?? this.myTimeZone,
      partnerTimeZone: partnerTimeZone ?? this.partnerTimeZone,
      nextReunionDate: nextReunionDate ?? this.nextReunionDate,
      reunionLocation: reunionLocation ?? this.reunionLocation,
      lastThinkingOfYou: lastThinkingOfYou ?? this.lastThinkingOfYou,
      lastThinkingSender: lastThinkingSender ?? this.lastThinkingSender,
    );
  }
}
