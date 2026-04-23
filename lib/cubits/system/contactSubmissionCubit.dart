import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/system/contact.dart';
import 'package:eschool/data/repositories/system/contactRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Contact Submission States
abstract class ContactSubmissionState extends Equatable {}

class ContactSubmissionInitial extends ContactSubmissionState {
  @override
  List<Object?> get props => [];
}

class ContactSubmissionLoading extends ContactSubmissionState {
  @override
  List<Object?> get props => [];
}

class ContactSubmissionSuccess extends ContactSubmissionState {
  final Contact contact;

  ContactSubmissionSuccess(this.contact);

  @override
  List<Object?> get props => [contact];
}

class ContactSubmissionFailure extends ContactSubmissionState {
  final String errorMessage;

  ContactSubmissionFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// Contact Submission Cubit
class ContactSubmissionCubit extends Cubit<ContactSubmissionState> {
  final ContactRepository _contactRepository;

  ContactSubmissionCubit(this._contactRepository) : super(ContactSubmissionInitial());

  Future<void> submitContact({
    required String name,
    required String email,
    required String subject,
    required String message,
    required String type,
  }) async {
    try {
      emit(ContactSubmissionLoading());

      final contact = await _contactRepository.submitContact(
        name: name,
        email: email,
        subject: subject,
        message: message,
        type: type,
      );

      emit(ContactSubmissionSuccess(contact));
    } catch (e) {
      emit(ContactSubmissionFailure(e.toString()));
    }
  }

  void reset() {
    emit(ContactSubmissionInitial());
  }
}
