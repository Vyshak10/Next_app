

import 'package:flutter/material.dart';
import 'package:next_app/common_widget/role_option_card.dart';
import 'package:next_app/view/login/login_view.dart';

import '../../common/color_extension.dart';



class UserType extends StatefulWidget {
  const UserType({super.key});

  @override
  State<UserType> createState() => _UserTypeState();
}

class _UserTypeState extends State<UserType> {


  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated = false; // Replace with your real auth logic

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
          child: SingleChildScrollView(// Ensures the entire content scrolls when needed.
              padding: EdgeInsets.all(24),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //logo N.E.X.T
                  Center(
                      child:Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/img/Icon.png',
                            height: 70,
                            width:70,),
                          SizedBox(width: 15,),
                          Text('N.E.X.T',
                              style:TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0066CC),
                              )
                          ),
                        ],
                      )
                  ),

                  SizedBox(height: 30,),

                  Text('I am a...',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold
                    ),
                  ),

                  SizedBox(height: 8,),

                  Text('Select your role to get started',
                    style: TextStyle(
                      fontSize: 18,
                      color: TColor.gray,
                    ),
                  ),

                  const SizedBox(height: 32,),

                  RoleOptionCard(
                    title: 'Established Company',
                    description: 'Looking to hire talent and grow your team',
                    icon: Icons.business_center,
                    iconColor: Colors.deepOrange,
                    features: const [
                      'Looking to hire talent and grow your team'
                          'Browse candidate profiles',
                      'Manage applications',
                      'Track progress',
                    ],

                    onTap: () {
                      Navigator.pushNamed(context, '/signup',
                          arguments:{'userType':'Established Company'});
                    },
                  ),


                  RoleOptionCard(
                    title: 'Startup',
                    description: 'Looking to build your founding team and grow fast',
                    icon:  Icons.rocket_launch,
                    iconColor:  Color(0xFFE97451),
                    features: const [
                      'Find co-founders and early employees',
                      'Connect with investors and mentors',
                      'Access resources for early-stage growth',
                    ],
                    onTap: (){
                      Navigator.pushNamed(context, '/signup',
                          arguments:{'userType':'Startup'});
                    },
                  ),

                  RoleOptionCard(
                    title:'Job Seeker',
                    description: 'Looking for job opportunities and connections',
                    icon: Icons.person,
                    iconColor:  const Color(0xFF0066CC),
                    features: const [
                      'Discover job opportunities',
                      'Connect with companies',
                      'Showcase your skills and experience',
                    ],

                    onTap: (){
                      Navigator.pushNamed(context, '/signup',
                          arguments:{'userType':'Job Seeker'});
                    },

                  ),

                  SizedBox(height:10,),

                ],
              )

          )
      ),


    );
  }
}
