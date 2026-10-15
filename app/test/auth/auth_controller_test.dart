import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/services/auth/account_models.dart';
import 'package:money_navigation/services/auth/account_repository.dart';
import 'package:money_navigation/services/auth/auth_controller.dart';
import 'package:money_navigation/services/auth/auth_failure.dart';
import 'package:money_navigation/services/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthException, AuthState, User;

final t0 = DateTime.utc(2026, 10, 15, 9, 30);

User userWithId(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-10-15T00:00:00Z',
  email: '$id@example.com',
);

Profile completeProfile(String id) => Profile(
  id: id,
  travelerType: TravelerType.visitorInThailand,
  homeCurrency: 'USD',
  cardCurrency: 'USD',
  language: AppLanguage.en,
  onboardedAt: t0,
);

Profile incompleteProfile(String id) => Profile(id: id);

class FakeAuthService extends AuthService {
  FakeAuthService({this.isConfigured = true, this.user});

  final bool isConfigured;
  User? user;
  final events = StreamController<AuthState>.broadcast();
  int signOutCalls = 0;
  int deleteCalls = 0;
  String? newPassword;

  void emit(AuthChangeEvent event) => events.add(AuthState(event, null));

  @override
  bool get configured => isConfigured;

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get changes {
    changesReads++;
    return events.stream;
  }

  int changesReads = 0;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    user = null;
    emit(AuthChangeEvent.signedOut);
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    user = null;
    emit(AuthChangeEvent.signedOut);
  }

  @override
  Future<void> setNewPassword(String password) async {
    newPassword = password;
  }
}

class FakeRepo extends AccountRepository {
  FakeRepo({this.profile, this.offline = false, this.userId = 'user-1'});

  Profile? profile;
  bool offline;
  String userId;

  /// When set, loadProfile waits for it before answering.
  Completer<void>? gate;
  int loads = 0;
  ProfileDraft? savedDraft;
  Profile? savedProfile;

  @override
  Future<Profile?> loadProfile() async {
    loads++;
    if (gate != null) await gate!.future;
    if (offline) throw const AuthFlowException(AuthFailure.offline);
    return profile;
  }

  @override
  Future<Profile> saveSetup(ProfileDraft draft, {required DateTime now}) async {
    if (offline) throw const AuthFlowException(AuthFailure.offline);
    savedDraft = draft;
    final p = draft.toProfile(userId, now: now);
    profile = p;
    savedProfile = p;
    return p;
  }
}

/// Lets stream events and unawaited work finish.
Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final _open = <AuthController>[];

