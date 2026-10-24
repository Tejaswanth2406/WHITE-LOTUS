import 'package:flutter/material.dart';

import '../../data/file_system/local_media_store.dart';
import '../files/file_system_screen.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key, this.store});

  final LocalMediaStore? store;

  @override
  Widget build(BuildContext context) {
    return FileSystemScreen(
      store: store,
      title: 'Vault',
      subtitle: 'App-local storage. Files are not password-encrypted yet.',
    );
  }
}
