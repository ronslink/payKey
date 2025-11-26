import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';

// This will generate the mock classes
// Run: flutter pub run build_runner build
@GenerateMocks([Dio])
import 'payroll_repository_test.mocks.dart';

// Assuming you have these classes defined
class PayPeriod {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  PayPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory PayPeriod.fromJson(Map<String, dynamic> json) {
    return PayPeriod(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'],
    );
  }
}

class PayrollRepository {
  final Dio dio;

  PayrollRepository(this.dio);

  Future<List<PayPeriod>> fetchPayPeriods() async {
    final response = await dio.get('/pay-periods');
    final List<dynamic> data = response.data;
    return data.map((json) => PayPeriod.fromJson(json)).toList();
  }

  Future<PayPeriod> runPayroll(DateTime date) async {
    final response = await dio.post(
      '/payroll/run',
      data: {'date': date.toIso8601String()},
    );
    return PayPeriod.fromJson(response.data);
  }
}

void main() {
  late MockDio mockDio;
  late PayrollRepository repository;

  setUp(() {
    mockDio = MockDio();
    repository = PayrollRepository(mockDio);
  });

  group('PayrollRepository', () {
    test('fetchPayPeriods returns list of pay periods', () async {
      // Arrange
      when(mockDio.get('/pay-periods')).thenAnswer(
        (_) async => Response(
          data: [
            {
              'id': '1',
              'startDate': '2024-01-01T00:00:00.000Z',
              'endDate': '2024-01-31T00:00:00.000Z',
              'status': 'COMPLETED',
            },
            {
              'id': '2',
              'startDate': '2024-02-01T00:00:00.000Z',
              'endDate': '2024-02-29T00:00:00.000Z',
              'status': 'PENDING',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/pay-periods'),
        ),
      );

      // Act
      final periods = await repository.fetchPayPeriods();

      // Assert
      expect(periods, hasLength(2));
      expect(periods[0].id, '1');
      expect(periods[0].status, 'COMPLETED');
      expect(periods[1].status, 'PENDING');
      verify(mockDio.get('/pay-periods')).called(1);
    });

    test('runPayroll creates new pay period', () async {
      // Arrange
      final testDate = DateTime(2024, 1, 31);
      when(mockDio.post(
        '/payroll/run',
        data: anyNamed('data'),
      )).thenAnswer(
        (_) async => Response(
          data: {
            'id': '3',
            'startDate': '2024-01-01T00:00:00.000Z',
            'endDate': '2024-01-31T00:00:00.000Z',
            'status': 'PENDING',
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/payroll/run'),
        ),
      );

      // Act
      final period = await repository.runPayroll(testDate);

      // Assert
      expect(period.id, '3');
      expect(period.status, 'PENDING');
      verify(mockDio.post(
        '/payroll/run',
        data: anyNamed('data'),
      )).called(1);
    });

    test('fetchPayPeriods throws exception on error', () async {
      // Arrange
      when(mockDio.get('/pay-periods')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/pay-periods'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/pay-periods'),
          ),
        ),
      );

      // Act & Assert
      expect(
        () => repository.fetchPayPeriods(),
        throwsA(isA<DioException>()),
      );
    });
  });
}
