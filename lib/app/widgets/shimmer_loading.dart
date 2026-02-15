import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.shapeBorder = const RoundedRectangleBorder(),
  });

  const ShimmerLoading.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[300],
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: ShimmerLoading.circular(width: 100, height: 100)),
          const SizedBox(height: 20),
          const ShimmerLoading.rectangular(height: 20, width: 200),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          ...List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoading.rectangular(height: 16, width: 100),
                  const SizedBox(height: 8),
                  const ShimmerLoading.rectangular(
                    height: 16,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerHome extends StatelessWidget {
  const ShimmerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card Shimmer
          ShimmerLoading.rectangular(
            height: 100,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),

          // Ads Slider Shimmer
          const ShimmerLoading.rectangular(height: 20, width: 120),
          const SizedBox(height: 10),
          ShimmerLoading.rectangular(
            height: 200,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),

          // Recent Posts Header Shimmer
          const ShimmerLoading.rectangular(height: 20, width: 140),
          const SizedBox(height: 10),

          // Posts List Shimmer
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerLoading.rectangular(
                height: 80,
                shapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerPosts extends StatelessWidget {
  const ShimmerPosts({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ShimmerLoading.rectangular(
          height: 120,
          shapeBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class ShimmerDirectory extends StatelessWidget {
  const ShimmerDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const ShimmerLoading.circular(width: 56, height: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoading.rectangular(height: 16, width: 150),
                  const SizedBox(height: 8),
                  const ShimmerLoading.rectangular(height: 14, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
