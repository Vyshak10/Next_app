import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AppBar(
                title: Text('Profile'),
                leading: Icon(Icons.person_2),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Logout logic here
                    },
                    child: Text('Logout'),
                  ),
                ],
              ),



              Padding(padding: EdgeInsets.all(24),
                child:Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 50,
                        ),

                        SizedBox(width: 40,),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Name',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                              ),
                            ),

                            Text('Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              )
                            )
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 30,),

                    Text('Posts',
                      style:TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),
                    ) ,


                    SizedBox(height: 20,),


                  ]
                ),
              )
            ],
          )
        ),
      ),
    );
  }
}
