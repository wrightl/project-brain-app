// lib/pages/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _favoriteColor = '';
  DateTime? _doB;

  final TextEditingController _dobController = TextEditingController();

  // DateTime? _selectedDate;

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _doB ?? DateTime(now.year - 18), // default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _doB = picked;
        _dobController.text =
            picked.toIso8601String().substring(0, 10); // yyyy-MM-dd
      });
    }
  }

  // void _submit() {
  //   if (_formKey.currentState!.validate()) {
  //     final data = {
  //       'dateOfBirth': _dobController.text,
  //       // add other onboarding fields here...
  //     };
  //     widget.onSubmit(data);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Welcome ${authProvider.profile?.name}!',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'Please complete your profile.',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                onSaved: (val) => _fullName = val ?? '',
                initialValue: authProvider.profile?.name ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Favorite Color'),
                onSaved: (val) => _favoriteColor = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pickDate,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select your date of birth'
                    : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    authProvider.completeOnboarding({
                      'email': authProvider.profile?.email,
                      'fullName': _fullName,
                      'doB': _dobController.text,
                      'favoriteColor': _favoriteColor,
                    }).then((_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Onboarding complete!')),
                      );
                      Navigator.pop(context);
                    }).catchError((error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $error')),
                      );
                    });
                  }
                },
                child: const Text('Complete Onboarding'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
