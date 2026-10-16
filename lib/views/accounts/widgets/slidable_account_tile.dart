import 'package:flutter/material.dart';

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
  static const double _actionWidth = 66.0;
  static const double _totalWidth = _actionWidth * 3; // 198.0

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
          // خلفية الإجراءات الثلاثة - تظهر فقط وبدقة متناهية عند بدء السحب (لا ترسم إطلاقاً عندما تكون مغلقة لمنع أي تسريب للألوان)
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
                          icon: Icons.edit_outlined,
                          label: 'تعديل',
                          color: const Color(0xFF3B82F6),
                          onTap: () {
                            _close();
                            widget.onEdit?.call();
                          },
                        ),

                        // زر حذف (أحمر)

                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'حذف',
                          color: const Color(0xFFEF4444),
                          onTap: () {
                            _close();
                            widget.onDelete?.call();
                          },
                        ),
                        // زر أرشفة (برتقالي / كهرماني)
                        _buildActionButton(
                          icon: Icons.archive_outlined,
                          label: 'أرشفة',
                          color: const Color(0xFFF59E0B),
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
              color: Colors.white,
              elevation: _dragExtent > 0 ? 3 : 0,
              shadowColor: Colors.black.withOpacity(0.18),
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
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
