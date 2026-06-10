import '/backend/schema/enums/enums.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/nav/nav.dart';

/// Resolves the signed-in user's role for permission checks.
UserRole? currentViewerRole() => AppStateNotifier.instance.effectiveUserRole;
