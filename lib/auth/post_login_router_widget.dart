import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/auth/auth_redirect.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/user_list_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';

/// Redirects authenticated users to the correct home route by role.
class PostLoginRouterWidget extends StatefulWidget {
  const PostLoginRouterWidget({super.key});

  @override
  State<PostLoginRouterWidget> createState() => _PostLoginRouterWidgetState();
}

class _PostLoginRouterWidgetState extends State<PostLoginRouterWidget> {
  String? _errorMessage;
  bool _routing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeOnce());
  }

  Future<void> _routeOnce() async {
    if (_routing || !mounted) {
      return;
    }
    _routing = true;

    if (!loggedIn) {
      if (mounted) {
        context.go(LoginPageWidget.routePath);
      }
      return;
    }

    try {
      final profile = await resolveCurrentUserProfile();
      if (profile != null && !userIsActive(profile)) {
        await authManager.signOut();
        AppStateNotifier.instance.clearUserRole();
        if (mounted) {
          setState(() {
            _errorMessage =
                'Your account is inactive. Contact an administrator.';
          });
        }
        return;
      }

      final path = await getPostLoginRoutePath();
      final role = AppStateNotifier.instance.userRole;

      if (!mounted) {
        return;
      }

      if (role == null) {
        setState(() {
          _errorMessage =
              'No staff profile found for this account (${currentUserEmail}). '
              'Ask an admin to register you in Firebase users/{uid}.';
        });
        return;
      }

      context.go(path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load your account: $e';
        });
      }
    }
  }

  Future<void> _signOut() async {
    await authManager.signOut();
    AppStateNotifier.instance.clearUserRole();
    if (mounted) {
      context.go(LoginPageWidget.routePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: FlutterFlowTheme.of(context).error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyLarge,
                ),
                const SizedBox(height: 24),
                FFButtonWidget(
                  onPressed: _signOut,
                  text: 'Back to Login',
                  options: FFButtonOptions(
                    width: 200,
                    height: 44,
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Inter Tight',
                          color: Colors.white,
                          letterSpacing: 0.0,
                        ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            FlutterFlowTheme.of(context).primary,
          ),
        ),
      ),
    );
  }
}
