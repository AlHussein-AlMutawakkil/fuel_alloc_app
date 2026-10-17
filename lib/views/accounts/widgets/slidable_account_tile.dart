import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_typography.dart';

/// عنصر قائمة قابل للسحب إلى اليمين لكشف الإجراءات الثلاثة: حذف، تعديل، أرشفة
class SlidableAccountTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  const SlidableAccountTile({
    super.key,
    required this.child,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onArchive,
  });

  @override
  State<SlidableAccountTile> createState() => _SlidableAccountTileState();
}

class _SlidableAccountTileState extends State<SlidableAccountTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  double _dragExtent = 0.0;
  static const double _actionWidth = AppDimensions.slidableActionWidth;
  static const double _totalWidth = AppDimensions.slidableTotalWidth;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_animController)
      ..addListener(() {
        setState(() {
          _dragExtent = _animation.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          if (_animation.value <= 0.001 && mounted) {
            setState(() {
              _dragExtent = 0.0;
            });
          }
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _animation = Tween<double>(begin: _dragExtent, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  void _close() {
    _animateTo(0.0);
  }

  void _open() {
    _animateTo(_totalWidth);
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _dragExtent > 0.0;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        // السحب جهة اليمين (delta.dx > 0)
        setState(() {
          _dragExtent =
              (_dragExtent + details.delta.dx).clamp(0.0, _totalWidth);
        });
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          _open();
        } else if (details.primaryVelocity != null &&
            details.primaryVelocity! < -300) {
          _close();
        } else if (_dragExtent > _totalWidth * 0.4) {
          _open();
        } else {
          _close();
        }
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // خلفية الإجراءات الثلاثة - تظهر فقط وبدقة متناهية عند بدء السحب
          if (_dragExtent > 0.0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _dragExtent,
              child: ClipRect(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: _totalWidth,
                    maxWidth: _totalWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // زر تعديل (أزرق)
                        _buildActionButton(
                          icon: AppIcons.edit,
                          label: AppStrings.edit,
                          color: AppColors.actionEdit,
                          onTap: () {
                            _close();
                            widget.onEdit?.call();
                          },
                        ),

                        // زر حذف (أحمر)
                        _buildActionButton(
                          icon: AppIcons.delete,
                          label: AppStrings.delete,
                          color: AppColors.actionDelete,
                          onTap: () {
                            _close();
                            widget.onDelete?.call();
                          },
                        ),
                        // زر أرشفة (برتقالي / كهرماني)
                        _buildActionButton(
                          icon: AppIcons.archive,
                          label: AppStrings.archive,
                          color: AppColors.actionArchive,
                          onTap: () {
                            _close();
                            widget.onArchive?.call();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // واجهة العنصر في المقدمة
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Material(
              color: AppColors.surface,
              elevation: _dragExtent > 0 ? 3 : 0,
              shadowColor: AppColors.overlayLight,
              child: InkWell(
                onTap: () {
                  if (isOpen) {
                    _close();
                  } else {
                    widget.onTap?.call();
                  }
                },
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: _actionWidth,
        color: color,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.textWhite,
              size: AppDimensions.iconMedium + 1,
            ),
            const SizedBox(height: AppDimensions.spaceXXS + 1),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: AppTypography.sizeSmall,
                fontWeight: AppTypography.weightBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