Future<AuthController> started(FakeAuthService service, FakeRepo repo) async {
  final c = AuthController(
    service: service,
    repository: repo,
    prefs: SharedPreferencesAsync(),
  );
  _open.add(c);
  await c.start();
  await settle();
  return c;
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    for (final c in _open) {
      c.dispose();
    }
    _open.clear();
  });

  group('start', () {
    test('stage is starting before start runs', () {
      final c = AuthController(
        service: FakeAuthService(),
        repository: FakeRepo(),
        prefs: SharedPreferencesAsync(),
      );
      expect(c.stage, AuthStage.starting);
      c.dispose();
    });

    test('not configured opens the app as a guest', () async {
      final repo = FakeRepo();
      final c = await started(FakeAuthService(isConfigured: false), repo);
      expect(c.stage, AuthStage.ready);
      expect(c.isGuest, isTrue);
      expect(c.accountsAvailable, isFalse);
      expect(c.profile, isNull);
      expect(repo.loads, 0);
    });

    test('no user and no guest flag shows welcome', () async {
      final c = await started(FakeAuthService(), FakeRepo());
      expect(c.stage, AuthStage.welcome);
      expect(c.isGuest, isFalse);
      expect(c.isSignedIn, isFalse);
    });

    test('user with an incomplete profile goes to setup', () async {
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(profile: incompleteProfile('user-1')),
      );
      expect(c.stage, AuthStage.setup);
      expect(c.profile!.id, 'user-1');
      expect(c.isSignedIn, isTrue);
      expect(c.email, 'user-1@example.com');
    });

    test('user with a complete profile is ready', () async {
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(profile: completeProfile('user-1')),
      );
      expect(c.stage, AuthStage.ready);
      expect(c.profile!.isComplete, isTrue);
      expect(c.isGuest, isFalse);
    });
  });

  group('guest', () {
    test('continueAsGuest opens the app', () async {
      final c = await started(FakeAuthService(), FakeRepo());
      await c.continueAsGuest();
      expect(c.stage, AuthStage.ready);
      expect(c.isGuest, isTrue);
    });

    test('the stored guest flag opens a fresh controller as ready', () async {
      final first = await started(FakeAuthService(), FakeRepo());
      await first.continueAsGuest();
      final second = await started(FakeAuthService(), FakeRepo());
      expect(second.stage, AuthStage.ready);
      expect(second.isGuest, isTrue);
    });

    test('showSignIn from guest goes back to welcome', () async {
      final c = await started(FakeAuthService(), FakeRepo());
      await c.continueAsGuest();
      c.showSignIn();
      expect(c.stage, AuthStage.welcome);
    });
  });

  group('offline profile load', () {
    test('uses the cached complete profile of the same user', () async {
      await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(profile: completeProfile('user-1')),
      );
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(offline: true),
      );
      expect(c.stage, AuthStage.ready);
      expect(c.profile, isNotNull);
      expect(c.profile!.id, 'user-1');
      expect(c.profile!.isComplete, isTrue);
      expect(c.profile!.homeCurrency, 'USD');
    });

    test('a cached incomplete profile still goes to setup', () async {
      await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(profile: incompleteProfile('user-1')),
      );
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(offline: true),
      );
      expect(c.stage, AuthStage.setup);
    });

    test('no cache: ready with a null profile, never setup', () async {
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(offline: true),
      );
      expect(c.stage, AuthStage.ready);
      expect(c.profile, isNull);
    });

    test('another user\'s cache is ignored', () async {
      await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(profile: completeProfile('user-1')),
      );
      final c = await started(
        FakeAuthService(user: userWithId('user-2')),
        FakeRepo(offline: true, userId: 'user-2'),
      );
      expect(c.stage, AuthStage.ready);
      expect(c.profile, isNull);
    });
  });

  group('completeSetup', () {
    test('saves the draft and opens the app with the saved profile', () async {
      final repo = FakeRepo(profile: incompleteProfile('user-1'));
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        repo,
      );
      expect(c.stage, AuthStage.setup);
      final draft = defaultsFor(
        TravelerType.visitorInThailand,
        deviceCurrency: 'JPY',
      );
      await c.completeSetup(draft);
      expect(c.stage, AuthStage.ready);
      expect(repo.savedDraft, same(draft));
      expect(c.profile, same(repo.savedProfile));
      expect(c.profile!.isComplete, isTrue);
      expect(c.profile!.homeCurrency, 'JPY');
    });

    test('the saved profile is the offline cache next launch', () async {
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(profile: incompleteProfile('user-1')),
      );
      await c.completeSetup(
        defaultsFor(TravelerType.thaiAbroad, deviceCurrency: 'THB'),
      );
      final next = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(offline: true),
      );
      expect(next.stage, AuthStage.ready);
      expect(next.profile!.travelerType, TravelerType.thaiAbroad);
    });

    test('an offline save throws and stays in setup', () async {
      final repo = FakeRepo(profile: incompleteProfile('user-1'));
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        repo,
      );
      repo.offline = true;
      await expectLater(
        c.completeSetup(
          defaultsFor(TravelerType.visitorInThailand, deviceCurrency: 'USD'),
        ),
        throwsA(
          isA<AuthFlowException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.offline,
          ),
        ),
      );
      expect(c.stage, AuthStage.setup);
    });
  });

  group('auth events', () {
    test('signedIn after start re-reads the profile', () async {
      final service = FakeAuthService();
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final c = await started(service, repo);
      expect(c.stage, AuthStage.welcome);
      expect(repo.loads, 0);
      service.user = userWithId('user-1');
      service.emit(AuthChangeEvent.signedIn);
      await settle();
      expect(repo.loads, 1);
      expect(c.stage, AuthStage.ready);
      expect(c.profile!.id, 'user-1');
    });

    test('signing in from guest clears the guest flag', () async {
      final service = FakeAuthService();
      final c = await started(
        service,
        FakeRepo(profile: incompleteProfile('user-1')),
      );
      await c.continueAsGuest();
      service.user = userWithId('user-1');
      service.emit(AuthChangeEvent.signedIn);
      await settle();
      expect(c.stage, AuthStage.setup);
      expect(c.isGuest, isFalse);
    });

    test('signedOut goes to welcome and drops the profile', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final c = await started(
        service,
        FakeRepo(profile: completeProfile('user-1')),
      );
      service.user = null;
      service.emit(AuthChangeEvent.signedOut);
      await settle();
      expect(c.stage, AuthStage.welcome);
      expect(c.profile, isNull);
    });

    test('signedOut while a guest stays ready', () async {
      final service = FakeAuthService();
      final c = await started(service, FakeRepo());
      await c.continueAsGuest();
      service.emit(AuthChangeEvent.signedOut);
      await settle();
      expect(c.stage, AuthStage.ready);
      expect(c.isGuest, isTrue);
    });

    test('signOut ends at welcome, not guest', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final c = await started(
        service,
        FakeRepo(profile: completeProfile('user-1')),
      );
      await c.signOut();
      await settle();
      expect(service.signOutCalls, 1);
      expect(c.stage, AuthStage.welcome);
      expect(c.isGuest, isFalse);
    });
  });

  group('password recovery', () {
    test(
      'passwordRecovery shows newPassword; signedIn does not leave it',
      () async {
        final service = FakeAuthService(user: userWithId('user-1'));
        final c = await started(
          service,
          FakeRepo(profile: completeProfile('user-1')),
        );
        service.emit(AuthChangeEvent.passwordRecovery);
        await settle();
        expect(c.stage, AuthStage.newPassword);
        service.emit(AuthChangeEvent.signedIn);
        await settle();
        expect(c.stage, AuthStage.newPassword);
      },
    );

    test('setNewPassword saves and opens a complete account', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final c = await started(
        service,
        FakeRepo(profile: completeProfile('user-1')),
      );
      service.emit(AuthChangeEvent.passwordRecovery);
      await settle();
      await c.setNewPassword('new-secret-1');
      expect(service.newPassword, 'new-secret-1');
      expect(c.stage, AuthStage.ready);
    });

    test('setNewPassword goes to setup for an incomplete profile', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final c = await started(
        service,
        FakeRepo(profile: incompleteProfile('user-1')),
      );
      service.emit(AuthChangeEvent.passwordRecovery);
      await settle();
      await c.setNewPassword('new-secret-1');
      expect(c.stage, AuthStage.setup);
    });

    test(
      'recovery during the initial profile load still ends in newPassword',
      () async {
        final service = FakeAuthService(user: userWithId('user-1'));
        final repo = FakeRepo(profile: completeProfile('user-1'))
          ..gate = Completer<void>();
        final c = AuthController(
          service: service,
          repository: repo,
          prefs: SharedPreferencesAsync(),
        );
        _open.add(c);
        final starting = c.start();
        await settle();
        expect(repo.loads, 1, reason: 'initial load is in flight');
        service.emit(AuthChangeEvent.passwordRecovery);
        await settle();
        repo.gate!.complete();
        await starting;
        await settle();
        expect(c.stage, AuthStage.newPassword);
      },
    );
  });

  group('deleteAccount', () {
    test('goes to welcome with no profile and no cache', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final c = await started(
        service,
        FakeRepo(profile: completeProfile('user-1')),
      );
      await c.deleteAccount();
      await settle();
      expect(service.deleteCalls, 1);
      expect(c.stage, AuthStage.welcome);
      expect(c.profile, isNull);
      expect(c.isGuest, isFalse);
      final again = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(offline: true),
      );
      expect(again.profile, isNull, reason: 'cached profile was forgotten');
    });
  });

  group('stale profile loads', () {
    test(
      'signedOut while the initial load is pending ends in welcome',
      () async {
        final service = FakeAuthService(user: userWithId('user-1'));
        final repo = FakeRepo(profile: incompleteProfile('user-1'))
          ..gate = Completer<void>();
        final c = AuthController(
          service: service,
          repository: repo,
          prefs: SharedPreferencesAsync(),
        );
        _open.add(c);
        final starting = c.start();
        await settle();
        expect(repo.loads, 1, reason: 'initial load is in flight');
        service.user = null;
        service.emit(AuthChangeEvent.signedOut);
        await settle();
        repo.gate!.complete();
        await starting;
        await settle();
        expect(c.stage, AuthStage.welcome);
        expect(c.profile, isNull);
      },
    );

    test('signedOut while a later load is pending ends in welcome', () async {
      final service = FakeAuthService();
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final c = await started(service, repo);
      repo.gate = Completer<void>();
      service.user = userWithId('user-1');
      service.emit(AuthChangeEvent.signedIn);
      await settle();
      expect(repo.loads, 1);
      service.user = null;
      service.emit(AuthChangeEvent.signedOut);
      await settle();
      repo.gate!.complete();
      await settle();
      expect(c.stage, AuthStage.welcome);
      expect(c.profile, isNull);
    });

    test('a load finishing after signedOut leaves no cached profile', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final repo = FakeRepo(profile: completeProfile('user-1'))
        ..gate = Completer<void>();
      final c = AuthController(
        service: service,
        repository: repo,
        prefs: SharedPreferencesAsync(),
      );
      _open.add(c);
      final starting = c.start();
      await settle();
      service.user = null;
      service.emit(AuthChangeEvent.signedOut);
      await settle();
      repo.gate!.complete();
      await starting;
      await settle();
      final next = await started(
        FakeAuthService(user: userWithId('user-1')),
        FakeRepo(offline: true),
      );
      expect(next.profile, isNull, reason: 'signed-out data stays forgotten');
    });
  });

  group('stream errors', () {
    test('a plain error with no user shows welcome and codeInvalid', () async {
      final service = FakeAuthService();
      final c = await started(service, FakeRepo());
      service.events.addError(StateError('bad link'));
      await settle();
      expect(c.stage, AuthStage.welcome);
      expect(c.notice, AuthFailure.codeInvalid);
    });

    test('with no user while a guest it stays ready', () async {
      final service = FakeAuthService();
      final c = await started(service, FakeRepo());
      await c.continueAsGuest();
      service.events.addError(StateError('bad link'));
      await settle();
      expect(c.stage, AuthStage.ready);
      expect(c.notice, AuthFailure.codeInvalid);
    });

    test('AuthException otp_expired gives codeInvalid', () async {
      final service = FakeAuthService();
      final c = await started(service, FakeRepo());
      service.events.addError(const AuthException('x', code: 'otp_expired'));
      await settle();
      expect(c.notice, AuthFailure.codeInvalid);
      expect(c.stage, AuthStage.welcome);
    });

    test('AuthException with an unknown code becomes codeInvalid', () async {
      final service = FakeAuthService();
      final c = await started(service, FakeRepo());
      service.events.addError(const AuthException('x', code: 'brand_new'));
      await settle();
      expect(c.notice, AuthFailure.codeInvalid);
    });

    test('an error while signed in changes nothing', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final c = await started(service, repo);
      var notified = 0;
      c.addListener(() => notified++);
      service.events.addError(const AuthException('x', code: 'otp_expired'));
      await settle();
      expect(c.stage, AuthStage.ready);
      expect(c.notice, isNull);
      expect(c.profile!.id, 'user-1');
      expect(notified, 0);
    });

    test('clearNotice clears a notice', () async {
      final service = FakeAuthService();
      final c = await started(service, FakeRepo());
      service.events.addError(StateError('bad link'));
      await settle();
      expect(c.notice, AuthFailure.codeInvalid);
      c.clearNotice();
      expect(c.notice, isNull);
    });

    test('a signedIn event clears the notice', () async {
      final service = FakeAuthService();
      final c = await started(
        service,
        FakeRepo(profile: completeProfile('user-1')),
      );
      service.events.addError(const AuthException('x', code: 'otp_expired'));
      await settle();
      expect(c.notice, AuthFailure.codeInvalid);
      service.user = userWithId('user-1');
      service.emit(AuthChangeEvent.signedIn);
      await settle();
      expect(c.notice, isNull);
      expect(c.stage, AuthStage.ready);
    });

    test('the controller still reacts to events after an error', () async {
      final service = FakeAuthService();
      final c = await started(
        service,
        FakeRepo(profile: completeProfile('user-1')),
      );
      service.events.addError(StateError('bad link'));
      await settle();
      service.user = userWithId('user-1');
      service.emit(AuthChangeEvent.signedIn);
      await settle();
      expect(c.stage, AuthStage.ready);
      expect(c.profile!.id, 'user-1');
    });
  });

  group('refreshProfile', () {
    test('picks up a changed profile', () async {
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final c = await started(
        FakeAuthService(user: userWithId('user-1')),
        repo,
      );
      expect(c.profile!.displayName, isNull);
      repo.profile = completeProfile('user-1').copyWith(displayName: 'Mia');
      await c.refreshProfile();
      expect(repo.loads, 2);
      expect(c.profile!.displayName, 'Mia');
      expect(c.stage, AuthStage.ready);
    });

    test('does nothing when signed out', () async {
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final c = await started(FakeAuthService(), repo);
      await c.refreshProfile();
      expect(repo.loads, 0);
      expect(c.stage, AuthStage.welcome);
    });
  });

  group('start never stays starting', () {
    Future<(AuthController, Future<void>)> launchPending(
      FakeAuthService service,
      FakeRepo repo,
    ) async {
      repo.gate = Completer<void>();
      final c = AuthController(
        service: service,
        repository: repo,
        prefs: SharedPreferencesAsync(),
      );
      _open.add(c);
      final starting = c.start();
      await settle();
      expect(repo.loads, 1, reason: 'first load is in flight');
      expect(c.stage, AuthStage.starting);
      return (c, starting);
    }

    test(
      'passwordRecovery during the first load ends in newPassword',
      () async {
        final service = FakeAuthService(user: userWithId('user-1'));
        final repo = FakeRepo(profile: completeProfile('user-1'));
        final (c, starting) = await launchPending(service, repo);
        service.emit(AuthChangeEvent.passwordRecovery);
        await settle();
        repo.gate!.complete();
        await starting;
        await settle();
        expect(c.stage, AuthStage.newPassword);
      },
    );

    for (final (label, profile, stage) in [
      ('complete', completeProfile('user-1'), AuthStage.ready),
      ('incomplete', incompleteProfile('user-1'), AuthStage.setup),
    ]) {
      test('signedIn during the first load settles ($label profile)', () async {
        final service = FakeAuthService(user: userWithId('user-1'));
        final repo = FakeRepo(profile: profile);
        final (c, starting) = await launchPending(service, repo);
        service.emit(AuthChangeEvent.signedIn);
        await settle();
        repo.gate!.complete();
        await starting;
        await settle();
        expect(c.stage, stage);
        expect(c.profile!.id, 'user-1');
      });
    }

    test('signing out during the first load ends in welcome', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final (c, starting) = await launchPending(service, repo);
      service.user = null;
      service.emit(AuthChangeEvent.signedOut);
      await settle();
      repo.gate!.complete();
      await starting;
      await settle();
      expect(c.stage, AuthStage.welcome);
      expect(c.profile, isNull);
    });

    test('a guest who signs out during the first load ends ready', () async {
      final first = await started(FakeAuthService(), FakeRepo());
      await first.continueAsGuest();
      final service = FakeAuthService(user: userWithId('user-1'));
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final (c, starting) = await launchPending(service, repo);
      service.user = null;
      service.emit(AuthChangeEvent.signedOut);
      await settle();
      repo.gate!.complete();
      await starting;
      await settle();
      expect(c.stage, isNot(AuthStage.starting));
      expect(c.stage, isIn([AuthStage.welcome, AuthStage.ready]));
    });
  });

  group('start is idempotent', () {
    test('a second start subscribes once and loads once', () async {
      final service = FakeAuthService(user: userWithId('user-1'));
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final c = AuthController(
        service: service,
        repository: repo,
        prefs: SharedPreferencesAsync(),
      );
      _open.add(c);
      await Future.wait([c.start(), c.start()]);
      await c.start();
      await settle();
      expect(service.changesReads, 1);
      expect(repo.loads, 1);
      expect(c.stage, AuthStage.ready);
    });

    test('one signedIn event after a double start loads once', () async {
      final service = FakeAuthService();
      final repo = FakeRepo(profile: completeProfile('user-1'));
      final c = await started(service, repo);
      await c.start();
      await settle();
      service.user = userWithId('user-1');
      service.emit(AuthChangeEvent.signedIn);
      await settle();
      expect(repo.loads, 1);
      expect(c.stage, AuthStage.ready);
    });
  });

  group('start never notifies synchronously', () {
    test('not configured: still starting right after the call', () async {
      final c = AuthController(
        service: FakeAuthService(isConfigured: false),
        repository: FakeRepo(),
        prefs: SharedPreferencesAsync(),
      );
      _open.add(c);
      var notified = 0;
      c.addListener(() => notified++);
      final starting = c.start();
      expect(c.stage, AuthStage.starting);
      expect(notified, 0);
      await starting;
      expect(c.stage, AuthStage.ready);
      expect(notified, 1);
    });

    test('configured, no user: still starting right after the call', () async {
      final c = AuthController(
        service: FakeAuthService(),
        repository: FakeRepo(),
        prefs: SharedPreferencesAsync(),
      );
      _open.add(c);
      var notified = 0;
      c.addListener(() => notified++);
      final starting = c.start();
      expect(c.stage, AuthStage.starting);
      expect(notified, 0);
      await starting;
      expect(c.stage, AuthStage.welcome);
    });
  });
}
