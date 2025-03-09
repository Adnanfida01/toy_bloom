import 'package:flutter/material.dart';

class CategoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Kids T-shirt', 'Blankets', 'Toys'];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(categories[index]),
              onSelected: (selected) {
                // Handle category selection
              },
            ),
          );
        },
      ),
    );
  }
}
