import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/add_items_styles.dart';

class AddItemsPage extends StatefulWidget {
  const AddItemsPage({super.key});

  @override
  State<AddItemsPage> createState() => _AddItemsPageState();
}

class _AddItemsPageState extends State<AddItemsPage> {
  final _formKey = GlobalKey<FormState>();

  final _supplierController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isSaving = false;

  List<String> _suppliers = [];
  List<String> _units = [];
  List<String> _locations = [];

  double get _price => double.tryParse(_priceController.text.trim()) ?? 0;
  double get _quantity => double.tryParse(_quantityController.text.trim()) ?? 0;
  double get _total => _price * _quantity;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final data = await Supabase.instance.client
          .from('materials')
          .select('supplier_name, unit, location');

      final suppliers = <String>{};
      final units = <String>{};
      final locations = <String>{};

      for (final row in data) {
        final supplier = row['supplier_name']?.toString().trim() ?? '';
        final unit = row['unit']?.toString().trim() ?? '';
        final location = row['location']?.toString().trim() ?? '';

        if (supplier.isNotEmpty) suppliers.add(supplier);
        if (unit.isNotEmpty) units.add(unit);
        if (location.isNotEmpty) locations.add(location);
      }

      if (!mounted) return;

      setState(() {
        _suppliers = suppliers.toList()..sort();
        _units = units.toList()..sort();
        _locations = locations.toList()..sort();
      });
    } catch (_) {}
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.from('materials').insert({
        'supplier_name': _supplierController.text.trim(),
        'description': _descriptionController.text.trim(),
        'unit': _unitController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'quantity': double.parse(_quantityController.text.trim()),
        'location': _locationController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material saved successfully')),
      );

      _supplierController.clear();
      _descriptionController.clear();
      _unitController.clear();
      _priceController.clear();
      _quantityController.clear();
      _locationController.clear();

      await _loadDropdownData();
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

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
                'Add Materials',
                style: isMobile
                    ? AddItemsStyles.pageTitleMobileStyle
                    : AddItemsStyles.pageTitleStyle,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add supplier, material, unit, price, quantity, and location.',
                style: AddItemsStyles.pageSubtitleStyle,
              ),
              const SizedBox(height: 20),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: AddItemsStyles.formCardDecoration,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _AutocompleteInputField(
                            controller: _supplierController,
                            options: _suppliers,
                            label: 'Name of Supplier',
                            hintText: 'Type or select supplier',
                            icon: Icons.storefront_outlined,
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _descriptionController,
                            label: 'Description of Materials',
                            hintText: 'Enter material description',
                            icon: Icons.inventory_2_outlined,
                            maxLines: 3,
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 16),
                          _AutocompleteInputField(
                            controller: _unitController,
                            options: _units,
                            label: 'Unit',
                            hintText: 'Type unit ex: pc, bag, kg, 1/2, 0.5',
                            icon: Icons.category_outlined,
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _priceController,
                            label: 'Price',
                            hintText: 'Enter price',
                            icon: Icons.payments_outlined,
                            keyboardType: TextInputType.number,
                            validator: _numberValidator,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _quantityController,
                            label: 'Quantity',
                            hintText: 'Enter quantity',
                            icon: Icons.format_list_numbered_outlined,
                            keyboardType: TextInputType.number,
                            validator: _numberValidator,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _AutocompleteInputField(
                            controller: _locationController,
                            options: _locations,
                            label: 'Location',
                            hintText: 'Type or select location',
                            icon: Icons.location_on_outlined,
                            validator: _requiredValidator,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: Text(
                              'Total: ₱${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AddItemsStyles.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveItem,
                              style: AddItemsStyles.saveButtonStyle,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Save Material',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final number = double.tryParse(value.trim());
    if (number == null) return 'Enter a valid number';
    if (number <= 0) return 'Value must be greater than 0';

    return null;
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMultiLine = maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AddItemsStyles.labelStyle),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
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

class _AutocompleteInputField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> options;
  final String label;
  final String hintText;
  final IconData icon;
  final String? Function(String?)? validator;

  const _AutocompleteInputField({
    required this.controller,
    required this.options,
    required this.label,
    required this.hintText,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();

        if (query.isEmpty) {
          return options;
        }

        return options.where((option) => option.toLowerCase().contains(query));
      },
      onSelected: (String selected) {
        controller.text = selected;
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AddItemsStyles.labelStyle),
            const SizedBox(height: 10),
            TextFormField(
              controller: textController,
              focusNode: focusNode,
              validator: validator,
              style: const TextStyle(color: AddItemsStyles.textPrimary),
              decoration: AddItemsStyles.inputDecoration(
                hintText: hintText,
                prefixIcon: icon,
              ),
            ),
          ],
        );
      },
      optionsViewBuilder: (context, onSelected, suggestions) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: const Color(0xFF111827),
            elevation: 10,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 500),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final option = suggestions.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: const TextStyle(color: AddItemsStyles.textPrimary),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
