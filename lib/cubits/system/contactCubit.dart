import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/system/contact.dart';
import 'package:eschool/data/models/system/contactResponse.dart';
import 'package:eschool/data/models/system/contactStats.dart';
import 'package:eschool/data/repositories/contactRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Contact List States
abstract class ContactState extends Equatable {}

class ContactInitial extends ContactState {
  @override
  List<Object?> get props => [];
}

class ContactLoading extends ContactState {
  @override
  List<Object?> get props => [];
}

class ContactLoaded extends ContactState {
  final ContactResponse contactResponse;
  final List<Contact> allContacts;

  ContactLoaded({
    required this.contactResponse,
    required this.allContacts,
  });

  @override
  List<Object?> get props => [contactResponse, allContacts];
}

class ContactError extends ContactState {
  final String errorMessage;

  ContactError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// Contact Detail States
abstract class ContactDetailState extends Equatable {}

class ContactDetailInitial extends ContactDetailState {
  @override
  List<Object?> get props => [];
}

class ContactDetailLoading extends ContactDetailState {
  @override
  List<Object?> get props => [];
}

class ContactDetailLoaded extends ContactDetailState {
  final Contact contact;

  ContactDetailLoaded(this.contact);

  @override
  List<Object?> get props => [contact];
}

class ContactDetailError extends ContactDetailState {
  final String errorMessage;

  ContactDetailError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// Contact Stats States
abstract class ContactStatsState extends Equatable {}

class ContactStatsInitial extends ContactStatsState {
  @override
  List<Object?> get props => [];
}

class ContactStatsLoading extends ContactStatsState {
  @override
  List<Object?> get props => [];
}

class ContactStatsLoaded extends ContactStatsState {
  final ContactStats stats;

  ContactStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class ContactStatsError extends ContactStatsState {
  final String errorMessage;

  ContactStatsError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

// Contact Cubit
class ContactCubit extends Cubit<ContactState> {
  final ContactRepository _contactRepository;

  ContactCubit(this._contactRepository) : super(ContactInitial());

  List<Contact> _allContacts = [];
  int _currentPage = 1;
  String? _currentType;
  String? _currentStatus;
  String? _currentSearch;

  List<Contact> get allContacts => _allContacts;

  Future<void> loadContacts({
    bool refresh = false,
    String? type,
    String? status,
    String? search,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _allContacts.clear();
        emit(ContactLoading());
      } else if (_allContacts.isEmpty) {
        emit(ContactLoading());
      }

      _currentType = type;
      _currentStatus = status;
      _currentSearch = search;

      final response = await _contactRepository.getContacts(
        page: _currentPage,
        type: type,
        status: status,
        search: search,
        perPage: 15,
      );

      if (refresh || _currentPage == 1) {
        _allContacts = response.contacts;
      } else {
        _allContacts.addAll(response.contacts);
      }

      emit(ContactLoaded(
        contactResponse: response,
        allContacts: _allContacts,
      ));
    } catch (e) {
      emit(ContactError(e.toString()));
    }
  }

  Future<void> loadMoreContacts() async {
    if (state is ContactLoaded) {
      final currentState = state as ContactLoaded;
      if (currentState.contactResponse.hasMorePages) {
        _currentPage++;
        await loadContacts(
          type: _currentType,
          status: _currentStatus,
          search: _currentSearch,
        );
      }
    }
  }

  Future<void> refreshContacts() async {
    await loadContacts(
      refresh: true,
      type: _currentType,
      status: _currentStatus,
      search: _currentSearch,
    );
  }
}

// Contact Detail Cubit
class ContactDetailCubit extends Cubit<ContactDetailState> {
  final ContactRepository _contactRepository;

  ContactDetailCubit(this._contactRepository) : super(ContactDetailInitial());

  Future<void> loadContactDetails(int contactId) async {
    try {
      emit(ContactDetailLoading());
      final contact = await _contactRepository.getContactDetails(contactId: contactId);
      emit(ContactDetailLoaded(contact));
    } catch (e) {
      emit(ContactDetailError(e.toString()));
    }
  }
}

// Contact Stats Cubit
class ContactStatsCubit extends Cubit<ContactStatsState> {
  final ContactRepository _contactRepository;

  ContactStatsCubit(this._contactRepository) : super(ContactStatsInitial());

  Future<void> loadContactStats() async {
    try {
      emit(ContactStatsLoading());
      final stats = await _contactRepository.getContactStats();
      emit(ContactStatsLoaded(stats));
    } catch (e) {
      emit(ContactStatsError(e.toString()));
    }
  }
}
