import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moyasar/moyasar.dart';
import 'package:moyasar/src/models/card_form_model.dart';
import 'package:moyasar/src/utils/card_utils.dart';
import 'package:moyasar/src/utils/input_formatters.dart';
import 'package:moyasar/src/widgets/network_icons.dart';

/// The widget that shows the Credit Card form and manages the 3DS step.
class CustomCreditCard extends StatefulWidget {
  const CustomCreditCard(
      {super.key,
      this.checkValidation = false,
      required this.onCreditCardFormChange,
      this.horizontalExpiryAndCvv = false,
      this.locale = const Localization.en()});

  final void Function(CardFormModel cardData, bool isValid)
      onCreditCardFormChange;
  final Localization locale;
  final bool checkValidation;
  final bool horizontalExpiryAndCvv;

  @override
  State<CustomCreditCard> createState() => _CustomCreditCardState();
}

class _CustomCreditCardState extends State<CustomCreditCard> {
  final _cardData = CardFormModel();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  bool _isValidForm() {
    if (widget.checkValidation || !_cardData.oneOrMoreIsEmpty()) {
      bool isValidForm =
          _formKey.currentState != null && _formKey.currentState!.validate();

      if (!isValidForm) {
        setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
        return false;
      }

      _formKey.currentState?.save();

      return isValidForm;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant CustomCreditCard oldWidget) {
    if (widget.checkValidation) {
      _isValidForm();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: _autoValidateMode,
      key: _formKey,
      child: Column(
        children: [
          CardFormField(
              inputDecoration: buildInputDecoration(
                hintText: widget.locale.nameOnCard,
              ),
              keyboardType: TextInputType.text,
              validator: (String? input) =>
                  CardUtils.validateName(input, widget.locale),
              onSaved: (value) {
                _cardData.name = value ?? '';
                widget.onCreditCardFormChange(_cardData, _isValidForm());
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z. ]')),
              ]),
          CardFormField(
              inputDecoration: buildInputDecoration(
                  hintText: widget.locale.cardNumber, addNetworkIcons: true),
              validator: (String? input) =>
                  CardUtils.validateCardNum(input, widget.locale),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                CardNumberInputFormatter(),
              ],
              onSaved: (value) {
                _cardData.number = CardUtils.getCleanedNumber(value!);
                widget.onCreditCardFormChange(_cardData, _isValidForm());
              }),
          if (widget.horizontalExpiryAndCvv)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CardFormField(
                    inputDecoration: buildInputDecoration(
                      hintText: '${widget.locale.expiry} (MM / YY)',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      CardMonthInputFormatter(),
                    ],
                    validator: (String? input) =>
                        CardUtils.validateDate(input, widget.locale),
                    onSaved: (value) {
                      List<String> expireDate = CardUtils.getExpiryDate(value!);
                      if (expireDate.length == 2) {
                        _cardData.month = expireDate.first;
                        _cardData.year = expireDate[1];
                      }
                      widget.onCreditCardFormChange(_cardData, _isValidForm());
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: CardFormField(
                      inputDecoration: buildInputDecoration(
                        hintText: widget.locale.cvc,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (String? input) =>
                          CardUtils.validateCVC(input, widget.locale),
                      onSaved: (value) {
                        _cardData.cvc = value ?? '';
                        widget.onCreditCardFormChange(
                            _cardData, _isValidForm());
                      }),
                ),
              ],
            )
          else ...[
            CardFormField(
              inputDecoration: buildInputDecoration(
                hintText: '${widget.locale.expiry} (MM / YY)',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
                CardMonthInputFormatter(),
              ],
              validator: (String? input) =>
                  CardUtils.validateDate(input, widget.locale),
              onSaved: (value) {
                List<String> expireDate = CardUtils.getExpiryDate(value!);
                if (expireDate.length == 2) {
                  _cardData.month = expireDate.first;
                  _cardData.year = expireDate[1];
                }
                widget.onCreditCardFormChange(_cardData, _isValidForm());
              },
            ),
            CardFormField(
                inputDecoration: buildInputDecoration(
                  hintText: widget.locale.cvc,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (String? input) =>
                    CardUtils.validateCVC(input, widget.locale),
                onSaved: (value) {
                  _cardData.cvc = value ?? '';
                  widget.onCreditCardFormChange(_cardData, _isValidForm());
                }),
          ],
        ],
      ),
    );
  }
}

class CardFormField extends StatelessWidget {
  final void Function(String?)? onSaved;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? inputDecoration;

  const CardFormField({
    Key? key,
    required this.onSaved,
    this.validator,
    this.inputDecoration,
    this.keyboardType = TextInputType.number,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: inputDecoration,
          validator: validator,
          onChanged: (value) {
            onSaved?.call(value);
          },
          inputFormatters: inputFormatters),
    );
  }
}

String showAmount(int amount, Localization locale) {
  final formattedAmount = (amount / 100).toStringAsFixed(2);

  if (locale.languageCode == 'en') {
    return '${locale.pay} SAR $formattedAmount';
  }

  return '${locale.pay} $formattedAmount ر.س';
}

InputDecoration buildInputDecoration(
    {required String hintText, bool addNetworkIcons = false}) {
  return InputDecoration(
      suffixIcon: addNetworkIcons ? const NetworkIcons() : null,
      hintText: hintText,
      focusedErrorBorder: defaultErrorBorder,
      enabledBorder: defaultEnabledBorder,
      focusedBorder: defaultFocusedBorder,
      errorBorder: defaultErrorBorder);
}

void closeKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

BorderRadius defaultBorderRadius = const BorderRadius.all(Radius.circular(8));

OutlineInputBorder defaultEnabledBorder = OutlineInputBorder(
    borderSide: BorderSide(color: Colors.grey[400]!),
    borderRadius: defaultBorderRadius);

OutlineInputBorder defaultFocusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: Colors.grey[600]!),
    borderRadius: defaultBorderRadius);

OutlineInputBorder defaultErrorBorder = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.red),
    borderRadius: defaultBorderRadius);
