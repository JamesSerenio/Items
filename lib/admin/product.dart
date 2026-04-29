import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/product_styles.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);

    try {
      final data = await Supabase.instance.client
          .from('materials')
          .select(
            'id, supplier_name, description, unit, unit_value, price, quantity, total, location, created_at',
          )
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _materials = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Load failed: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _materials;

    return _materials.where((item) {
      return [
        item['supplier_name'],
        item['description'],
        item['unit'],
        item['unit_value'],
        item['location'],
      ].any((v) => (v?.toString().toLowerCase() ?? '').contains(query));
    }).toList();
  }

  num get _grandTotal {
    num total = 0;
    for (final item in _filteredMaterials) {
      total += num.tryParse(item['total']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  num get _totalQuantity {
    num total = 0;
    for (final item in _filteredMaterials) {
      total += num.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  String _text(dynamic value) => value?.toString() ?? '-';

  String _money(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '0') ?? 0;
    return '₱${number.toStringAsFixed(2)}';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = double.tryParse(value.trim());
    if (number == null) return 'Invalid number';
    if (number <= 0) return 'Must be greater than 0';
    return null;
  }

  Future<void> _deleteMaterial(String id) async {
    try {
      await Supabase.instance.client.from('materials').delete().eq('id', id);
      if (!mounted) return;
      _showSnack('Material deleted');
      await _loadMaterials();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Delete failed: $e');
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ProductStyles.panelCardColor,
        title: const Text(
          'Delete Material',
          style: TextStyle(color: ProductStyles.textPrimary),
        ),
        content: Text(
          'Delete ${_text(item['description'])}?',
          style: const TextStyle(color: ProductStyles.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMaterial(item['id'].toString());
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: ProductStyles.dangerColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMaterial({
    required String id,
    required String supplierName,
    required String description,
    required String unit,
    required double unitValue,
    required double price,
    required double quantity,
    required String location,
  }) async {
    try {
      await Supabase.instance.client
          .from('materials')
          .update({
            'supplier_name': supplierName,
            'description': description,
            'unit': unit,
            'unit_value': unitValue,
            'price': price,
            'quantity': quantity,
            'location': location,
          })
          .eq('id', id);

      if (!mounted) return;
      _showSnack('Material updated');
      await _loadMaterials();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Update failed: $e');
    }
  }

  void _openEditDialog(Map<String, dynamic> item) {
    final supplierController = TextEditingController(
      text: _text(item['supplier_name']),
    );
    final descriptionController = TextEditingController(
      text: _text(item['description']),
    );
    final unitController = TextEditingController(text: _text(item['unit']));
    final unitValueController = TextEditingController(
      text: _text(item['unit_value']),
    );
    final priceController = TextEditingController(text: _text(item['price']));
    final quantityController = TextEditingController(
      text: _text(item['quantity']),
    );
    final locationController = TextEditingController(
      text: _text(item['location']),
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) {
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 18,
            vertical: 14,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              decoration: ProductStyles.editDialogDecoration,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Edit Material',
                              style: ProductStyles.dialogTitleStyle.copyWith(
                                fontSize: isMobile ? 18 : 22,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            color: ProductStyles.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _EditField(
                        controller: supplierController,
                        label: 'Name of Supplier',
                        icon: Icons.storefront_outlined,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 10),
                      _EditField(
                        controller: descriptionController,
                        label: 'Description',
                        icon: Icons.inventory_2_outlined,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _EditField(
                              controller: unitController,
                              label: 'Unit',
                              icon: Icons.category_outlined,
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _EditField(
                              controller: unitValueController,
                              label: 'Unit Value',
                              icon: Icons.scale_outlined,
                              keyboardType: TextInputType.number,
                              validator: _numberValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _EditField(
                              controller: priceController,
                              label: 'Price',
                              icon: Icons.payments_outlined,
                              keyboardType: TextInputType.number,
                              validator: _numberValidator,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _EditField(
                              controller: quantityController,
                              label: 'Quantity',
                              icon: Icons.format_list_numbered_outlined,
                              keyboardType: TextInputType.number,
                              validator: _numberValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _EditField(
                        controller: locationController,
                        label: 'Location',
                        icon: Icons.location_on_outlined,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ProductStyles.cancelButtonStyle,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                Navigator.pop(context);

                                await _updateMaterial(
                                  id: item['id'].toString(),
                                  supplierName: supplierController.text.trim(),
                                  description: descriptionController.text
                                      .trim(),
                                  unit: unitController.text.trim(),
                                  unitValue: double.parse(
                                    unitValueController.text.trim(),
                                  ),
                                  price: double.parse(
                                    priceController.text.trim(),
                                  ),
                                  quantity: double.parse(
                                    quantityController.text.trim(),
                                  ),
                                  location: locationController.text.trim(),
                                );
                              },
                              style: ProductStyles.saveEditButtonStyle,
                              child: const Text(
                                'Save',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _compactStatCard({
    required String label,
    required String value,
    required IconData icon,
    required bool isMobile,
  }) {
    return Expanded(
      child: Container(
        height: isMobile ? 50 : 92,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 5 : 18,
          vertical: isMobile ? 5 : 16,
        ),
        decoration: ProductStyles.statCardDecoration.copyWith(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 22),
        ),
        child: Row(
          children: [
            Container(
              width: isMobile ? 21 : 48,
              height: isMobile ? 21 : 48,
              decoration: ProductStyles.statIconDecoration.copyWith(
                borderRadius: BorderRadius.circular(isMobile ? 7 : 15),
              ),
              child: Icon(
                icon,
                color: ProductStyles.primaryColor,
                size: isMobile ? 12 : 22,
              ),
            ),
            SizedBox(width: isMobile ? 4 : 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ProductStyles.statLabelStyle.copyWith(
                      fontSize: isMobile ? 8 : 13,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: ProductStyles.statValueStyle.copyWith(
                        fontSize: isMobile ? 10 : 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(bool isMobile) {
    return Row(
      children: [
        _compactStatCard(
          label: 'Items',
          value: _filteredMaterials.length.toString(),
          icon: Icons.inventory_2_outlined,
          isMobile: isMobile,
        ),
        SizedBox(width: isMobile ? 5 : 14),
        _compactStatCard(
          label: 'Qty',
          value: _totalQuantity.toString(),
          icon: Icons.format_list_numbered_outlined,
          isMobile: isMobile,
        ),
        SizedBox(width: isMobile ? 5 : 14),
        _compactStatCard(
          label: 'Value',
          value: _money(_grandTotal),
          icon: Icons.payments_outlined,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildSearchAndRefresh(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: isMobile ? 38 : 58,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                color: ProductStyles.textPrimary,
                fontSize: isMobile ? 11 : 14,
              ),
              decoration: ProductStyles.searchDecoration.copyWith(
                hintText: isMobile
                    ? 'Search material...'
                    : 'Search supplier, material, unit, or location...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 18,
                  vertical: isMobile ? 7 : 18,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 6 : 10),
        SizedBox(
          height: isMobile ? 38 : 58,
          width: isMobile ? 41 : 58,
          child: IconButton(
            onPressed: _loadMaterials,
            icon: Icon(Icons.refresh_rounded, size: isMobile ? 17 : 24),
            style: ProductStyles.refreshButtonStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildTable(bool isMobile) {
    final items = _filteredMaterials;

    if (items.isEmpty) {
      return const Center(
        child: Text('No materials found', style: ProductStyles.emptyStyle),
      );
    }

    if (isMobile) {
      return Container(
        width: double.infinity,
        decoration: ProductStyles.tableOuterDecoration.copyWith(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: DataTable(
            headingRowHeight: 34,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 54,
            horizontalMargin: 6,
            columnSpacing: 7,
            dividerThickness: 0.45,
            headingRowColor: WidgetStateProperty.all(
              ProductStyles.tableHeaderColor,
            ),
            dataRowColor: WidgetStateProperty.resolveWith(
              (states) => ProductStyles.tableRowColor,
            ),
            columns: const [
              DataColumn(label: _MobileHeaderText('Supplier')),
              DataColumn(label: _MobileHeaderText('Material')),
              DataColumn(label: _MobileHeaderText('Price')), // ✅ ADD
              DataColumn(label: _MobileHeaderText('Qty')),
              DataColumn(label: _MobileHeaderText('Total')),
              DataColumn(label: _MobileHeaderText('Act')),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 52,
                      child: _MobileCellText(_text(item['supplier_name'])),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MobileCellText(_text(item['description'])),
                          const SizedBox(height: 2),
                          Text(
                            '${_text(item['unit'])} • UV ${_text(item['unit_value'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ProductStyles.pageSubtitleStyle.copyWith(
                              fontSize: 6.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 40,
                      child: Text(
                        _money(item['price']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ProductStyles.tableCellTextStyle.copyWith(
                          fontSize: 7.8,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 20,
                      child: Text(
                        _text(item['quantity']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ProductStyles.tableCellTextStyle.copyWith(
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 46,
                      child: Text(
                        _money(item['total']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ProductStyles.tableHighlightTextStyle.copyWith(
                          fontSize: 7.8,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 42,
                      child: Row(
                        children: [
                          _TinyActionButton(
                            icon: Icons.edit_rounded,
                            color: ProductStyles.primaryColor,
                            onTap: () => _openEditDialog(item),
                          ),
                          const SizedBox(width: 3),
                          _TinyActionButton(
                            icon: Icons.delete_outline_rounded,
                            color: ProductStyles.dangerColor,
                            onTap: () => _confirmDelete(item),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: ProductStyles.tableOuterDecoration,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              primary: false,
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowHeight: 58,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 66,
                horizontalMargin: 22,
                columnSpacing: 26,
                dividerThickness: 0.6,
                headingRowColor: WidgetStateProperty.all(
                  ProductStyles.tableHeaderColor,
                ),
                dataRowColor: WidgetStateProperty.resolveWith(
                  (states) => ProductStyles.tableRowColor,
                ),
                columns: const [
                  DataColumn(label: _HeaderText('Supplier')),
                  DataColumn(label: _HeaderText('Description')),
                  DataColumn(label: _HeaderText('Unit')),
                  DataColumn(label: _HeaderText('Unit Value')),
                  DataColumn(label: _HeaderText('Price')),
                  DataColumn(label: _HeaderText('Qty')),
                  DataColumn(label: _HeaderText('Total')),
                  DataColumn(label: _HeaderText('Location')),
                  DataColumn(label: _HeaderText('Action')),
                ],
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 130,
                          child: _CellText(_text(item['supplier_name'])),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: _CellText(_text(item['description'])),
                        ),
                      ),
                      DataCell(_UnitPill(_text(item['unit']))),
                      DataCell(_CellText(_text(item['unit_value']))),
                      DataCell(_CellText(_money(item['price']))),
                      DataCell(_CellText(_text(item['quantity']))),
                      DataCell(
                        _CellText(_money(item['total']), isHighlight: true),
                      ),
                      DataCell(
                        SizedBox(
                          width: 130,
                          child: _CellText(_text(item['location'])),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              icon: Icons.edit_rounded,
                              color: ProductStyles.primaryColor,
                              onTap: () => _openEditDialog(item),
                            ),
                            const SizedBox(width: 7),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: ProductStyles.dangerColor,
                              onTap: () => _confirmDelete(item),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Container(
      decoration: ProductStyles.pageBackground,
      child: Container(
        decoration: isMobile
            ? ProductStyles.mobilePanelDecoration
            : ProductStyles.panelDecoration,
        padding: EdgeInsets.all(isMobile ? 8 : 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product / Materials',
              style: isMobile
                  ? ProductStyles.pageTitleMobileStyle.copyWith(fontSize: 18)
                  : ProductStyles.pageTitleStyle,
            ),
            SizedBox(height: isMobile ? 2 : 5),
            Text(
              'View, update, and manage all saved materials.',
              style: ProductStyles.pageSubtitleStyle.copyWith(
                fontSize: isMobile ? 10 : 14,
              ),
            ),
            SizedBox(height: isMobile ? 7 : 20),
            _buildStats(isMobile),
            SizedBox(height: isMobile ? 7 : 18),
            _buildSearchAndRefresh(isMobile),
            SizedBox(height: isMobile ? 7 : 18),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTable(isMobile),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: ProductStyles.tableHeaderTextStyle);
  }
}

class _MobileHeaderText extends StatelessWidget {
  final String text;

  const _MobileHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ProductStyles.tableHeaderTextStyle.copyWith(fontSize: 8.5),
    );
  }
}

class _CellText extends StatelessWidget {
  final String text;
  final bool isHighlight;

  const _CellText(this.text, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: isHighlight
          ? ProductStyles.tableHighlightTextStyle
          : ProductStyles.tableCellTextStyle,
    );
  }
}

class _MobileCellText extends StatelessWidget {
  final String text;

  const _MobileCellText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: ProductStyles.tableCellTextStyle.copyWith(
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _UnitPill extends StatelessWidget {
  final String text;

  const _UnitPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: ProductStyles.unitPillDecoration,
      child: Text(text, style: ProductStyles.unitPillTextStyle),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TinyActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Icon(icon, color: color, size: 11),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: icon == Icons.edit_rounded ? 'Edit' : 'Delete',
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: color.withOpacity(0.45)),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: ProductStyles.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ProductStyles.textSecondary),
        prefixIcon: Icon(icon, color: ProductStyles.textSecondary),
        filled: true,
        fillColor: ProductStyles.inputFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ProductStyles.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ProductStyles.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ProductStyles.dangerColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ProductStyles.dangerColor),
        ),
      ),
    );
  }
}
