import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

class MockObject extends Mock {}

void main() {
  test('hello world!', () {
    final mock = MockObject();
    when(mock.toString()).thenReturn('Hello, World!');
    expect(mock.toString(), 'Hello, World!');
  });
}