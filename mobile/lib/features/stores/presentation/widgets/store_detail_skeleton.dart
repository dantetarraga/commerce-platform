import 'package:apamuy/features/stores/presentation/widgets/store_logo.dart';
import 'package:apamuy/features/stores/presentation/widgets/store_stat_blocks.dart';
import 'package:apamuy/shared/design_system/design_system.dart';
import 'package:apamuy/shared/widgets/image_sliver_app_bar.dart';
import 'package:flutter/material.dart';

/// Misma geometría que la pantalla real para que el crossfade no salte. Si la
/// portada ya se conoce, se muestra.
class StoreDetailSkeleton extends StatelessWidget {
  const StoreDetailSkeleton({this.coverUrl, this.heroTag, super.key});

  final String? coverUrl;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        ImageSliverAppBar.loading(
          imageUrl: coverUrl,
          heroTag: heroTag,
          edgeHeight: StoreLogo.size,
          edge: const StoreLogo(loading: true),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 220, height: 32),
                      SizedBox(height: 10),
                      SkeletonBox(width: 200, height: 12),
                      SizedBox(height: 12),
                      SkeletonBox(width: 170, height: 12),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                StoreStatBlocksSkeleton(),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: MenuHeadSkeleton()),
        SliverList.builder(itemCount: 3, itemBuilder: (_, _) => const AppProductRowSkeleton()),
      ],
    ),
  );
}

/// Pestañas de secciones y el título de la primera, antes de las filas.
class MenuHeadSkeleton extends StatelessWidget {
  const MenuHeadSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Skeleton(
    child: Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: SkeletonBox(width: 92, height: 40, borderRadius: AppRadius.button)),
              SizedBox(width: AppSpacing.xs),
              Flexible(child: SkeletonBox(width: 110, height: 40, borderRadius: AppRadius.button)),
              SizedBox(width: AppSpacing.xs),
              Flexible(child: SkeletonBox(width: 80, height: 40, borderRadius: AppRadius.button)),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(width: 130, height: 22),
        ],
      ),
    ),
  );
}
