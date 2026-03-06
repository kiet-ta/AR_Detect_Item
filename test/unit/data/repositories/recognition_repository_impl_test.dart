import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ar/core/errors/exceptions.dart';
import 'package:ar/core/errors/failures.dart';
import 'package:ar/data/ml/drawing_classifier.dart';
import 'package:ar/data/repositories/recognition_repository_impl.dart';
import 'package:ar/domain/entities/drawing_entity.dart';
import 'package:ar/domain/entities/recognition_result_entity.dart';

class _MockDrawingClassifier extends Mock implements DrawingClassifier {}

void main() {
  late RecognitionRepositoryImpl sut;
  late _MockDrawingClassifier mockClassifier;

  final tDrawing = DrawingEntity(
    id: 'test-id',
    imageBytes: Uint8List(0),
    capturedAt: DateTime(2024),
  );
  final tResult = RecognitionResultEntity(
    label: 'dog',
    confidence: 0.92,
    category: 'animal',
    recognizedAt: DateTime(2024),
  );

  setUp(() {
    mockClassifier = _MockDrawingClassifier();
    sut = RecognitionRepositoryImpl(mockClassifier);
    registerFallbackValue(tDrawing);
  });

  group('RecognitionRepositoryImpl.classify', () {
    test('returns Right(RecognitionResultEntity) on success', () async {
      when(() => mockClassifier.classify(any()))
          .thenAnswer((_) async => tResult);

      final result = await sut.classify(tDrawing);

      expect(result, Right(tResult));
    });

    test('returns Left(InferenceFailure) on InferenceException', () async {
      when(() => mockClassifier.classify(any()))
          .thenThrow(const InferenceException('tflite error'));

      final result = await sut.classify(tDrawing);

      expect(result, isA<Left<Failure, RecognitionResultEntity>>());
      final failure = (result as Left).value;
      expect(failure, isA<InferenceFailure>());
    });

    test('returns Left(CacheFailure) on generic exception', () async {
      when(() => mockClassifier.classify(any()))
          .thenThrow(Exception('unexpected'));

      final result = await sut.classify(tDrawing);

      expect(result, isA<Left<Failure, RecognitionResultEntity>>());
    });
  });
}
