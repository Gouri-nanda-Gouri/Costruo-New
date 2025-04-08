import 'package:costruo_worker/login.dart';
import 'package:costruo_worker/registration.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://beoujrcdcgnjhkzkwsut.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlb3VqcmNkY2duamhremt3c3V0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY4Mjc5MjAsImV4cCI6MjA1MjQwMzkyMH0.WTC61iUVromESiSaqgzN4w4MypTGlvyb3dvCCDXJNMQ',
  );

    runApp(const MainApp());
}
final supabase =  Supabase.instance.client;
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return   MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Login()
    );
  }
}
