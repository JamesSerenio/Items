import 'package:flutter/material.dart';
import '../styles/add_items_styles.dart';

class AddItemsPage extends StatelessWidget {
  const AddItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      decoration: AddItemsStyles.pageBackground,
      child: Container(
        decoration: isMobile
            ? AddItemsStyles.mobilePanelDecoration
            : AddItemsStyles.panelDecoration,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Items',
                style: isMobile
                    ? AddItemsStyles.pageTitleMobileStyle
                    : AddItemsStyles.pageTitleStyle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your product or item details here.',
                style: AddItemsStyles.pageSubtitleStyle,
              ),
              const SizedBox(height: 20),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: AddItemsStyles.formCardDecoration,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _InputField(
                          label: 'Item Name',
                          hintText: 'Enter item name',
                          icon: Icons.inventory_2_outlined,
                        ),
                        const SizedBox(height: 16),
                        const _InputField(
                          label: 'Price',
                          hintText: 'Enter price',
                          icon: Icons.payments_outlined,
                        ),
                        const SizedBox(height: 16),
                        const _InputField(
                          label: 'Description',
                          hintText: 'Enter description',
                          icon: Icons.description_outlined,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: AddItemsStyles.saveButtonStyle,
                            child: const Text(
                              'Save Item',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final int maxLines;

  const _InputField({
    required this.label,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMultiLine = maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AddItemsStyles.labelStyle),
        const SizedBox(height: 10),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(color: AddItemsStyles.textPrimary),
          decoration: AddItemsStyles.inputDecoration(
            hintText: hintText,
            prefixIcon: icon,
            alignLabelTop: isMultiLine,
          ),
        ),
      ],
    );
  }
}
