import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'package:table_calendar/table_calendar.dart';
import 'package:tswcd/Pages/EcentPage.dart';

import '../main.dart';

class EventList extends StatefulWidget {
  @override
  _EventListState createState() => _EventListState();
}

class _EventListState extends State<EventList> {
  List<String> _categories = ['IT', 'study', 'charity', 'sport', 'culture'];
  List<String> _selectedCategories = [];
  final databaseReference = FirebaseDatabase.instance.reference().child('events');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  DateTime? _selectedDay;
  Map<String, List<IconData>> categoryIcons = {
    'it': [Icons.computer, Icons.desktop_mac, Icons.router],
    'study': [Icons.menu_book, Icons.school, Icons.library_books],
    'charity': [Icons.favorite, Icons.volunteer_activism, Icons.favorite_border],
    'sport': [Icons.sports_soccer, Icons.sports_basketball, Icons.sports_baseball],
    'culture': [Icons.palette, Icons.theater_comedy, Icons.music_note],
  };
  IconData getIconForCategory(String category) {
    if (categoryIcons.containsKey(category)) {
      List<IconData> icons = categoryIcons[category]!;
      return icons[Random().nextInt(icons.length)];
    } else {
      return Icons.event;
    }
  }
  List<List<String>> setsOfCategories = [
    ['IT', 'study', 'charity'],
    ['sport', 'culture'], // Example of a second set of categories
    // ... potentially more sets
  ];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to log out the user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // You can add any additional cleanup or navigation logic here
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('NEskuchnoAta'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState!.openEndDrawer();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: StreamBuilder<DatabaseEvent>(
          stream: databaseReference.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              DataSnapshot dataValues = snapshot.data!.snapshot;
              if (dataValues.value != null) {
                List<dynamic> events = [];
                dynamic data = dataValues.value;
                if (data is List) {
                  events.addAll(data);
                } else if (data is Map) {
                  data.forEach((key, value) {
                    events.add(value);
                  });
                }

                events = events.where((event) {
                  DateTime eventDate = DateTime.parse(event['date']);
                  return (_selectedCategories.isEmpty || _selectedCategories.contains(event['type'])) &&
                      (_selectedDay == null ||
                          (eventDate.isAfter(_selectedDay!.subtract(Duration(days: 1))) &&
                              eventDate.isBefore(_selectedDay!.add(Duration(days: 1)))));
                }).toList();

                final double screenWidth = MediaQuery.of(context).size.width;
                final double screenHeight = MediaQuery.of(context).size.height;
                int crossAxisCount = 2;
                if (screenWidth>screenHeight) {
                  crossAxisCount = 4;
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1,
                  ),
                  itemCount: events.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EventDetailsPage(
                              startDate: events[index]['date'],
                              endDate: events[index]['end_date'],
                              title: events[index]['title'],
                              type: events[index]['type'],
                              smallDescription: events[index]['small_description'],
                              largeDescription: events[index]['full_description'])),
                        );
                      },

                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Icon(
                                  getIconForCategory(events[index]['type']),
                                  size: 64,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                events[index]['title'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8.0),
                              Text(events[index]['small_description']),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else {
                return Center(child: Text('Данные не найдены'));
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
      endDrawer: Drawer(
        child: Column(
          children: <Widget>[
            SizedBox(height: 15,),

            TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: DateTime.now().subtract(Duration(
                  hours: DateTime.now().hour,
                  minutes: DateTime.now().minute,
                  seconds: DateTime.now().second)),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
              },
            ),
            SizedBox(height: 5,),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 16,end: 16),
              child: Divider(
                thickness: 0.5,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 5,),
            Padding(padding: EdgeInsetsDirectional.only(start: 16),
            child: Text(
              'Фильтры:',
              softWrap: true,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black,fontFamily: 'Futura'),
            ),),
            SizedBox(height: 10,),
            ...setsOfCategories.map((set) => Wrap(
              spacing: 8.0, // Horizontal spacing between chips
              runSpacing: 16.0, // Vertical spacing between lines of chips
              children: set.map((category) => FilterChip(
                label: Text(category),
                selected: _selectedCategories.contains(category),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.removeWhere((String name) => name == category);
                    }
                  });
                },
              )).toList(),
            )).toList(),
            SizedBox(height: 5,),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 16,end: 16),
              child: Divider(
                thickness: 0.5,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 20,end: 20),
              child: ElevatedButton(onPressed: (){}, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Создать событие',
                    style: TextStyle(
                      fontWeight: FontWeight.w100,
                      fontFamily: 'Futura',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),),
            ),
            SizedBox(height: 15,),
            Row(
              children: [
                SizedBox(width: 16,),
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 6,),
                Text('ОПАСНАЯ ЗОНА',style: TextStyle(color: Colors.red),),
                SizedBox(width: 6,),
                Expanded(
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 16,),
              ],
            ),
            SizedBox(height: 16,),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 20,end: 20),
              child: ElevatedButton(onPressed:
                  (){
                    signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MyHomePage()),
                    );
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red
                ),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Выйти с аккаунта',
                    style: TextStyle(
                      fontWeight: FontWeight.w100,
                      fontFamily: 'Futura',
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),),
            ),

          ],
        ),
      ),
    );
  }
}
