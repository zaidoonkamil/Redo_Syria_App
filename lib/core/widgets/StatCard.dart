import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String icon;
  final int total;
  final int used;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.icon,
    required this.total,
    required this.used,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final percent = (used / total).clamp(0.0, 1.0);

    return Container(
      width: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 4,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Image.asset('assets/images/$icon'),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'احصائي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '$used / $total',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
