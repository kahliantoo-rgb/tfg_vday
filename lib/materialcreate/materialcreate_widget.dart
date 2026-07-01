import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/material_category_helpers.dart';
import '/backend/material_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/nav/nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'materialcreate_model.dart';
export 'materialcreate_model.dart';

class MaterialcreateWidget extends StatefulWidget {
  const MaterialcreateWidget({
    super.key,
    this.materialRef,
  });

  final DocumentReference? materialRef;

  static String routeName = 'Materialcreate';
  static String routePath = '/materialcreate';

  @override
  State<MaterialcreateWidget> createState() => _MaterialcreateWidgetState();
}

class _MaterialcreateWidgetState extends State<MaterialcreateWidget> {
  late MaterialcreateModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late final DocumentReference _draftMaterialRef;
  String? _hydratedMaterialId;
  bool _saving = false;

  bool get _isEdit => widget.materialRef != null;

  @override
  void initState() {
    super.initState();
    _draftMaterialRef =
        widget.materialRef ?? MaterialRecord.collection.doc();
    _model = createModel(context, () => MaterialcreateModel());
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();
    _model.skuTextController ??= TextEditingController();
    _model.skuFocusNode ??= FocusNode();
    _model.costTextController ??= TextEditingController();
    _model.costFocusNode ??= FocusNode();
    _model.unitValue ??= defaultMaterialUnits.first;
    _model.unitValueController ??=
        FormFieldController<String>(_model.unitValue);
    _model.categoryValueController ??=
        FormFieldController<String>(_model.categoryValue);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _hydrateFromMaterial(MaterialRecord material) {
    if (_hydratedMaterialId == material.reference.id) {
      return;
    }
    _hydratedMaterialId = material.reference.id;
    _model.nameTextController?.text = material.name;
    _model.skuTextController?.text = material.sku;
    if (material.cost > 0) {
      _model.costTextController?.text = material.cost.toStringAsFixed(2);
    }
    _model.switchValue = material.isActive;
    _model.unitValue = material.unit.isNotEmpty
        ? material.unit
        : defaultMaterialUnits.first;
    _model.unitValueController?.value = _model.unitValue;
    if (material.category.isNotEmpty) {
      _model.categoryValue = material.category;
      _model.categoryValueController?.value = material.category;
    }
  }

  Future<void> _save(MaterialRecord? existing) async {
    if (_saving) {
      return;
    }
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }
    if (!canCreateProducts(AppStateNotifier.instance.userRole)) {
      return;
    }
    if (!ensureActiveCompanyForWrite(context)) {
      return;
    }

    setState(() => _saving = true);
    final cost = double.tryParse(_model.costTextController!.text.trim());
    final error = await saveMaterialRecord(
      ref: existing?.reference ?? _draftMaterialRef,
      name: _model.nameTextController!.text,
      unit: _model.unitValue ?? defaultMaterialUnits.first,
      sku: _model.skuTextController!.text,
      cost: cost,
      isActive: _model.switchValue,
      category: _model.categoryValue,
      existing: existing,
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? tr(context, 'material.snack.created')
              : tr(context, 'material.snack.saved'),
        ),
      ),
    );
    context.pop();
  }

  Future<void> _delete(MaterialRecord material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'material.delete.title')),
        content: Text(
          tr(context, 'material.delete.body',
              params: {'name': material.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, 'common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final error = await deleteMaterialRecord(material);
    if (!mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    context.pop();
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
    );
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
        key: scaffoldKey,
        backgroundColor: theme.secondaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _isEdit
                ? tr(context, 'material.edit.title')
                : tr(context, 'material.create.title'),
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(),
              color: Colors.white,
              fontSize: 22,
            ),
          ),
          actions: const [AppBarLanguageHomeActions()],
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isEdit
              ? StreamBuilder<MaterialRecord>(
                  stream: MaterialRecord.getDocument(widget.materialRef!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final material = snapshot.data!;
                    _hydrateFromMaterial(material);
                    return _form(context, material);
                  },
                )
              : _form(context, null),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, MaterialRecord? existing) {
    final theme = FlutterFlowTheme.of(context);
    final unitOptions = [
      ...defaultMaterialUnits,
      if (_model.unitValue != null &&
          _model.unitValue!.isNotEmpty &&
          !defaultMaterialUnits.contains(_model.unitValue))
        _model.unitValue!,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _model.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _model.nameTextController,
              focusNode: _model.nameFocusNode,
              decoration: _fieldDecoration(tr(context, 'material.form.name')),
              validator: _model.nameTextControllerValidator.asValidator(context),
            ),
            const SizedBox(height: 12),
            FlutterFlowDropDown<String>(
              controller: _model.unitValueController ??=
                  FormFieldController<String>(_model.unitValue),
              options: unitOptions,
              onChanged: (val) => setState(() => _model.unitValue = val),
              width: double.infinity,
              height: 48,
              textStyle: theme.bodyMedium,
              hintText: tr(context, 'material.form.unit'),
              fillColor: theme.secondaryBackground,
              elevation: 0,
              borderColor: theme.alternate,
              borderWidth: 1,
              borderRadius: 8,
              margin: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<String>>(
              stream: streamTenantMaterialCategories(),
              builder: (context, categorySnapshot) {
                final categoryOptions = List<String>.from(
                  categorySnapshot.data ?? defaultMaterialCategories,
                );
                if (_model.categoryValue != null &&
                    _model.categoryValue!.isNotEmpty &&
                    !categoryOptions.contains(_model.categoryValue)) {
                  categoryOptions.add(_model.categoryValue!);
                }
                return FlutterFlowDropDown<String>(
                  controller: _model.categoryValueController ??=
                      FormFieldController<String>(_model.categoryValue),
                  options: categoryOptions,
                  onChanged: (val) => setState(() => _model.categoryValue = val),
                  width: double.infinity,
                  height: 48,
                  textStyle: theme.bodyMedium,
                  hintText: tr(context, 'material.form.categoryOptional'),
                  fillColor: theme.secondaryBackground,
                  elevation: 0,
                  borderColor: theme.alternate,
                  borderWidth: 1,
                  borderRadius: 8,
                  margin: EdgeInsets.zero,
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model.skuTextController,
              focusNode: _model.skuFocusNode,
              decoration: _fieldDecoration(tr(context, 'material.form.skuOptional')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _model.costTextController,
              focusNode: _model.costFocusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration:
                  _fieldDecoration(tr(context, 'material.form.costOptional')),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(context, 'common.active')),
              value: _model.switchValue,
              onChanged: (value) => setState(() => _model.switchValue = value),
            ),
            const SizedBox(height: 24),
            FFButtonWidget(
              onPressed: _saving ? null : () => _save(existing),
              text: _saving
                  ? tr(context, 'common.saving')
                  : (_isEdit
                      ? tr(context, 'common.save')
                      : tr(context, 'common.create')),
              options: FFButtonOptions(
                width: double.infinity,
                height: 48,
                color: theme.primary,
                textStyle: theme.titleMedium.override(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            if (existing != null &&
                canEditProducts(AppStateNotifier.instance.userRole)) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _saving ? null : () => _delete(existing),
                child: Text(
                  tr(context, 'material.delete.button'),
                  style: TextStyle(color: theme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
