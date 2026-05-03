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
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitController = TextEditingController();
  final _unitValueController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isSaving = false;

  List<String> _suppliers = [];
  List<String> _brands = [];
  List<String> _units = [];
  List<String> _unitValues = [];
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
    _brandController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _unitValueController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final data = await Supabase.instance.client
          .from('materials')
          .select('supplier_name, brand, unit, unit_value, location');

      final suppliers = <String>{};
      final brands = <String>{};
      final units = <String>{};
      final unitValues = <String>{};
      final locations = <String>{};

      for (final row in data) {
        final supplier = row['supplier_name']?.toString().trim() ?? '';
        final brand = row['brand']?.toString().trim() ?? '';
        final unit = row['unit']?.toString().trim() ?? '';
        final unitValue = row['unit_value']?.toString().trim() ?? '';
        final location = row['location']?.toString().trim() ?? '';

        if (supplier.isNotEmpty) suppliers.add(supplier);
        if (brand.isNotEmpty) brands.add(brand);
        if (unit.isNotEmpty) units.add(unit);
        if (unitValue.isNotEmpty) unitValues.add(unitValue);
        if (location.isNotEmpty) locations.add(location);
      }

      if (!mounted) return;

      setState(() {
        _suppliers = suppliers.toList()..sort();
        _brands = brands.toList()..sort();
        _units = units.toList()..sort();
        _unitValues = unitValues.toList()..sort();
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
        'brand': _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        'description': _descriptionController.text.trim(),
        'unit': _unitController.text.trim(),
        'unit_value': double.parse(_unitValueController.text.trim()),
        'price': double.parse(_priceController.text.trim()),
        'quantity': double.parse(_quantityController.text.trim()),
        'location': _locationController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material saved successfully')),
      );

      _supplierController.clear();
      _brandController.clear();
      _descriptionController.clear();
      _unitController.clear();
      _unitValueController.text = '1';
      _priceController.clear();
      _quantityController.clear();
      _locationController.clear();

      await _loadDropdownData();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }

    if (mounted) setState(() => _isSaving = false);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = double.tryParse(value.trim());
    if (number == null) return 'Invalid';
    if (number <= 0) return 'Must be > 0';
    return null;
  }

  Widget _twoCol({
    required Widget left,
    required Widget right,
    required double gap,
    required bool oneColumn,
  }) {
    if (oneColumn) {
      return Column(
        children: [
          left,
          SizedBox(height: gap),
          right,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: gap),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isMobile = width < 650;
    final isTablet = width >= 650 && width < 1100;
    final compact = isMobile || isTablet;
    final oneColumn = width < 430;

    final pagePad = isMobile
        ? 8.0
        : isTablet
        ? 18.0
        : 20.0;

    final cardPad = isMobile
        ? 8.0
        : isTablet
        ? 26.0
        : 32.0;

    final gap = isMobile
        ? 4.0
        : isTablet
        ? 16.0
        : 18.0;

    final cardMaxWidth = isMobile
        ? 410.0
        : isTablet
        ? 920.0
        : 1120.0;

    final cardHeight = isMobile
        ? height * 0.95
        : isTablet
        ? height * 0.84
        : height * 0.80;

    return Container(
      decoration: AddItemsStyles.pageBackground,
      child: Container(
        decoration: AddItemsStyles.panelDecoration,
        padding: EdgeInsets.all(pagePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Materials',
              style: compact
                  ? AddItemsStyles.pageTitleMobileStyle
                  : AddItemsStyles.pageTitleStyle,
            ),
            SizedBox(height: isMobile ? 1 : 4),
            Text(
              'Add supplier, brand, material, unit, price, quantity, and location.',
              maxLines: isMobile ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: AddItemsStyles.pageSubtitleStyle.copyWith(
                fontSize: isMobile
                    ? 11
                    : isTablet
                    ? 13
                    : 14,
              ),
            ),
            SizedBox(height: isMobile ? 4 : 12),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Container(
                    width: double.infinity,
                    height: cardHeight,
                    padding: EdgeInsets.all(cardPad),
                    decoration: AddItemsStyles.formCardDecoration,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        physics: isMobile
                            ? const BouncingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _twoCol(
                              gap: gap,
                              oneColumn: oneColumn,
                              left: _AutocompleteInputField(
                                controller: _supplierController,
                                options: _suppliers,
                                label: 'Supplier',
                                hintText: 'Select supplier',
                                icon: Icons.storefront_outlined,
                                validator: _requiredValidator,
                              ),
                              right: _AutocompleteInputField(
                                controller: _brandController,
                                options: _brands,
                                label: 'Brand Optional',
                                hintText: 'Enter brand',
                                icon: Icons.sell_outlined,
                              ),
                            ),
                            SizedBox(height: gap),
                            _InputField(
                              controller: _descriptionController,
                              label: 'Description',
                              hintText: 'Enter material description',
                              icon: Icons.inventory_2_outlined,
                              validator: _requiredValidator,
                            ),
                            SizedBox(height: gap),
                            _twoCol(
                              gap: gap,
                              oneColumn: oneColumn,
                              left: _AutocompleteInputField(
                                controller: _unitController,
                                options: _units,
                                label: 'Unit',
                                hintText: 'pc, bag, kg',
                                icon: Icons.category_outlined,
                                validator: _requiredValidator,
                              ),
                              right: _AutocompleteInputField(
                                controller: _unitValueController,
                                options: _unitValues,
                                label: 'Unit Value',
                                hintText: '1 or 0.5',
                                icon: Icons.scale_outlined,
                                keyboardType: TextInputType.number,
                                validator: _numberValidator,
                              ),
                            ),
                            SizedBox(height: gap),
                            _twoCol(
                              gap: gap,
                              oneColumn: oneColumn,
                              left: _InputField(
                                controller: _priceController,
                                label: 'Price',
                                hintText: 'Enter price',
                                icon: Icons.payments_outlined,
                                keyboardType: TextInputType.number,
                                validator: _numberValidator,
                                onChanged: (_) => setState(() {}),
                              ),
                              right: _InputField(
                                controller: _quantityController,
                                label: 'Quantity',
                                hintText: 'Enter qty',
                                icon: Icons.format_list_numbered_outlined,
                                keyboardType: TextInputType.number,
                                validator: _numberValidator,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(height: gap),
                            _AutocompleteInputField(
                              controller: _locationController,
                              options: _locations,
                              label: 'Location',
                              hintText: 'Type or select location',
                              icon: Icons.location_on_outlined,
                              validator: _requiredValidator,
                            ),
                            SizedBox(height: gap),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: isMobile
                                        ? 33
                                        : isTablet
                                        ? 44
                                        : 48,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: AddItemsStyles.totalDecoration,
                                    child: Text(
                                      'Total: ₱${_total.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: AddItemsStyles.textPrimary,
                                        fontSize: isMobile
                                            ? 11
                                            : isTablet
                                            ? 14
                                            : 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: gap),
                                SizedBox(
                                  width: isMobile
                                      ? 105
                                      : isTablet
                                      ? 150
                                      : 170,
                                  height: isMobile
                                      ? 33
                                      : isTablet
                                      ? 44
                                      : 48,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveItem,
                                    style: AddItemsStyles.saveButtonStyle,
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            'Save',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: isMobile ? 11 : 14,
                                              color: Colors.black,
                                            ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(
          color: AddItemsStyles.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        decoration: AddItemsStyles.inputDecoration(
          hintText: hintText,
          prefixIcon: icon,
        ),
      ),
    );
  }
}

class _AutocompleteInputField extends StatefulWidget {
  final TextEditingController controller;
  final List<String> options;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AutocompleteInputField({
    required this.controller,
    required this.options,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_AutocompleteInputField> createState() =>
      _AutocompleteInputFieldState();
}

class _AutocompleteInputFieldState extends State<_AutocompleteInputField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return widget.options;
        return widget.options.where(
          (option) => option.toLowerCase().contains(query),
        );
      },
      onSelected: (String selected) => widget.controller.text = selected,
      fieldViewBuilder: (context, textController, node, onSubmitted) {
        return _FieldShell(
          label: widget.label,
          child: TextFormField(
            controller: textController,
            focusNode: node,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: const TextStyle(
              color: AddItemsStyles.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            decoration: AddItemsStyles.inputDecoration(
              hintText: widget.hintText,
              prefixIcon: widget.icon,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, suggestions) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: const Color(0xFF07140F),
            elevation: 12,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150, maxWidth: 420),
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
                      style: const TextStyle(
                        color: AddItemsStyles.textPrimary,
                        fontSize: 12,
                      ),
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

class _FieldShell extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldShell({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AddItemsStyles.labelStyle.copyWith(
            fontSize: isMobile ? 10 : 12,
          ),
        ),
        SizedBox(height: isMobile ? 2 : 4),
        child,
      ],
    );
  }
}
