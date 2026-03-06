import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ar/core/errors/failures.dart';
import 'package:ar/domain/entities/asset_3d_entity.dart';
import 'package:ar/domain/repositories/asset_repository.dart';
import 'package:ar/domain/usecases/fetch_3d_asset_usecase.dart';

class _MockAssetRepository extends Mock implements AssetRepository {}

void main() {
  late Fetch3dAssetUseCase sut;
  late _MockAssetRepository mockRepo;

  const tLabel = 'cat';
  final tAsset = Asset3dEntity(
    label: tLabel,
    localModelPath: '/cache/cat.glb',
    localAudioPathEn: '/cache/cat_en.mp3',
    localAudioPathVi: '/cache/cat_vi.mp3',
    vocabularyEn: 'Cat',
    vocabularyVi: 'Mèo',
    category: 'animal',
    version: 1,
  );

  setUp(() {
    mockRepo = _MockAssetRepository();
    sut = Fetch3dAssetUseCase(mockRepo);
  });

  group('Fetch3dAssetUseCase', () {
    test('returns Asset3dEntity when asset is available locally', () async {
      when(() => mockRepo.getAsset(tLabel))
          .thenAnswer((_) async => Right(tAsset));

      final result = await sut(tLabel);

      expect(result, Right(tAsset));
      verify(() => mockRepo.getAsset(tLabel)).called(1);
    });

    test('returns AssetNotFoundFailure when asset missing', () async {
      const failure = AssetNotFoundFailure('not found');
      when(() => mockRepo.getAsset(tLabel))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut(tLabel);

      expect(result, const Left(failure));
    });
  });
}
