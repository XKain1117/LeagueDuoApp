import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toMap(){
    return {
      "puuid": puuid,
      "id": summonerId,
      "name" : ign,
      "rank" : rank,
      "tier" : tier,
      "profileIcon" : profileIcon,
      "summonerLevel" : summonerLevel,
    };
  }
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

class AppAccount {
  final String? id;
  final String? accountName;
  final String? motd;
  final List<String>? currentChats;
  final List<Map<String, dynamic>>? acceptedAccounts;
  final List<Map<String, dynamic>>? declinedAccounts;
  final Map<String, dynamic> leagueAccount;

  const AppAccount({
    this.id = "",
    this.accountName = "",
    this.motd = "",
    this.currentChats = const [],
    this.acceptedAccounts = const [],
    this.declinedAccounts = const [],
    this.leagueAccount = const {},
  });

  Map<String, dynamic> toMap(){
    return {
      "id" : id,
      "accountName" : accountName,
      "motd" : motd,
      "currentChats" : currentChats,
      "acceptedAccounts" : acceptedAccounts,
      "declinedAccounts" : declinedAccounts,
      "leagueAccount" : leagueAccount,
    };
  }

  static AppAccount fromMap(Map<String, dynamic> json){
    return AppAccount(
      id: json['id'] as String?,
      accountName: json['accountName'] as String?,
      motd: json['motd'] as String?,
      currentChats: List<String>.from(json['currentChats'] ?? []),
      acceptedAccounts: List<Map<String, dynamic>>.from(json['acceptedAccounts'] ?? []),
      declinedAccounts: List<Map<String, dynamic>>.from(json['declinedAccounts'] ?? []),
      leagueAccount: json['leagueAccount'] as Map<String, dynamic>,
    );
  }
}


Future<LeagueAccount> fetchLeagueAccount(String name) async{
  Config c = Config();
  String result = name.replaceAll(" ", "%20");
  final initial_response = await http.get(Uri.parse('https://na1.api.riotgames.com/lol/summoner/v4/summoners/by-name/${result}?api_key=${c.key}'));
  final initial = jsonDecode(initial_response.body);
  final second_response = await http.get(Uri.parse('https://na1.api.riotgames.com/lol/league/v4/entries/by-summoner/${initial["id"]}?api_key=${c.key}'));
  final second = jsonDecode(second_response.body);

  LeagueAccount acc = LeagueAccount(puuid:initial["puuid"], summonerId: initial["id"], ign: initial["name"], 
    summonerLevel: initial["summonerLevel"], rank:second[0]["rank"], tier:second[0]["tier"], profileIcon:initial["profileIconId"]);
  if (initial_response.statusCode == 200) {
    return acc;
  } else {
    throw Exception('Failed to load account');
  }
}


Future<bool> checkAppAccount(String id) async{
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentReference documentReference = firestore.collection('Accounts').doc(id);
  DocumentSnapshot snapshot = await documentReference.get();

  if(snapshot.exists){
    return true;
  }else{
    return false;
  }
}


Future<AppAccount> getAppAccount(String id, [String? name, String? IGN]) async{
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference documentReference = firestore.collection('Accounts').doc(id);
    DocumentSnapshot snapshot = await documentReference.get();

    if(snapshot.exists){
      print("exsits");
      AppAccount ap = AppAccount.fromMap(snapshot.data() as Map<String, dynamic>);
      return ap;
    }else{
      if (name == null) {
        throw Exception("Name cannot be null.");
      }
      if (IGN == null) {
        throw Exception("IGN cannot be null.");
      }
      LeagueAccount la = await fetchLeagueAccount(IGN);
      return AppAccount(id: id, accountName: name, leagueAccount: la.toMap());
    }
}
