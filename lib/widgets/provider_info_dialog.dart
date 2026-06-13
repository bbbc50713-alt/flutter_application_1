import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

class ProviderInfoDialog extends StatefulWidget {
  final ServiceProvider? existingProvider;

  const ProviderInfoDialog({
    super.key,
    this.existingProvider,
  });

  @override
  State<ProviderInfoDialog> createState() => _ProviderInfoDialogState();

  static Future<ServiceProvider?> show(BuildContext context, {ServiceProvider? existing}) {
    return showDialog<ServiceProvider>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProviderInfoDialog(existingProvider: existing),
    );
  }
}

class _ProviderInfoDialogState extends State<ProviderInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.existingProvider?.companyName ?? '');
    _addressController = TextEditingController(text: widget.existingProvider?.address ?? '');
    _phoneController = TextEditingController(text: widget.existingProvider?.phoneNumber ?? '');
    _emailController = TextEditingController(text: widget.existingProvider?.email ?? '');
  }

  @override
  void dispose() {
    _companyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = ServiceProvider(
        id: widget.existingProvider?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        companyName: _companyController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: widget.existingProvider?.createdAt,
      );

      context.read<TestProvider>().saveProvider(provider);
      Navigator.of(context).pop(provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.providerInfo),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: AppStrings.companyName,
                  hintText: 'Enter company name',
                ),
                validator: Validators.required,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: AppStrings.address,
                  hintText: 'Enter address',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: AppStrings.phoneNumber,
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: AppStrings.email,
                  hintText: 'Enter email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                textInputAction: TextInputAction.done,
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
