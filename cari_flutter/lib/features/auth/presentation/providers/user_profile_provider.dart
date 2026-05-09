import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';

final userProfileProvider = FutureProvider<UserModel>((ref) {
  return ref.read(authRepositoryProvider).fetchProfile();
});
