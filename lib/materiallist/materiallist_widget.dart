import '/auth/role_helpers.dart';
import '/backend/backend.dart';
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
            'Materials',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(),
                  color: Colors.white,
                  fontSize: 22.0,
                ),
          ),
          actions: const [HomeNavIconButton.onPrimary()],
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
                        'Material List',
                        style: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .override(
                              font: GoogleFonts.interTight(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      ),
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
                      return Center(child: Text('Error: ${snapshot.error}'));
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
                      return const Center(child: Text('No materials yet'));
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
                                [
                                  if (material.unit.isNotEmpty)
                                    'Unit: ${material.unit}',
                                  if (material.sku.isNotEmpty)
                                    'SKU: ${material.sku}',
                                  if (material.cost > 0)
                                    'Cost: ${material.cost.toStringAsFixed(2)}',
                                ].join(' · '),
                              ),
                              trailing: material.isActive
                                  ? null
                                  : Chip(
                                      label: Text(
                                        'Inactive',
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
