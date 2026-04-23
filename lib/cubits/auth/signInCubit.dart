import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/auth/guardian.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/data/repositories/authRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SignInState extends Equatable {}

class SignInInitial extends SignInState {
  @override
  List<Object?> get props => [];
}

class SignInInProgress extends SignInState {
  @override
  List<Object?> get props => [];
}

class SignInSuccess extends SignInState {
  final String jwtToken;
  final bool isStudentLogIn;
  final Student student;
  final String schoolCode;
  final Guardian parent;
  final List<Student> children;

  SignInSuccess({
    required this.jwtToken,
    required this.isStudentLogIn,
    required this.student,
    required this.parent,
    required this.schoolCode,
    this.children = const [],
  });

  @override
  List<Object?> get props => [jwtToken, isStudentLogIn, student, children];
}

class SignInFailure extends SignInState {
  final String errorMessage;

  SignInFailure(this.errorMessage);

  @override
  List<Object?> get props => [];
}

class SignInCubit extends Cubit<SignInState> {
  final AuthRepository _authRepository;

  SignInCubit(this._authRepository) : super(SignInInitial());

  Future<void> signInUser({
    required String userId,
    required String password,
    String? schoolCode,
    required bool isStudentLogin,
  }) async {
    emit(SignInInProgress());

    try {
      late Map<String, dynamic> result;

      if (isStudentLogin) {
        result = await _authRepository.signInStudent(
          grNumber: userId,
          schoolCode: schoolCode!,
          password: password,
        );
      } else {
        result = await _authRepository.signInParent(
          email: userId,
          password: password,
        );
      }

      emit(
        SignInSuccess(
          schoolCode: result['schoolCode'] ?? '',
          jwtToken: result['jwtToken'],
          isStudentLogIn: isStudentLogin,
          student: isStudentLogin ? result['student'] : Student.fromJson({}),
          parent: isStudentLogin ? Guardian.fromJson({}) : result['parent'],
          children: result['children'] ?? [],
        ),
      );
    } catch (e) {
      emit(SignInFailure(e.toString()));
    }
  }
}
