import '/app_branding.dart';
import '/backend/user_registration_request_helpers.dart';
import '/components/customer_birthday_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import '/index.dart';
import '/l10n/locale_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_signup_page_model.dart';
export 'user_signup_page_model.dart';

class UserSignupPageWidget extends StatefulWidget {
  const UserSignupPageWidget({super.key});

  static String routeName = 'UserSignupPage';
  static String routePath = '/userSignup';

  @override
  State<UserSignupPageWidget> createState() => _UserSignupPageWidgetState();
}

class _UserSignupPageWidgetState extends State<UserSignupPageWidget> {
  late UserSignupPageModel _model;
  String? _formMessage;
  bool _formMessageIsError = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserSignupPageModel());
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();
    _model.phoneTextController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.companyNameTextController ??= TextEditingController();
    _model.companyNameFocusNode ??= FocusNode();
    _model.companyUenTextController ??= TextEditingController();
    _model.companyUenFocusNode ??= FocusNode();
    _model.companyAddressTextController ??= TextEditingController();
    _model.companyAddressFocusNode ??= FocusNode();
    _model.companyPhoneTextController ??= TextEditingController();
    _model.companyPhoneFocusNode ??= FocusNode();
    _model.companyEmailTextController ??= TextEditingController();
    _model.companyEmailFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: FlutterFlowTheme.of(context).labelLarge,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 24.0),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    setState(() {
      _formMessage = message;
      _formMessageIsError = isError;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickLogo() async {
    final selectedMedia = await selectMediaWithSourceBottomSheet(
      context: context,
      allowPhoto: true,
    );
    if (selectedMedia == null ||
        selectedMedia.isEmpty ||
        !selectedMedia.every(
          (m) => validateFileFormat(m.storagePath, context),
        )) {
      return;
    }
    final media = selectedMedia.first;
    setState(() {
      _model.pickedLogoBytes = media.bytes;
      _model.pickedLogoFilename = media.storagePath.split('/').last;
      _model.logoPreviewPath = media.storagePath;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _formMessage = null);

    if (!_model.formKey.currentState!.validate()) {
      _showMessage(
        loc(context, en: 'Please complete all required fields.', zh: '请填写所有必填项。'),
        isError: true,
      );
      return;
    }

    final email = _model.emailTextController!.text.trim();
    final requestId = userRegistrationRequestDocId(email);
    final accountType = _model.isCompanyAccount
        ? UserSignupAccountType.company
        : UserSignupAccountType.private;

    setState(() => _model.saving = true);
    try {
      String? logoUrl;
      if (_model.isCompanyAccount &&
          _model.pickedLogoBytes != null &&
          _model.pickedLogoFilename != null) {
        setState(() => _model.uploadingLogo = true);
        logoUrl = await uploadUserRegistrationLogo(
          requestId: requestId,
          bytes: _model.pickedLogoBytes!,
          filename: _model.pickedLogoFilename!,
        );
        if (logoUrl == null) {
          _showMessage(
            loc(
              context,
              en: 'Logo upload failed. Try again or submit without a logo.',
              zh: 'Logo 上传失败，请重试或不带 Logo 提交。',
            ),
            isError: true,
          );
          return;
        }
      }

      final result = await submitUserRegistrationRequest(
        name: _model.nameTextController!.text,
        phone: _model.phoneTextController!.text,
        email: email,
        birthday: _model.birthday,
        accountType: accountType,
        companyName: _model.companyNameTextController?.text,
        companyUen: _model.companyUenTextController?.text,
        companyAddress: _model.companyAddressTextController?.text,
        companyPhone: _model.companyPhoneTextController?.text,
        companyEmail: _model.companyEmailTextController?.text,
        companyLogoUrl: logoUrl,
      );

      if (!mounted) {
        return;
      }
      if (!result.success) {
        _showMessage(
          result.errorMessage ??
              loc(context, en: 'Registration failed.', zh: '注册提交失败。'),
          isError: true,
        );
        return;
      }

      _showMessage(
        loc(
          context,
          en: 'Registration submitted. Please wait for admin approval before logging in.',
          zh: '注册申请已提交，请等待管理员审核后再登录。',
        ),
        isError: false,
      );
      context.go(LoginPageWidget.routePath);
    } finally {
      if (mounted) {
        setState(() {
          _model.saving = false;
          _model.uploadingLogo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.secondaryBackground,
        appBar: AppBar(
          backgroundColor: theme.secondaryBackground,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.primaryText),
            onPressed: () => context.go(LoginPageWidget.routePath),
          ),
          title: Text(
            loc(context, en: 'Sign up · $kProductName', zh: '注册 · $kProductName'),
            style: theme.titleLarge,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _model.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        loc(
                          context,
                          en: 'Create your account request',
                          zh: '填写注册信息',
                        ),
                        style: theme.headlineMedium.override(
                          font: GoogleFonts.interTight(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        child: Text(
                          loc(
                            context,
                            en: 'Submit your details. An administrator will review and activate your account.',
                            zh: '提交资料后，管理员审核通过即可登录。',
                          ),
                          style: theme.labelMedium,
                        ),
                      ),
                      if (_formMessage != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (_formMessageIsError ? theme.error : theme.success)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  _formMessageIsError ? theme.error : theme.success,
                            ),
                          ),
                          child: Text(
                            _formMessage!,
                            style: theme.bodyMedium.override(
                              color:
                                  _formMessageIsError ? theme.error : theme.success,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        loc(context, en: 'Personal details', zh: '个人资料'),
                        style: theme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _model.nameTextController,
                        focusNode: _model.nameFocusNode,
                        decoration: _fieldDecoration(
                          context,
                          loc(context, en: 'Full name *', zh: '姓名 *'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc(context, en: 'Required', zh: '必填');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _model.phoneTextController,
                        focusNode: _model.phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        decoration: _fieldDecoration(
                          context,
                          loc(context, en: 'Phone *', zh: '电话 *'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc(context, en: 'Required', zh: '必填');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _model.emailTextController,
                        focusNode: _model.emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: _fieldDecoration(
                          context,
                          loc(context, en: 'Email *', zh: '邮箱 *'),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty || !trimmed.contains('@')) {
                            return loc(
                              context,
                              en: 'Enter a valid email',
                              zh: '请输入有效邮箱',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomerBirthdayPickerTile(
                        birthday: _model.birthday,
                        labelText: loc(context, en: 'Birthday', zh: '生日'),
                        onChanged: (value) => setState(() => _model.birthday = value),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        loc(context, en: 'Account type', zh: '账户类型'),
                        style: theme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(loc(context, en: 'Private', zh: '私人')),
                            icon: const Icon(Icons.person_outline),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(loc(context, en: 'Company', zh: '公司')),
                            icon: const Icon(Icons.business_outlined),
                          ),
                        ],
                        selected: {_model.isCompanyAccount},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _model.isCompanyAccount = selection.first;
                          });
                        },
                      ),
                      if (_model.isCompanyAccount) ...[
                        const SizedBox(height: 24),
                        Text(
                          loc(context, en: 'Company details', zh: '公司资料'),
                          style: theme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _model.companyNameTextController,
                          focusNode: _model.companyNameFocusNode,
                          decoration: _fieldDecoration(
                            context,
                            loc(context, en: 'Company name *', zh: '公司名称 *'),
                          ),
                          validator: (value) {
                            if (!_model.isCompanyAccount) {
                              return null;
                            }
                            if (value == null || value.trim().isEmpty) {
                              return loc(context, en: 'Required', zh: '必填');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _model.companyUenTextController,
                          focusNode: _model.companyUenFocusNode,
                          decoration: _fieldDecoration(
                            context,
                            loc(
                              context,
                              en: 'Company registration no.',
                              zh: '公司注册号',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _model.companyAddressTextController,
                          focusNode: _model.companyAddressFocusNode,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _fieldDecoration(
                            context,
                            loc(context, en: 'Address', zh: '地址'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _model.companyPhoneTextController,
                          focusNode: _model.companyPhoneFocusNode,
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration(
                            context,
                            loc(context, en: 'Company phone', zh: '公司电话'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _model.companyEmailTextController,
                          focusNode: _model.companyEmailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _fieldDecoration(
                            context,
                            loc(context, en: 'Company email', zh: '公司邮箱'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc(context, en: 'Company logo', zh: '公司 Logo'),
                          style: theme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: theme.primaryBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.alternate),
                              ),
                              child: _model.pickedLogoBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _model.pickedLogoBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.storefront,
                                      color: theme.secondaryText,
                                      size: 36,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FFButtonWidget(
                                onPressed: (_model.saving || _model.uploadingLogo)
                                    ? null
                                    : _pickLogo,
                                text: loc(
                                  context,
                                  en: 'Upload logo',
                                  zh: '上传 Logo',
                                ),
                                options: FFButtonOptions(
                                  height: 44,
                                  color: theme.primaryBackground,
                                  textStyle: theme.titleSmall.override(
                                    color: theme.primaryText,
                                  ),
                                  borderSide: BorderSide(color: theme.alternate),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      FFButtonWidget(
                        onPressed: (_model.saving || _model.uploadingLogo)
                            ? null
                            : _submit,
                        text: _model.saving
                            ? loc(context, en: 'Submitting…', zh: '提交中…')
                            : loc(context, en: 'Submit registration', zh: '提交注册'),
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 52,
                          color: theme.primary,
                          textStyle: theme.titleSmall.override(
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go(LoginPageWidget.routePath),
                        child: Text(
                          loc(
                            context,
                            en: 'Already have an account? Log in',
                            zh: '已有账号？返回登录',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
