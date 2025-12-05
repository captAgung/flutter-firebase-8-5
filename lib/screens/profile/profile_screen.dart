import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _nameController = TextEditingController(text: authService.currentUser?.displayName);
    _bioController = TextEditingController(text: authService.currentUser?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserProfile(
        displayName: _nameController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout gagal: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text('Semua data akun akan dihapus. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (!mounted) return;
        final TextEditingController pwController = TextEditingController();
        final reauth = await showDialog<bool?>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Masukkan Kata Sandi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Untuk keamanan, masukkan kata sandi Anda untuk mengkonfirmasi penghapusan akun.'),
                const SizedBox(height: 12),
                TextField(
                  controller: pwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Konfirmasi', style: TextStyle(color: Colors.red))),
            ],
          ),
        );

        if (reauth == true) {
          if (!mounted) return;
          final pwd = pwController.text;
          try {
            await authService.reauthenticateWithPassword(pwd);
            if (!mounted) return;
            await authService.deleteAccount();
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed('/login');
          } catch (e2) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal re-auth atau menghapus akun: $e2')));
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus akun: ${e.message ?? e.toString()}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus akun: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold();
        }
        final user = authService.currentUser;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display name
                  Text(
                    user?.displayName ?? 'Pengguna',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  // Edit profile section
                  if (_isEditing)
                    Column(
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'Nama Lengkap',
                          validator: Validators.validateName,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _bioController,
                          label: 'Bio',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Text('Simpan', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _isEditing = false),
                                child: const Text('Batal'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildInfoCard('Email', user?.email ?? '-'),
                        const SizedBox(height: 12),
                        _buildInfoCard('Bergabung', 
                          '${user?.createdAt.day ?? 0}/${user?.createdAt.month ?? 0}/${user?.createdAt.year ?? 0}'),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _isEditing = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Edit Profil', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Delete account
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _deleteAccount(),
                      child: const Text('Hapus Akun', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
