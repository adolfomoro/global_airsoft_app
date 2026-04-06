import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class RequestNotificationPermissionDialog extends StatelessWidget {
  const RequestNotificationPermissionDialog({
    super.key,
    required this.onAllow,
    required this.onDismiss,
  });

  final VoidCallback onAllow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.onPrimary,
                size: 40,
              ),
            ),
            AppSpacing.sizedBoxVerticalMd,
            Text(
              'Fique por Dentro! 🔔',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.sizedBoxVerticalSm,
            Text(
              'Ative notificações para não perder nada importante',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceDim,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.sizedBoxVerticalLg,
            _BenefitItem(
              icon: Icons.people_rounded,
              title: 'Convites de Amigos',
              description: 'Receba solicitações de amizade al instante',
            ),
            AppSpacing.sizedBoxVerticalMd,
            _BenefitItem(
              icon: Icons.local_fire_department_rounded,
              title: 'Jogos Próximos',
              description: 'Não perca nenhum evento perto de você',
            ),
            AppSpacing.sizedBoxVerticalMd,
            _BenefitItem(
              icon: Icons.groups_rounded,
              title: 'Times Querendo Você',
              description: 'Veja convites de times em busca de jogadores',
            ),
            AppSpacing.sizedBoxVerticalXl,
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onAllow,
                child: const Text('Permitir Notificações'),
              ),
            ),
            AppSpacing.sizedBoxVerticalMd,
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onDismiss,
                child: const Text('Agora Não'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.secondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
