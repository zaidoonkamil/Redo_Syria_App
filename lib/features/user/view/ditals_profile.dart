import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/styles/themes.dart';
import '../../../core/widgets/app_bar.dart';
import '../model/ProfileModel.dart';

class DetailsProfile extends StatelessWidget {
  final ProfileModel profile;

  const DetailsProfile({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                CustomAppBarBack(),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: _userProfileHeader(
                    name: profile.name,
                    phone: profile.phone,
                    role: profile.role,
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // _chip(
                          //   text: profile.isActive ? "نشط" : "محظور",
                          //   bg: profile.isActive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                          //   fg: profile.isActive ? Colors.green : Colors.red,
                          // ),
                          // const SizedBox(width: 8),
                          // _chip(
                          //   text: profile.isVerified ? "موثّق" : "غير موثّق",
                          //   bg: profile.isVerified ? Colors.blue.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                          //   fg: profile.isVerified ? Colors.blue : Colors.orange,
                          // ),
                          const SizedBox(width: 8),
                          _chip(
                            text: profile.role,
                            bg: Colors.blueGrey.withOpacity(0.12),
                            fg: Colors.blueGrey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildSettingsItem(
                        title: "الاسم",
                        subtitle: profile.name,
                        icon: Iconsax.user,
                      ),
                      _buildSettingsItem(
                        title: "الهاتف",
                        subtitle: profile.phone,
                        icon: Iconsax.call,
                      ),
                      // _buildSettingsItem(
                      //   title: "التوثيق",
                      //   subtitle: profile.isVerified ? "موثّق" : "غير موثّق",
                      //   icon: Icons.verified_outlined,
                      // ),
                      // _buildSettingsItem(
                      //   title: "الحساب",
                      //   subtitle: profile.isActive ? "نشط" : "محظور",
                      //   icon: profile.isActive ? Icons.check_circle_outline : Icons.block_outlined,
                      // ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _userProfileHeader({
    required String name,
    required String phone,
    required String role,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [secondPrimaryColor, Color(0xff2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person, size: 28, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String text, required Color bg, required Color fg}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // نفس شكل Settings item اللي عندك بالـ Profile
  Widget _buildSettingsItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.grey[600]),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 220,
                      child: Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: secondPrimaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: secondPrimaryColor.withOpacity(0.22)),
                  ),
                  child: Icon(icon, color: secondPrimaryColor, size: 22),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(width: double.infinity, height: 1.2, color: Colors.grey[200]),
        const SizedBox(height: 14),
      ],
    );
  }

}
