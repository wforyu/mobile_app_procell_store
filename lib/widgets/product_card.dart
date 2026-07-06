import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Hero(
                    tag: 'product_${product.id}',
                    child: _buildImage(),
                  ),
                  if (product.hasDiscount && product.discountPercent != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (product.stock == 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: const Center(
                          child: Text('Habis',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      Text(product.brand!,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500]),
                          maxLines: 1),
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < product.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (product.hasDiscount)
                      Text(
                        product.priceFormatted,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough),
                      ),
                    Text(
                      product.effectivePriceFormatted,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A73E8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (product.image == null) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }
    return CachedNetworkImage(
      imageUrl: product.image!,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, _, _) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }
}
