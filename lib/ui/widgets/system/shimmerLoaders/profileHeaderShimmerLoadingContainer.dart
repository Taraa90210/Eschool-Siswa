import 'package:eschool/ui/widgets/system/shimmerLoaders/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/shimmerLoadingContainer.dart';
import 'package:flutter/material.dart';

class ProfileHeaderShimmerLoadingContainer extends StatelessWidget {
  const ProfileHeaderShimmerLoadingContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical:
            MediaQuery.of(context).padding.top + 16,
        horizontal: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile Picture Shimmer (80x80 like original)
              ShimmerLoadingContainer(
                child: CustomShimmerContainer(
                  width: 80,
                  height: 80,
                  borderRadius: 40,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * (0.05),
              ),
              // Profile Info Shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting shimmer (Selamat Pagi)
                    ShimmerLoadingContainer(
                      child: CustomShimmerContainer(
                        borderRadius: 4,
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Name shimmer with emoji space
                    ShimmerLoadingContainer(
                      child: CustomShimmerContainer(
                        borderRadius: 4,
                        width: MediaQuery.of(context).size.width * 0.45,
                        height: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Badges shimmer
                    Row(
                      children: [
                        // Class badge shimmer
                        ShimmerLoadingContainer(
                          child: CustomShimmerContainer(
                            borderRadius: 30,
                            width: MediaQuery.of(context).size.width * 0.22,
                            height: 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Absent badge shimmer
                        ShimmerLoadingContainer(
                          child: CustomShimmerContainer(
                            borderRadius: 30,
                            width: MediaQuery.of(context).size.width * 0.28,
                            height: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}


