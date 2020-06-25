import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:foodprint/domain/auth/i_auth_repository.dart';
import 'package:foodprint/domain/auth/register_failure.dart';
import 'package:foodprint/domain/auth/value_objects.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';

part 'register_form_event.dart';
part 'register_form_state.dart';

part 'register_form_bloc.freezed.dart';

@injectable
class RegisterFormBloc extends Bloc<RegisterFormEvent, RegisterFormState> {
  final IAuthRepository _authClient;

  RegisterFormBloc(this._authClient);

  @override
  RegisterFormState get initialState => RegisterFormState.initial();

  @override
  Stream<RegisterFormState> mapEventToState(
    RegisterFormEvent event,
  ) async* {
    yield* event.map(
      emailChanged: (e) async* {
        yield state.copyWith(
            emailAddress: EmailAddress(e.emailStr),
            authFailureOrSuccessOption:
                none() // associate new email address with new auth response
            );
      },
      usernameChanged: (e) async* {
        yield state.copyWith(
            username: Username(e.usernameStr),
            authFailureOrSuccessOption: none());
      },
      passwordChanged: (e) async* {
        yield state.copyWith(
            password: Password(e.passwordStr),
            authFailureOrSuccessOption: none());
      },
      registerPressed: (e) async* {
        Either<RegisterFailure, Unit> failureOrSuccess;

        // Check if the fields are valid
        final isEmailValid = state.emailAddress.isValid();
        final isPasswordValid = state.password.isValid();
        final isUsernameValid = state.username.isValid();

        if (isEmailValid && isPasswordValid && isUsernameValid) {
          yield state.copyWith(
              isSubmitting: true, authFailureOrSuccessOption: none());

          // Attempt to register 
          failureOrSuccess = await _authClient.register(
              emailAddress: state.emailAddress,
              password: state.password,
              username: state.username);
        }
        // Invalid input
        yield state.copyWith(
          isSubmitting: false,
          authFailureOrSuccessOption: optionOf(
              failureOrSuccess), // if null, return none() otherwise some(failureOrSuccess)
          showErrorMessages: true,
        );
      },
    );
  }
}
