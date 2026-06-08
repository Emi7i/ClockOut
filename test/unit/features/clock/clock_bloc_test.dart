import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:clock_app/domain/entities/clock_entry.dart';
import 'package:clock_app/domain/repositories/clock_repository.dart';
import 'package:clock_app/domain/use_cases/clock_in_use_case.dart';
import 'package:clock_app/domain/use_cases/clock_out_use_case.dart';
import 'package:clock_app/features/clock/bloc/clock_bloc.dart';

class MockClockRepository extends Mock implements ClockRepository {}
class MockClockInUseCase extends Mock implements ClockInUseCase {}
class MockClockOutUseCase extends Mock implements ClockOutUseCase {}

void main() {
  late MockClockRepository mockRepository;
  late MockClockInUseCase mockClockIn;
  late MockClockOutUseCase mockClockOut;

  setUp(() {
    mockRepository = MockClockRepository();
    mockClockIn = MockClockInUseCase();
    mockClockOut = MockClockOutUseCase();
  });

  group('ClockBloc', () {
    final tClockEntry = ClockEntry(
      id: '1',
      clockedInAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockIdle] when ClockStarted finds no active entry',
      build: () {
        when(() => mockRepository.getActiveEntry()).thenAnswer((_) async => null);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
        );
      },
      act: (bloc) => bloc.add(const ClockStarted()),
      expect: () => [
        isA<ClockIdle>(),
      ],
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockActive] when ClockStarted finds active entry',
      build: () {
        when(() => mockRepository.getActiveEntry()).thenAnswer((_) async => tClockEntry);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
        );
      },
      act: (bloc) => bloc.add(const ClockStarted()),
      expect: () => [
        isA<ClockActive>(),
      ],
    );

    blocTest<ClockBloc, ClockState>(
      'emits [ClockActive] when ClockInRequested succeeds',
      build: () {
        when(() => mockClockIn()).thenAnswer((_) async => tClockEntry);
        return ClockBloc(
          clockIn: mockClockIn,
          clockOut: mockClockOut,
          repository: mockRepository,
        );
      },
      act: (bloc) => bloc.add(const ClockInRequested()),
      expect: () => [
        isA<ClockActive>(),
      ],
    );
  });
}
