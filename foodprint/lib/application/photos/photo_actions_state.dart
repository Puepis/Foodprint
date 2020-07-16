part of 'photo_actions_bloc.dart';

@freezed
abstract class PhotoActionsState with _$PhotoActionsState {
  const factory PhotoActionsState.initial() = Initial;
  const factory PhotoActionsState.actionInProgress() = ActionInProgress;
  const factory PhotoActionsState.deleteFailure(PhotoFailure failure) = DeleteFailure;
  const factory PhotoActionsState.deleteSuccess(FoodprintEntity newFoodprint) = DeleteSuccess;
  const factory PhotoActionsState.editFailure(PhotoFailure failure) = EditFailure;
  const factory PhotoActionsState.editSuccess(FoodprintEntity newFoodprint) = EditSuccess;
  const factory PhotoActionsState.saveFailure(PhotoFailure failure) = SaveFailure;
  const factory PhotoActionsState.saveSuccess(FoodprintEntity newFoodprint) = SaveSuccess;
}