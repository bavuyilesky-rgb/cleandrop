import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class ProfileAndSettingsTab extends StatefulWidget {
  final String userName;
  final String userPhone;
  final String streetAddress;
  final String suburbCity;
  final VoidCallback onRefreshGps;
  final void Function(String name, String phone, String address)
  onUpdateProfile;

  const ProfileAndSettingsTab({
    super.key,
    required this.userName,
    required this.userPhone,
    required this.streetAddress,
    required this.suburbCity,
    required this.onRefreshGps,
    required this.onUpdateProfile,
  });

  @override
  State<ProfileAndSettingsTab> createState() => _ProfileAndSettingsTabState();
}

class _ProfileAndSettingsTabState extends State<ProfileAndSettingsTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addrCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.userName);
    _phoneCtrl = TextEditingController(text: widget.userPhone);
    _addrCtrl = TextEditingController(text: widget.streetAddress);
  }

  Future<void> _saveProfileChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
      }, SetOptions(merge: true));
    }
    widget.onUpdateProfile(
      _nameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      _addrCtrl.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile & phone number saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeModeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.deepEmerald,
                ),
                title: const Text('Dark Theme',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                value: isDark,
                onChanged: (val) {
                  setState(() {
                    themeModeNotifier.value =
                    val ? ThemeMode.dark : ThemeMode.light;
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_iphone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addrCtrl,
                      decoration: InputDecoration(
                        labelText: 'Live GPS Street Address',
                        prefixIcon: const Icon(Icons.my_location),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.gps_fixed),
                          onPressed: widget.onRefreshGps,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkNavy,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saveProfileChanges,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}