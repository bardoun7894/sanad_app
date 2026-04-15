import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class CountryCode {
  final String name;
  final String dialCode;
  final String flag;
  final String code;

  const CountryCode({
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.code,
  });
}

const List<CountryCode> countryCodes = [
  CountryCode(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦', code: 'SA'),
  CountryCode(name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪', code: 'AE'),
  CountryCode(name: 'Kuwait', dialCode: '+965', flag: '🇰🇼', code: 'KW'),
  CountryCode(name: 'Qatar', dialCode: '+974', flag: '🇶🇦', code: 'QA'),
  CountryCode(name: 'Bahrain', dialCode: '+973', flag: '🇧🇭', code: 'BH'),
  CountryCode(name: 'Oman', dialCode: '+968', flag: '🇴🇲', code: 'OM'),
  CountryCode(name: 'Egypt', dialCode: '+20', flag: '🇪🇬', code: 'EG'),
  CountryCode(name: 'Jordan', dialCode: '+962', flag: '🇯🇴', code: 'JO'),
  CountryCode(name: 'Lebanon', dialCode: '+961', flag: '🇱🇧', code: 'LB'),
  CountryCode(name: 'Morocco', dialCode: '+212', flag: '🇲🇦', code: 'MA'),
  CountryCode(name: 'Algeria', dialCode: '+213', flag: '🇩🇿', code: 'DZ'),
  CountryCode(name: 'Tunisia', dialCode: '+216', flag: '🇹🇳', code: 'TN'),
  CountryCode(name: 'Iraq', dialCode: '+964', flag: '🇮🇶', code: 'IQ'),
  CountryCode(name: 'Syria', dialCode: '+963', flag: '🇸🇾', code: 'SY'),
  CountryCode(name: 'Palestine', dialCode: '+970', flag: '🇵🇸', code: 'PS'),
  CountryCode(name: 'Yemen', dialCode: '+967', flag: '🇾🇪', code: 'YE'),
  CountryCode(name: 'Libya', dialCode: '+218', flag: '🇱🇾', code: 'LY'),
  CountryCode(name: 'Sudan', dialCode: '+249', flag: '🇸🇩', code: 'SD'),
  CountryCode(name: 'United States', dialCode: '+1', flag: '🇺🇸', code: 'US'),
  CountryCode(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧', code: 'GB'),
  CountryCode(name: 'France', dialCode: '+33', flag: '🇫🇷', code: 'FR'),
  CountryCode(name: 'Germany', dialCode: '+49', flag: '🇩🇪', code: 'DE'),
  CountryCode(name: 'Turkey', dialCode: '+90', flag: '🇹🇷', code: 'TR'),
  CountryCode(name: 'Pakistan', dialCode: '+92', flag: '🇵🇰', code: 'PK'),
  CountryCode(name: 'India', dialCode: '+91', flag: '🇮🇳', code: 'IN'),
];

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final ValueChanged<CountryCode>? onCountryChanged;
  final CountryCode? initialCountry;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.onCountryChanged,
    this.initialCountry,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late CountryCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? countryCodes.first; // Saudi Arabia default
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Country',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: countryCodes.length,
                itemBuilder: (context, index) {
                  final country = countryCodes[index];
                  final isSelected = country.code == _selectedCountry.code;
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country.dialCode,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check, color: AppColors.primary),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                      widget.onCountryChanged?.call(country);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
          decoration: InputDecoration(
            hintText: widget.hint,
            hintTextDirection: TextDirection.ltr,
            prefixIcon: InkWell(
              onTap: _showCountryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountry.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCountry.dialCode,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: isDark ? Colors.white24 : Colors.black12,
                      margin: const EdgeInsets.only(left: 8),
                    ),
                  ],
                ),
              ),
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          validator: widget.validator,
        ),
      ],
    );
  }

  String get fullPhoneNumber => '${_selectedCountry.dialCode}${widget.controller.text}';
  CountryCode get selectedCountry => _selectedCountry;
}
