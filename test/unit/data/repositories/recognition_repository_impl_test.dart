import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:magic_doodle/core/errors/exceptions.dart';
import 'package:magic_doodle/core/errors/failures.dart';
import 'package:magic_doodle/data/ml/drawing_classifier.dart';
import 'package:magic_doodle/data/models/recognition_result_model.dart';
import 'package:magic_doodle/data/repositories/recognition_repository_impl.dart';
import 'package:magic_doodle/domain/entities/drawing_entity.dart';
import 'package:magic_doodle/domain/entities/recognition_result_entity.dart';
import 'package:mocktail/mocktail.dart';

class _MockDrawingClassifier extends Mock implements DrawingClassifier {}

void main() {
  late RecognitionRepositoryImpl sut;
  late _MockDrawingClassifier mockClassifier;

  final tDrawing = DrawingEntity(
    id: 'test-id',
    imageBytes: Uint8List(0),
    capturedAt: DateTime(2024),
  );

  final tRecognizedAtMs = DateTime.utc(2024).millisecondsSinceEpoch;
  final tResultModel = RecognitionResultModel(
    label: 'dog',
    confidence: 0.92,
    category: 'animal',
    recognizedAtMs: tRecognizedAtMs,
  );
  final tExpectedEntity = RecognitionResultEntity(
    label: 'dog',
    confidence: 0.92,
    category: 'animal',
    recognizedAt:
        DateTime.fromMillisecondsSinceEpoch(tRecognizedAtMs, isUtc: true),
  );

  setUp(() {
    mockClassifier = _MockDrawingClassifier();
    sut = RecognitionRepositoryImpl(mockClassifier);
    registerFallbackValue(Uint8List(0));
  });

  group('RecognitionRepositoryImpl.classify', () {
    test('returns Right(RecognitionResultEntity) on success', () async {
      when(() => mockClassifier.classify(any()))
          .thenAnswer((_) async => tResultModel);

      final result = await sut.classify(tDrawing);

      expect(result, Right<Failure, RecognitionResultEntity>(tExpectedEntity));
    });

    test('returns Left(InferenceFailure) on InferenceException', () async {
      when(() => mockClassifier.classify(any()))
          .thenThrow(const InferenceException('tflite error'));

      final result = await sut.classify(tDrawing);

      expect(result, isA<Left<Failure, RecognitionResultEntity>>());
      final failure = (result as Left).value;
      expect(failure, isA<InferenceFailure>());
    });

    test('returns Left(InferenceFailure) on generic exception', () async {
      when(() => mockClassifier.classify(any()))
          .thenThrow(Exception('unexpected'));

      final result = await sut.classify(tDrawing);

      expect(result, isA<Left<Failure, RecognitionResultEntity>>());
    });
  });
}
