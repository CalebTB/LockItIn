import 'package:get_it/get_it.dart';

// Services
import '../services/proposal_service.dart';
import '../services/group_service.dart';
import '../services/friend_service.dart';
import '../services/notification_service.dart';
import '../services/event_service.dart';

// Repositories
import '../../data/repositories/proposal_repository_impl.dart';
import '../../domain/repositories/proposal_repository.dart';

// Use Cases
import '../../domain/usecases/proposal/create_proposal_usecase.dart';
import '../../domain/usecases/proposal/cast_vote_usecase.dart';
import '../../domain/usecases/proposal/finalize_proposal_usecase.dart';
// import '../../domain/usecases/group/create_group_usecase.dart'; // Commented until IGroupRepository is implemented

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Initialize all dependencies
///
/// Call this in main() before runApp()
Future<void> setupDependencies() async {
  // ============================================================================
  // SERVICES (Singletons)
  // ============================================================================

  // Register services as lazy singletons
  getIt.registerLazySingleton<ProposalService>(() => ProposalService.instance);
  getIt.registerLazySingleton<GroupService>(() => GroupService.instance);
  getIt.registerLazySingleton<FriendService>(() => FriendService.instance);
  getIt.registerLazySingleton<NotificationService>(() => NotificationService.instance);
  getIt.registerLazySingleton<EventService>(() => EventService.instance);

  // ============================================================================
  // REPOSITORIES
  // ============================================================================

  // Proposal Repository
  getIt.registerLazySingleton<IProposalRepository>(
    () => ProposalRepositoryImpl(service: getIt<ProposalService>()),
  );

  // Note: GroupRepository and FriendRepository interfaces can be added later
  // when we have their implementations

  // ============================================================================
  // USE CASES
  // ============================================================================

  // Proposal Use Cases
  getIt.registerFactory<CreateProposalUseCase>(
    () => CreateProposalUseCase(getIt<IProposalRepository>()),
  );

  getIt.registerFactory<CastVoteUseCase>(
    () => CastVoteUseCase(getIt<IProposalRepository>()),
  );

  getIt.registerFactory<FinalizeProposalUseCase>(
    () => FinalizeProposalUseCase(getIt<IProposalRepository>()),
  );

  // Group Use Cases
  // Note: CreateGroupUseCase requires IGroupRepository which we'll add later
  // getIt.registerFactory<CreateGroupUseCase>(
  //   () => CreateGroupUseCase(getIt<IGroupRepository>()),
  // );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}

/// Check if dependencies are registered
bool get areDependenciesRegistered => getIt.isRegistered<ProposalService>();
