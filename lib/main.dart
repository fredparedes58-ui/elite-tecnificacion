import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:myapp/auth/app_auth_state.dart';
import 'package:myapp/config/app_config.dart';
import 'package:myapp/config/app_router.dart';
import 'package:myapp/repositories/conversations_repository.dart';
import 'package:myapp/repositories/credits_repository.dart';
import 'package:myapp/repositories/in_app_notifications_repository.dart';
import 'package:myapp/repositories/my_players_repository.dart';
import 'package:myapp/repositories/notifications_repository.dart';
import 'package:myapp/repositories/pending_players_repository.dart';
import 'package:myapp/repositories/players_repository.dart';
import 'package:myapp/repositories/reservations_repository.dart';
import 'package:myapp/repositories/system_config_repository.dart';
import 'package:myapp/repositories/users_repository.dart';
import 'package:myapp/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      // Deep link reset password se maneja por ruta /reset-password
    }
  });

  final appAuthState = AppAuthState();
  final pendingPlayersRepo = PendingPlayersRepository();
  final notificationsRepo = NotificationsRepository();
  final creditsRepo = CreditsRepository();
  final myPlayersRepo = MyPlayersRepository();
  final reservationsRepo = ReservationsRepository();
  final conversationsRepo = ConversationsRepository();
  final usersRepo = UsersRepository();
  final inAppNotificationsRepo = InAppNotificationsRepository();
  final systemConfigRepo = SystemConfigRepository();
  final playersRepo = PlayersRepository();
  final router = createAppRouter(appAuthState);

  runApp(
    Provider<AppAuthState>.value(
      value: appAuthState,
      child: ChangeNotifierProvider<PendingPlayersRepository>.value(
        value: pendingPlayersRepo,
        child: ChangeNotifierProvider<NotificationsRepository>.value(
          value: notificationsRepo,
          child: ChangeNotifierProvider<CreditsRepository>.value(
            value: creditsRepo,
            child: ChangeNotifierProvider<MyPlayersRepository>.value(
              value: myPlayersRepo,
              child: ChangeNotifierProvider<ReservationsRepository>.value(
                value: reservationsRepo,
                child: ChangeNotifierProvider<ConversationsRepository>.value(
                  value: conversationsRepo,
                  child: ChangeNotifierProvider<UsersRepository>.value(
                    value: usersRepo,
                    child: ChangeNotifierProvider<InAppNotificationsRepository>.value(
                      value: inAppNotificationsRepo,
                      child: ChangeNotifierProvider<SystemConfigRepository>.value(
                        value: systemConfigRepo,
                        child: ChangeNotifierProvider<PlayersRepository>.value(
                          value: playersRepo,
                          child: MaterialApp.router(
                            title: 'Futbol AI',
                            theme: AppTheme.lightTheme,
                            darkTheme: AppTheme.darkTheme,
                            themeMode: ThemeMode.dark,
                            routerConfig: router,
                            debugShowCheckedModeBanner: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
