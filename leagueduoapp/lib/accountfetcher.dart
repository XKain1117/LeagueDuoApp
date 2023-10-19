import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:leagueduoapp/config.dart';


class LeagueAccount {
  final String puuid;
  final String summonerId;
  final String ign;
  final String rank;
  final String tier;
  final int profileIcon;
  final int summonerLevel;

  const LeagueAccount({
    this.puuid = "",
    this.summonerId = "",
    this.ign = "",
    this.rank = "",
    this.tier = "",
    this.profileIcon = 0,
    this.summonerLevel = 0,
  });
  factory LeagueAccount.fromJson(Map<String, dynamic> json) {
    return LeagueAccount(
      puuid: json['puuid'],
      summonerId: json['id'],
      ign: json['name'],
      rank: json['rank'],
      tier: json['tier'],
      profileIcon: json['profileIcon'],
      summonerLevel: json['summonerLevel'],
    );
  }

}

Future<LeagueAccount> fetchLeagueAccount() async{
  Config c = Config();
  final initial_response = await http.get(Uri.parse('https://na1.api.riotgames.com/lol/summoner/v4/summoners/by-name/High%20Lord%20Xenith?api_key=${c.key}'));
  final initial = jsonDecode(initial_response.body);
  final second_response = await http.get(Uri.parse('https://na1.api.riotgames.com/lol/league/v4/entries/by-summoner/${initial["id"]}?api_key=${c.key}'));
  final second = jsonDecode(second_response.body);

  LeagueAccount acc = LeagueAccount(puuid:initial["puuid"], summonerId: initial["id"], profileIcon: initial["profileIconId"], 
    ign: initial["name"], summonerLevel: initial["summonerLevel"], rank:second[0]["rank"], tier:second[0]["tier"]);
  if (initial_response.statusCode == 200) {
    return acc;
  } else {
    throw Exception('Failed to load account');
  }
}
