import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _companyName = TextEditingController();
  final _taxOffice = TextEditingController();
  final _taxId = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyAddress = TextEditingController();

  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _newPasswordAgain = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureNewAgain = true;

  bool _profileSaving = false;
  bool _passwordSaving = false;

  String? _lastFilledUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyName.dispose();
    _taxOffice.dispose();
    _taxId.dispose();
    _companyPhone.dispose();
    _companyAddress.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _newPasswordAgain.dispose();
    super.dispose();
  }

  void _fillFromUser(UserModel u) {
    _companyName.text = u.companyName;
    _taxOffice.text = u.taxOffice;
    _taxId.text = u.taxId;
    _companyPhone.text = u.companyPhone;
    _companyAddress.text = u.companyAddress;
    _lastFilledUserId = u.id;
  }

  Future<void> _saveCompanyProfile() async {
    setState(() => _profileSaving = true);
    try {
      final updated = await ref.read(authRepositoryProvider).updateProfile({
        'companyName': _companyName.text.trim(),
        'taxOffice': _taxOffice.text.trim(),
        'taxId': _taxId.text.trim(),
        'companyPhone': _companyPhone.text.trim(),
        'companyAddress': _companyAddress.text.trim(),
      });
      ref.read(authNotifierProvider.notifier).setAuthenticatedUser(updated);
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kurum bilgileri kaydedildi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorMapper.toMessage(e))));
    } finally {
      if (mounted) setState(() => _profileSaving = false);
    }
  }

  Future<void> _changePassword() async {
    final cur = _currentPassword.text;
    final n1 = _newPassword.text;
    final n2 = _newPasswordAgain.text;
    if (cur.isEmpty || n1.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mevcut ve yeni sifreyi girin')),
      );
      return;
    }
    if (n1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni sifre en az 6 karakter olmali')),
      );
      return;
    }
    if (n1 != n2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Yeni sifreler eslesmiyor')));
      return;
    }

    setState(() => _passwordSaving = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(currentPassword: cur, newPassword: n1);
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _newPasswordAgain.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sifre guncellendi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiErrorMapper.toMessage(e))));
    } finally {
      if (mounted) setState(() => _passwordSaving = false);
    }
  }

  Future<void> _refreshProfile() async {
    ref.invalidate(userProfileProvider);
    await ref.read(userProfileProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    ref.listen(userProfileProvider, (_, next) {
      next.whenData((u) {
        if (_lastFilledUserId != u.id) {
          _fillFromUser(u);
        }
      });
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withAlpha(34),
              AppColors.backgroundColor,
              AppColors.successColor.withAlpha(22),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: AppColors.dangerColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ApiErrorMapper.toMessage(e),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refreshProfile,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            ),
            data: (user) {
              final email = user.email;

              return RefreshIndicator(
                onRefresh: _refreshProfile,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Row(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, child) => Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset((1 - t) * 12, 0),
                                  child: child,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Hero(
                                    tag: 'profile_avatar',
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: AppColors.primaryColor
                                          .withAlpha(44),
                                      child: Text(
                                        email.isNotEmpty
                                            ? email[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hesabim',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textColor
                                                  .withAlpha(170),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: AppColors.primaryColor.withAlpha(36),
                            ),
                          ),
                          child: Column(
                            children: [
                              TabBar(
                                controller: _tabController,
                                labelColor: AppColors.primaryColor,
                                unselectedLabelColor: AppColors.textColor
                                    .withAlpha(140),
                                indicatorColor: AppColors.primaryColor,
                                tabs: const [
                                  Tab(
                                    icon: Icon(Icons.business_rounded),
                                    text: 'Kurum',
                                  ),
                                  Tab(
                                    icon: Icon(Icons.lock_rounded),
                                    text: 'Guvenlik',
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 420,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _CompanyTab(
                                      companyName: _companyName,
                                      taxOffice: _taxOffice,
                                      taxId: _taxId,
                                      companyPhone: _companyPhone,
                                      companyAddress: _companyAddress,
                                      saving: _profileSaving,
                                      onSave: _saveCompanyProfile,
                                    ),
                                    _PasswordTab(
                                      current: _currentPassword,
                                      newPass: _newPassword,
                                      newAgain: _newPasswordAgain,
                                      obscureCurrent: _obscureCurrent,
                                      obscureNew: _obscureNew,
                                      obscureNewAgain: _obscureNewAgain,
                                      onToggleCurrent: () => setState(
                                        () =>
                                            _obscureCurrent = !_obscureCurrent,
                                      ),
                                      onToggleNew: () => setState(
                                        () => _obscureNew = !_obscureNew,
                                      ),
                                      onToggleNewAgain: () => setState(
                                        () => _obscureNewAgain =
                                            !_obscureNewAgain,
                                      ),
                                      saving: _passwordSaving,
                                      onSubmit: _changePassword,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: _InfoTile(
                          icon: Icons.badge_outlined,
                          title: 'Kullanici ID',
                          subtitle: user.id,
                          dense: true,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: AppColors.dangerColor.withAlpha(40),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.dangerColor,
                            ),
                            title: const Text('Cikis yap'),
                            subtitle: const Text(
                              'Oturumu bu cihazda sonlandirir',
                            ),
                            onTap: () async {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .logout();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CompanyTab extends StatelessWidget {
  const _CompanyTab({
    required this.companyName,
    required this.taxOffice,
    required this.taxId,
    required this.companyPhone,
    required this.companyAddress,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController companyName;
  final TextEditingController taxOffice;
  final TextEditingController taxId;
  final TextEditingController companyPhone;
  final TextEditingController companyAddress;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ticari unvan ve iletisim bilgileriniz fatura / rapor ciktilarinda kullanilabilir.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textColor.withAlpha(150),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: companyName,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Sirket / isletme adi',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.storefront_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: taxOffice,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Vergi dairesi',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: taxId,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z\s]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Vergi no / TCKN',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: companyPhone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Isletme telefonu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: companyAddress,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Adres',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _PasswordTab extends StatelessWidget {
  const _PasswordTab({
    required this.current,
    required this.newPass,
    required this.newAgain,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.obscureNewAgain,
    required this.onToggleCurrent,
    required this.onToggleNew,
    required this.onToggleNewAgain,
    required this.saving,
    required this.onSubmit,
  });

  final TextEditingController current;
  final TextEditingController newPass;
  final TextEditingController newAgain;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureNewAgain;
  final VoidCallback onToggleCurrent;
  final VoidCallback onToggleNew;
  final VoidCallback onToggleNewAgain;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hesap sifrenizi degistirin. Mevcut sifrenizi dogru girmeniz gerekir.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textColor.withAlpha(150),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: current,
            obscureText: obscureCurrent,
            decoration: InputDecoration(
              labelText: 'Mevcut sifre',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleCurrent,
                icon: Icon(
                  obscureCurrent
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPass,
            obscureText: obscureNew,
            decoration: InputDecoration(
              labelText: 'Yeni sifre',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleNew,
                icon: Icon(
                  obscureNew
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newAgain,
            obscureText: obscureNewAgain,
            decoration: InputDecoration(
              labelText: 'Yeni sifre (tekrar)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleNewAgain,
                icon: Icon(
                  obscureNewAgain
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: saving ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.successColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(saving ? 'Guncelleniyor...' : 'Sifreyi guncelle'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.primaryColor.withAlpha(26)),
      ),
      child: ListTile(
        dense: dense,
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(title),
        subtitle: SelectableText(subtitle),
      ),
    );
  }
}
