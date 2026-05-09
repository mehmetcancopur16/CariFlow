import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../providers/clients_provider.dart';
import '../../../transactions/presentation/providers/dashboard_provider.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _taxIdController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _composedNotes() {
    final lines = <String>[];
    final cp = _contactPersonController.text.trim();
    final tax = _taxIdController.text.trim();
    final web = _websiteController.text.trim();
    if (cp.isNotEmpty) lines.add('Yetkili: $cp');
    if (tax.isNotEmpty) lines.add('Vergi/TC: $tax');
    if (web.isNotEmpty) lines.add('Web: $web');
    final free = _notesController.text.trim();
    if (free.isNotEmpty) lines.add(free);
    return lines.join('\n');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final composedNotes = _composedNotes();
    if (composedNotes.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notlar (ticari + serbest) toplam 2000 karakteri gecemez',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{'name': _nameController.text.trim()};
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final address = _addressController.text.trim();
      if (phone.isNotEmpty) payload['phone'] = phone;
      if (email.isNotEmpty) payload['email'] = email;
      if (address.isNotEmpty) payload['address'] = address;
      if (composedNotes.isNotEmpty) payload['notes'] = composedNotes;

      await ref.read(clientsNotifierProvider.notifier).addClient(payload);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Musteri basariyla kaydedildi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/clients');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiErrorMapper.toMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withAlpha(32),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textColor.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldCard({required List<Widget> children}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(252),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryColor.withAlpha(22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withAlpha(26),
              AppColors.backgroundColor,
              AppColors.successColor.withAlpha(16),
            ],
          ),
        ),
        child: SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.97, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => context.go('/clients'),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Geri',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Yeni musteri karti',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    'Zorunlu alan: ad. Digerleri opsiyonel; backend ile tam uyumludur.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textColor.withAlpha(150),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _sectionHeader(
                                icon: Icons.contact_mail_rounded,
                                title: 'Temel bilgiler',
                                subtitle:
                                    'Musteriyi tanıyacak ad, telefon ve e-posta. '
                                    'E-posta girerseniz gecerli formatta olmalidir.',
                                accent: AppColors.primaryColor,
                              ),
                              const SizedBox(height: 14),
                              _fieldCard(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Ad / unvan *',
                                      hintText: 'Ornek: ABC Ticaret Ltd.',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.badge_rounded),
                                    ),
                                    validator: (v) {
                                      if ((v ?? '').trim().isEmpty) {
                                        return 'Ad zorunludur';
                                      }
                                      if (v!.trim().length < 2) {
                                        return 'En az 2 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d+\s\-().]'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Telefon',
                                      hintText: '+90 5xx xxx xx xx',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(
                                        Icons.phone_android_rounded,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Uluslararasi veya yerel format kullanabilirsiniz.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textColor.withAlpha(130),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'E-posta',
                                      hintText: 'ornek@sirket.com',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                    validator: (v) {
                                      final t = (v ?? '').trim();
                                      if (t.isEmpty) return null;
                                      if (!_emailRegex.hasMatch(t)) {
                                        return 'Gecerli bir e-posta girin';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _sectionHeader(
                                icon: Icons.location_on_rounded,
                                title: 'Adres',
                                subtitle:
                                    'Fatura veya teslimat icin kullanabileceginiz acik adres.',
                                accent: AppColors.successColor,
                              ),
                              const SizedBox(height: 14),
                              _fieldCard(
                                children: [
                                  TextFormField(
                                    controller: _addressController,
                                    minLines: 3,
                                    maxLines: 5,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: const InputDecoration(
                                      labelText: 'Acik adres',
                                      hintText:
                                          'Mahalle, sokak, bina no, ilce / il',
                                      alignLabelWithHint: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _sectionHeader(
                                icon: Icons.business_center_rounded,
                                title: 'Ticari ve yetkili (opsiyonel)',
                                subtitle:
                                    'Bu alanlar tek bir "notlar" alaninda birlestirilir; '
                                    'backend\'de ayri alan yoktur.',
                                accent: const Color(0xFF0D9488),
                              ),
                              const SizedBox(height: 14),
                              _fieldCard(
                                children: [
                                  TextFormField(
                                    controller: _contactPersonController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      labelText: 'Yetkili kisi',
                                      hintText: 'Iletisim kurulacak kisi',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _taxIdController,
                                    decoration: const InputDecoration(
                                      labelText: 'Vergi no / TC',
                                      hintText: 'Ticari veya bireysel',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.numbers_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _websiteController,
                                    keyboardType: TextInputType.url,
                                    decoration: const InputDecoration(
                                      labelText: 'Web sitesi',
                                      hintText: 'https://',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.language_rounded),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _sectionHeader(
                                icon: Icons.sticky_note_2_rounded,
                                title: 'Notlar',
                                subtitle:
                                    'Ozel anlasmalar, risk notu veya hatirlatmalar. '
                                    'Ustteki ticari satirlarla birlikte en fazla 2000 karakter.',
                                accent: const Color(0xFF7C3AED),
                              ),
                              const SizedBox(height: 14),
                              _fieldCard(
                                children: [
                                  TextFormField(
                                    controller: _notesController,
                                    minLines: 4,
                                    maxLines: 8,
                                    decoration: const InputDecoration(
                                      labelText: 'Serbest notlar',
                                      hintText:
                                          'Sadece sizin gorebileceginiz notlar...',
                                      alignLabelWithHint: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _saving
                                          ? null
                                          : () => context.go('/clients'),
                                      icon: const Icon(Icons.close_rounded),
                                      label: const Text('Iptal'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: FilledButton.icon(
                                      onPressed: _saving ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        elevation: 4,
                                        shadowColor: AppColors.primaryColor
                                            .withAlpha(100),
                                      ),
                                      icon: _saving
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.save_rounded),
                                      label: Text(
                                        _saving
                                            ? 'Kaydediliyor...'
                                            : 'Musteriyi kaydet',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
