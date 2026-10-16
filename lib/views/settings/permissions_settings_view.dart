import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/one_ui_card.dart';

/// واجهة إدارة الأذونات بنمط One UI
class PermissionsSettingsView extends StatefulWidget {
  const PermissionsSettingsView({super.key});

  @override
  State<PermissionsSettingsView> createState() =>
      _PermissionsSettingsViewState();
}

class _PermissionsSettingsViewState extends State<PermissionsSettingsView> {
  bool _micEnabled = false;
  bool _cameraEnabled = true;
  bool _photosEnabled = true;

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onChanged(!isEnabled);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF0F172A),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                isEnabled
                    ? AppStrings.permissionOn
                    : AppStrings.permissionOff,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isEnabled
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_left,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text('الأذونات'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          OneUiCard(
            children: [
              _buildPermissionRow(
                icon: Icons.mic_none_outlined,
                title: AppStrings.micPermission,
                isEnabled: _micEnabled,
                onChanged: (val) => setState(() => _micEnabled = val),
              ),
              _buildPermissionRow(
                icon: Icons.camera_alt_outlined,
                title: AppStrings.cameraPermission,
                isEnabled: _cameraEnabled,
                onChanged: (val) => setState(() => _cameraEnabled = val),
              ),
              _buildPermissionRow(
                icon: Icons.photo_library_outlined,
                title: AppStrings.photosPermission,
                isEnabled: _photosEnabled,
                onChanged: (val) => setState(() => _photosEnabled = val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
