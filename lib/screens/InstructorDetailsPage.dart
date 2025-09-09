import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InstructorDetailsPage extends StatefulWidget {
  const InstructorDetailsPage({super.key});

  @override
  State<InstructorDetailsPage> createState() => _InstructorDetailsPageState();
}

class _InstructorDetailsPageState extends State<InstructorDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Instructor")),
      body: Text("data"),
    );
  }
}
