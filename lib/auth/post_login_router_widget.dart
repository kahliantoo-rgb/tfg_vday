import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/auth/auth_redirect.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';

/// Redirects authenticated users to the correct home route by role.
class PostLoginRouterWidget extends StatefulWidget {
  const PostLoginRouterWidget({super.key});

  @override
  State<PostLoginRouterWidget> createState() => _PostLoginRouterWidgetState();
}

class _PostLoginRouterWidgetState extends State<PostLoginRouterWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final path = await getPostLoginRoutePath();
      await AppStateNotifier.instance.loadUserRole();
      if (mounted) {
        context.go(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
