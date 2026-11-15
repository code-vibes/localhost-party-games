enum PlayMode {
  solo,
  duo,
  trio,
  quad,
  team2v2,
  party,
}

extension PlayModeX on PlayMode {
  int get playerCount => switch (this) {
        PlayMode.solo => 1,
        PlayMode.duo => 2,
        PlayMode.trio => 3,
        PlayMode.quad => 4,
        PlayMode.team2v2 => 4,
        PlayMode.party => 4,
      };

  String get label => switch (this) {
        PlayMode.solo => 'SOLO',
        PlayMode.duo => 'DUO',
        PlayMode.trio => 'TRIO',
        PlayMode.quad => 'SQUAD',
        PlayMode.team2v2 => '2v2 TEAM',
        PlayMode.party => 'PARTY MIX',
      };

  String get subtitle => switch (this) {
        PlayMode.solo => 'Practice & chill',
        PlayMode.duo => 'Pass-and-play',
        PlayMode.trio => 'Three-way turns',
        PlayMode.quad => 'Four on one phone',
        PlayMode.team2v2 => 'Red vs blue squads',
        PlayMode.party => 'Curated chaos picks',
      };

  bool get isTeam => this == PlayMode.team2v2;
  bool get isParty => this == PlayMode.party;
}