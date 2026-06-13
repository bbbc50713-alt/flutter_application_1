import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../utils/utils.dart';

class CustomerInfoResult {
  final Customer customer;
  final int cellCount;
  final int testDuration;

  CustomerInfoResult({
    required this.customer,
    required this.cellCount,
    required this.testDuration,
  });
}

class CustomerInfoDialog extends StatefulWidget {
  const CustomerInfoDialog({super.key});

  @override
  State<CustomerInfoDialog> createState() => _CustomerInfoDialogState();

  static Future<CustomerInfoResult?> show(BuildContext context) {
    return showDialog<CustomerInfoResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CustomerInfoDialog(),
    );
  }
}

class _CustomerInfoDialogState extends State<CustomerInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();

  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _batteryNumberController = TextEditingController();
  final _batteryInfoController = TextEditingController();

  List<Customer> _searchResults = [];
  bool _showSearchResults = false;
  String? _selectedCustomerId;
  int _cellCount = 24;
  int _testDuration = 6;

  @override
  void dispose() {
    _companyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _batteryNumberController.dispose();
    _batteryInfoController.dispose();
    super.dispose();
  }

  void _onCompanyChanged(String value) async {
    if (value.length >= 2) {
      final results = await _db.searchCustomers(value);
      setState(() {
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
      });
    } else {
      setState(() {
        _showSearchResults = false;
      });
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomerId = customer.id;
      _companyController.text = customer.companyName;
      _addressController.text = customer.companyAddress;
      _phoneController.text = customer.phoneNumber;
      _emailController.text = customer.email;
      _showSearchResults = false;
    });
  }

  void _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      final companyName = _companyController.text.trim();
      final email = _emailController.text.trim();

      Customer customer;

      if (_selectedCustomerId != null) {
        customer = Customer(
          id: _selectedCustomerId!,
          companyName: companyName,
          companyAddress: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: email,
          batteryNumber: _batteryNumberController.text.trim(),
          batteryInfo: _batteryInfoController.text.trim(),
        );
        await _db.updateCustomer(customer);
      } else {
        final existing = await _db.findDuplicateCustomer(companyName, email);
        if (existing != null) {
          customer = Customer(
            id: existing.id,
            companyName: companyName,
            companyAddress: _addressController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            email: email,
            batteryNumber: _batteryNumberController.text.trim(),
            batteryInfo: _batteryInfoController.text.trim(),
          );
          await _db.updateCustomer(customer);
        } else {
          customer = Customer(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            companyName: companyName,
            companyAddress: _addressController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            email: email,
            batteryNumber: _batteryNumberController.text.trim(),
            batteryInfo: _batteryInfoController.text.trim(),
          );
          await _db.insertCustomer(customer);
        }
      }

      Navigator.of(context).pop(CustomerInfoResult(
        customer: customer,
        cellCount: _cellCount,
        testDuration: _testDuration,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.customerInfo),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: AppStrings.companyName,
                  hintText: 'Enter company name',
                  suffixIcon: _showSearchResults
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _showSearchResults = false),
                        )
                      : const Icon(Icons.search),
                ),
                validator: Validators.required,
                onChanged: _onCompanyChanged,
                textInputAction: TextInputAction.next,
              ),

              if (_showSearchResults)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _searchResults.map((customer) {
                        return ListTile(
                          dense: true,
                          title: Text(customer.companyName),
                          subtitle: Text(customer.email),
                          onTap: () => _selectCustomer(customer),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Company Address',
                  hintText: 'Enter company address',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Customer Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Customer Email',
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _batteryNumberController,
                decoration: const InputDecoration(
                  labelText: AppStrings.batteryNumber,
                  hintText: 'Enter battery number',
                ),
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _batteryInfoController,
                decoration: const InputDecoration(
                  labelText: AppStrings.batteryInfo,
                  hintText: 'Enter battery information',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _cellCount,
                      decoration: const InputDecoration(
                        labelText: 'Number of Cells',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: List.generate(
                        (AppConstants.maxCells - AppConstants.minCells) ~/ 2 + 1,
                        (index) => AppConstants.minCells + (index * 2),
                      ).map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value cells'),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _cellCount = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _testDuration,
                      decoration: const InputDecoration(
                        labelText: 'Test Duration',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: List.generate(
                        AppConstants.maxHours - AppConstants.minHours + 1,
                        (index) => AppConstants.minHours + index,
                      ).map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value hours'),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _testDuration = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text(AppStrings.ok),
        ),
      ],
    );
  }
}
