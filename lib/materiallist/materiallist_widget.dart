import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/material_category_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'materiallist_model.dart';
export 'materiallist_model.dart';

class MateriallistWidget extends StatefulWidget {
  const MateriallistWidget({
    super.key,
    this.materialRef,
  });

  final DocumentReference? materialRef;

  static String routeName = 'Materiallist';
  static String routePath = '/materiallist';

  @override
  State<MateriallistWidget> createState() => _MateriallistWidgetState();
}

class _MateriallistWidgetState extends State<MateriallistWidget> {
  late MateriallistModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String _materialSubtitle(BuildContext context, MaterialRecord material) {
    final parts = <String>[];
    if (material.category.isNotEmpty) {
      parts.add(material.category);
    }
    if (material.unit.isNotEmpty) {
      parts.add(tr(context, 'material.line.unit',
          params: {'unit': material.unit}));
    }
    if (material.sku.isNotEmpty) {
      parts.add(tr(context, 'material.line.sku',
          params: {'sku': material.sku}));
    }
    if (material.cost > 0) {
      parts.add(tr(context, 'material.line.cost',
          params: {'cost': material.cost.toStringAsFixed(2)}));
    }
    return parts.join(' · ');
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MateriallistModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 30.0,
            buttonSize: 60.0,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            tr(context, 'material.list.title'),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(),
                  color: Colors.white,
                  fontSize: 22.0,
                ),
          ),
          actions: const [AppBarLanguageHomeActions()],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(context, 'material.list.heading'),
                        style: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .override(
                              font: GoogleFonts.interTight(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      ),
                    ),
                    if (canEditProducts(AppStateNotifier.instance.userRole))
                      FlutterFlowIconButton(
                        borderRadius: 20.0,
                        buttonSize: 40.0,
                        icon: Icon(
                          Icons.category_outlined,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 24.0,
                        ),
                        onPressed: () =>
                            showManageMaterialCategoriesDialog(context),
                      ),
                    if (canCreateProducts(AppStateNotifier.instance.userRole))
                      FlutterFlowIconButton(
                        borderRadius: 20.0,
                        buttonSize: 40.0,
                        icon: Icon(
                          Icons.add_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 24.0,
                        ),
                        onPressed: () =>
                            context.pushNamed(MaterialcreateWidget.routeName),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MaterialRecord>>(
                  stream: queryTenantMaterialRecord().map((materials) {
                    final sorted = [...materials];
                    sorted.sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );
                    return sorted;
                  }),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          tr(context, 'common.errorDetail',
                              params: {'error': '${snapshot.error}'}),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      );
                    }
                    final materials = snapshot.data!;
                    if (materials.isEmpty) {
                      return Center(
                        child: Text(tr(context, 'material.list.empty')),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: materials.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final material = materials[index];
                        return Opacity(
                          opacity: material.isActive ? 1 : 0.6,
                          child: Card(
                            child: ListTile(
                              title: Text(material.name),
                              subtitle: Text(
                                _materialSubtitle(context, material),
                              ),
                              trailing: material.isActive
                                  ? null
                                  : Chip(
                                      label: Text(
                                        tr(context, 'common.inactive'),
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall,
                                      ),
                                    ),
                              onTap: canEditProducts(
                                AppStateNotifier.instance.userRole,
                              )
                                  ? () => context.pushNamed(
                                        MaterialcreateWidget.routeName,
                                        queryParameters: {
                                          'materialRef': serializeParam(
                                            material.reference,
                                            ParamType.DocumentReference,
                                          ),
                                        }.withoutNulls,
                                        extra: <String, dynamic>{
                                          'materialRef': material.reference,
                                        },
                                      )
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
