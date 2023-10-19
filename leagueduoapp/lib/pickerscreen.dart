import 'package:flutter/material.dart';
import 'package:leagueduoapp/accountfetcher.dart';
import 'package:leagueduoapp/titlescreen.dart';



class PickerScreen extends StatefulWidget {
  const PickerScreen({super.key});
  @override
  State<PickerScreen> createState() => _PickerState();
}




class _PickerState extends State<PickerScreen>{
  late Future<LeagueAccount> account;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil<void>(
                context, 
                MaterialPageRoute<void>(builder: (BuildContext context) => const Titlescreen()), 
                (Route<dynamic> route) => false
              );
            },
            child: Container(
              height:100,
              width:300,
              color: Colors.green,
              child: const Text('Logout'),
            ),
          ),
          const SizedBox(height:20),
          ElevatedButton(
            onPressed: () {
              account = fetchLeagueAccount();
            },
            child: Container(
              height:100,
              width:300,
              color: Colors.green,
              child: const Text('Refresh'),
            ),
          ),
          FutureBuilder<LeagueAccount>(
              future: account,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          margin: const EdgeInsets.all(50),
                          color: Colors.green,
                          child: Column(
                            children: [
                              
                              Container(
                                alignment: Alignment.topCenter,
                                width: 100,
                                height: 100,
                                color: const Color.fromARGB(255, 35, 21, 196),
                                child: const SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.fill,
                                        child: Icon(
                                          Icons.accessible,
                                        )
                                      )
                                    )
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.amber[400],
                                    child: const SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.fill,
                                        child: Icon(
                                          Icons.account_box_rounded,
                                        )
                                      )
                                    )
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Text(
                                    snapshot.data!.ign,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      backgroundColor: Color.fromARGB(255, 121, 227, 117) 
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    color: const Color.fromARGB(255, 230, 20, 156),
                                    child: const SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.fill,
                                        child: Icon(
                                          Icons.anchor,
                                        )
                                      )
                                    )
                                  ),
                                  const SizedBox(height:20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${snapshot.data!.tier}  ${snapshot.data!.rank}",
                                        style: const TextStyle(
                                          backgroundColor: Color.fromARGB(255, 121, 227, 117),
                                          fontSize: 20,
                                        ),     
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            ]
                          ),
                        )
                      ],
                  );
                  
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                // By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            )
        ]
      ),
    );
    
  }
  @override
  void initState() {
    super.initState();
    account = fetchLeagueAccount();
  }
   @override
  void dispose() {
    super.dispose();
  }
}

