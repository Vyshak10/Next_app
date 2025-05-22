

import 'package:flutter/material.dart';
import 'package:next_app/common/color_extension.dart';
import 'package:next_app/view/login/user_type.dart';

class Onboardingpage extends StatefulWidget {
  const Onboardingpage({super.key});

  @override
  State<Onboardingpage> createState() => _OnboardingpageState();
}

class _OnboardingpageState extends State<Onboardingpage> {

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String,String>> onboardingData = [{
    'title': 'Find Your Dream Job',
    'description': 'Discover opportunities that match your skills and career goals.',
    'icon': 'search',
  },
    {
      'title': 'Connect with Top Companies',
      'description': 'Build relationships with leading companies and startups in your industry.',
      'icon': 'users',
    },
    {
      'title': 'Grow Your Team',
      'description': 'For companies, find exceptional talent to help your business thrive.',
      'icon': 'briefcase',
    },
  ];
   //handles next
   void handlenext(){
    if( _currentIndex < onboardingData.length - 1){
      _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut
      );
    }
    else{
      handleFinish();
    }
  }
  //handles skip
  void handleSkip(){
     handleFinish();
  }
  //handles route to the userr type page
  void handleFinish() {
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (context) => const UserType()),
    );
  }

  Widget renderIcon(String icon){
     IconData selectedIcon;
     switch(icon){
       case 'search':
         selectedIcon = Icons.search;
         break;
       case 'users':
         selectedIcon = Icons.people;
         break;
       case 'breifcase':
         selectedIcon = Icons.work;
         break;
       default:
         selectedIcon = Icons.circle;
     }
     return Icon(selectedIcon,size:60,
       color:Colors.blue,);
  }
  Widget buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(onboardingData.length, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.white,
      body: SafeArea(
          child:Column(
            children: [

              Padding(
                padding:EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16 ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(onPressed: handleSkip,
                        child: Text('Skip',style: TextStyle(color: Colors.blue),)
                    ),
                    Image.asset(
                      'assets/img/Icon.png',
                      height: 32,
                      width: 32,
                    ),
                  ],
                )
              ),

              Expanded(child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index){
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context,index){
                  final item = onboardingData[index];
                  return Padding(
                      padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Container(//container at center
                          width: size.width *0.7,
                          height: size.width * 0.7,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(opacity: 0.2,
                              child: Icon(Icons.workspaces_outline,size: 120),
                              ),

                              Container(//circle inside the container
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0,4),
                                    )
                                  ]
                                ),
                                child: Center(
                                  child: renderIcon(item['icon']!
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 32,
                        ),
                        Text(
                          item['title']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                            fontWeight:FontWeight.bold,
                          color: Colors.black
                        ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                            item['description']!,
                        textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            height: 1.5,
                          ),
                          )
                      ],
                    ),
                  );
                },
              )
              ),

              SizedBox(height: 24,),
              buildDots(),
              Padding(
                  padding: EdgeInsets.all(24),
                child:
                SizedBox(
                width: double.infinity,
                  child:ElevatedButton.icon(
                    onPressed: handlenext,
                    icon: Icon(
                      _currentIndex == onboardingData.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                      color: Colors.white,
                    ),
                    label: Text(
                      _currentIndex == onboardingData.length - 1
                          ? 'Get Started' : 'Next',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      ),
                    ),
                  )
                ),
            ],
          ),
      ),
    );
}
}
