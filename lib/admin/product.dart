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
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _materials = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return _materials;

    return _materials.where((item) {
      final supplier = item['supplier_name']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';
      final unit = item['unit']?.toString().toLowerCase() ?? '';
      final location = item['location']?.toString().toLowerCase() ?? '';

      return supplier.contains(query) ||
          description.contains(query) ||
          unit.contains(query) ||
          location.contains(query);
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

  String _money(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '0') ?? 0;
    return '₱${number.toStringAsFixed(2)}';
  }

  String _text(dynamic value) {
    return value?.toString() ?? '-';
  }

  String _unitLabel(Map<String, dynamic> item) {
    final unitValue = item['unit_value']?.toString() ?? '1';
    final unit = item['unit']?.toString() ?? '';
    return '$unitValue $unit';
  }

  Future<void> _deleteMaterial(String id) async {
    try {
      await Supabase.instance.client.from('materials').delete().eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Material deleted')));

      await _loadMaterials();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Delete ${_text(item['description'])}?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ProductStyles.statCardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: ProductStyles.statIconDecoration,
              child: Icon(icon, color: ProductStyles.primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ProductStyles.statLabelStyle),
                  const SizedBox(height: 4),
                  Text(value, style: ProductStyles.statValueStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    final items = _filteredMaterials;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text('No materials found', style: ProductStyles.emptyStyle),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: ProductStyles.mobileCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _text(item['description']),
                style: ProductStyles.mobileTitleStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Supplier: ${_text(item['supplier_name'])}',
                style: ProductStyles.mobileSubStyle,
              ),
              Text(
                'Unit: ${_unitLabel(item)}',
                style: ProductStyles.mobileSubStyle,
              ),
              Text(
                'Qty: ${_text(item['quantity'])}',
                style: ProductStyles.mobileSubStyle,
              ),
              Text(
                'Price: ${_money(item['price'])}',
                style: ProductStyles.mobileSubStyle,
              ),
              Text(
                'Total: ${_money(item['total'])}',
                style: ProductStyles.mobileTotalStyle,
              ),
              Text(
                'Location: ${_text(item['location'])}',
                style: ProductStyles.mobileSubStyle,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => _confirmDelete(item),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: ProductStyles.dangerColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTable() {
    final items = _filteredMaterials;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No materials found', style: ProductStyles.emptyStyle),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            ProductStyles.tableHeaderColor,
          ),
          dataRowColor: WidgetStateProperty.all(ProductStyles.tableRowColor),
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Supplier')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Unit')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Location')),
            DataColumn(label: Text('Action')),
          ],
          rows: items.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(_text(item['supplier_name']))),
                DataCell(Text(_text(item['description']))),
                DataCell(Text(_unitLabel(item))),
                DataCell(Text(_money(item['price']))),
                DataCell(Text(_text(item['quantity']))),
                DataCell(Text(_money(item['total']))),
                DataCell(Text(_text(item['location']))),
                DataCell(
                  IconButton(
                    onPressed: () => _confirmDelete(item),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: ProductStyles.dangerColor,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
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
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product / Materials',
              style: isMobile
                  ? ProductStyles.pageTitleMobileStyle
                  : ProductStyles.pageTitleStyle,
            ),
            const SizedBox(height: 8),
            const Text(
              'View all saved materials and inventory records.',
              style: ProductStyles.pageSubtitleStyle,
            ),
            const SizedBox(height: 18),
            isMobile
                ? Column(
                    children: [
                      Row(
                        children: [
                          _statCard(
                            label: 'Items',
                            value: _filteredMaterials.length.toString(),
                            icon: Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            label: 'Quantity',
                            value: _totalQuantity.toString(),
                            icon: Icons.format_list_numbered_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(
                            label: 'Total Value',
                            value: '₱${_grandTotal.toStringAsFixed(2)}',
                            icon: Icons.payments_outlined,
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _statCard(
                        label: 'Items',
                        value: _filteredMaterials.length.toString(),
                        icon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(width: 14),
                      _statCard(
                        label: 'Quantity',
                        value: _totalQuantity.toString(),
                        icon: Icons.format_list_numbered_outlined,
                      ),
                      const SizedBox(width: 14),
                      _statCard(
                        label: 'Total Value',
                        value: '₱${_grandTotal.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                      ),
                    ],
                  ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: ProductStyles.textPrimary),
                    decoration: ProductStyles.searchDecoration,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _loadMaterials,
                  icon: const Icon(Icons.refresh_rounded),
                  style: ProductStyles.refreshButtonStyle,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : isMobile
                  ? SingleChildScrollView(child: _buildMobileList())
                  : SingleChildScrollView(child: _buildTable()),
            ),
          ],
        ),
      ),
    );
  }
}
