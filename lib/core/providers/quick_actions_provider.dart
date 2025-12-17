import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_action_config.dart';

class QuickActionsState {
  final List<QuickActionConfig> actions;
  final int maxVisibleActions;
  final QuickActionType primaryAction; // The action triggered on tap

  const QuickActionsState({
    this.actions = defaultQuickActions,
    this.maxVisibleActions = 4,
    this.primaryAction = QuickActionType.logMood,
  });

  List<QuickActionConfig> get enabledActions {
    return actions
        .where((a) => a.isEnabled)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<QuickActionConfig> get visibleActions {
    return enabledActions.take(maxVisibleActions).toList();
  }

  QuickActionsState copyWith({
    List<QuickActionConfig>? actions,
    int? maxVisibleActions,
    QuickActionType? primaryAction,
  }) {
    return QuickActionsState(
      actions: actions ?? this.actions,
      maxVisibleActions: maxVisibleActions ?? this.maxVisibleActions,
      primaryAction: primaryAction ?? this.primaryAction,
    );
  }
}

class QuickActionsNotifier extends StateNotifier<QuickActionsState> {
  QuickActionsNotifier() : super(const QuickActionsState());

  void toggleAction(QuickActionType type) {
    final actions = state.actions.map((action) {
      if (action.type == type) {
        return action.copyWith(isEnabled: !action.isEnabled);
      }
      return action;
    }).toList();

    state = state.copyWith(actions: actions);
  }

  void reorderActions(int oldIndex, int newIndex) {
    final enabledActions = state.enabledActions;
    if (oldIndex < enabledActions.length && newIndex < enabledActions.length) {
      final item = enabledActions.removeAt(oldIndex);
      enabledActions.insert(newIndex, item);

      // Update order values
      final updatedActions = state.actions.map((action) {
        final index = enabledActions.indexWhere((a) => a.type == action.type);
        if (index >= 0) {
          return action.copyWith(order: index);
        }
        return action;
      }).toList();

      state = state.copyWith(actions: updatedActions);
    }
  }

  void setMaxVisible(int count) {
    state = state.copyWith(maxVisibleActions: count.clamp(2, 6));
  }

  void resetToDefaults() {
    state = const QuickActionsState();
  }

  void setPrimaryAction(QuickActionType type) {
    state = state.copyWith(primaryAction: type);
  }

  // Add a new action type that wasn't in defaults
  void addAction(QuickActionType type) {
    if (!state.actions.any((a) => a.type == type)) {
      final newAction = QuickActionConfig(
        type: type,
        isEnabled: true,
        order: state.actions.length,
      );
      state = state.copyWith(actions: [...state.actions, newAction]);
    }
  }
}

final quickActionsProvider =
    StateNotifierProvider<QuickActionsNotifier, QuickActionsState>(
  (ref) => QuickActionsNotifier(),
);
