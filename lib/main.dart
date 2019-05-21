import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FirestoreSlideshow(),
      ),
      theme: ThemeData.light(),
    );
  }
}

class FirestoreSlideshow extends StatefulWidget {
  createState() => FirestoreSlideshowState();
}

class FirestoreSlideshowState extends State<FirestoreSlideshow> {
  final PageController controller = PageController(viewportFraction: 0.8);
  final Firestore db = Firestore.instance;
  Stream slides;
  String activeTag = 'favourites';

  // Track current page
  int currentPage = 0;

  @override
  void initState() {
    _queryDb();

    // Set state when page changes
    controller.addListener(() {
      int next = controller.page.round();

      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: slides,
      initialData: [],
      builder: (context, AsyncSnapshot snap) {
        List slideList = snap.data.toList();
        return PageView.builder(
          controller: controller,
          itemCount: slideList.length + 1,
          itemBuilder: (context, int currentIndex) {
            if (currentIndex == 0) {
              return _buildTagPage();
            } else if (slideList.length >= currentIndex) {
              bool active = currentIndex == currentPage;
              return _buildStoryPage(slideList[currentIndex - 1], active);
            }
          },
        );
      },
    );
  }

  void _queryDb({String tag = 'favourites'}) {
    // Make a query
    Query query = db.collection('stories').where('tags', arrayContains: tag);
    slides =
        query.snapshots().map((list) => list.documents.map((doc) => doc.data));

    // Update active tag
    setState(() {
      activeTag = tag;
    });
  }

  _buildStoryPage(Map data, bool active) {
    final double blur = active ? 30 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 100 : 200;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(top: top, bottom: 50, right: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(data['img']),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black87,
              blurRadius: blur,
              offset: Offset(offset, offset))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            data['title'],
            style: TextStyle(fontSize: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  _buildTagPage() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Packages',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          Text(
            'FILTER',
            style: TextStyle(color: Colors.black26),
          ),
          _buildButton('favourites'),
          _buildButton('happy'),
          _buildButton('sad'),
        ],
      ),
    );
  }

  _buildButton(tag) {
    Color color = tag == activeTag ? Colors.purple : Colors.white;
    return FlatButton(
      color: color,
      child: Text('#$tag'),
      onPressed: () => _queryDb(tag: tag),
    );
  }
}
