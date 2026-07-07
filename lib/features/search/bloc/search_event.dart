part of 'search_bloc.dart';

sealed class SearchEvent {}

final class SearchQueryChanged extends SearchEvent {
  SearchQueryChanged(this.query);
  final String query;
}

final class SearchCleared extends SearchEvent {}
