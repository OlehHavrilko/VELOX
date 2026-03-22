import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VELOX',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00E5FF),
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'Mobile IDE',
                style: TextStyle(color: Color(0xFF546E7A), fontSize: 14),
              ),
              const SizedBox(height: 40),
              _QuickButton(
                icon: Icons.terminal,
                label: 'Open Terminal',
                color: const Color(0xFF00E5FF),
                onTap: () => context.go('/terminal'),
              ),
              const SizedBox(height: 12),
              _QuickButton(
                icon: Icons.code,
                label: 'Open Editor',
                color: const Color(0xFF7C3AED),
                onTap: () => context.go('/editor'),
              ),
              const SizedBox(height: 12),
              _QuickButton(
                icon: Icons.auto_awesome,
                label: 'AI Agent',
                color: const Color(0xFF10B981),
                onTap: () => context.go('/ai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          border: Border.all(color: const Color(0xFF1E2D3D)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF546E7A), size: 14),
          ],
        ),
      ),
    );
  }
}