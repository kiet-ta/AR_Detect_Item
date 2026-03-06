import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ar/core/errors/failures.dart';
import 'package:ar/domain/entities/drawing_entity.dart';
import 'package:ar/domain/entities/recognition_result_entity.dart';
import 'package:ar/domain/repositories/recognition_repository.dart';
import 'package:ar/domain/usecases/recognize_drawing_usecase.dart';

class _MockRecognitionRepository extends Mock
    implements RecognitionRepository {}

void main() {
  late RecognizeDrawingUseCase sut;
  late _MockRecognitionRepository mockRepo;

  final tDrawing = DrawingEntity(
    id: 'test-id',
    imageBytes: Uint8List(0),
    capturedAt: DateTime(2024),
  );
  final tResult = RecognitionResultEntity(
    label: 'cat',
    confidence: 0.85,
    category: 'animal',
    recognizedAt: DateTime(2024),
  );

  setUp(() {
    mockRepo = _MockRecognitionRepository();
    sut = RecognizeDrawingUseCase(mockRepo);
    registerFallbackValue(tDrawing);
  });

  group('RecognizeDrawingUseCase', () {
    test('returns RecognitionResultEntity on success', () async {
      when(() => mockRepo.classify(any()))
          .thenAnswer((_) async => Right(tResult));

      final result = await sut(tDrawing);

      expect(result, Right(tResult));
      verify(() => mockRepo.classify(tDrawing)).called(1);
    });

    test('returns InferenceFailure on classifier error', () async {
      const failure = InferenceFailure('model error');
      when(() => mockRepo.classify(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut(tDrawing);

      expect(result, const Left(failure));
    });
  });
}
