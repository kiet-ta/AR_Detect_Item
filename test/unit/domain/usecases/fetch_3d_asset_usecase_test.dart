import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:magic_doodle/core/errors/failures.dart';
import 'package:magic_doodle/domain/entities/asset_3d_entity.dart';
import 'package:magic_doodle/domain/repositories/asset_repository.dart';
import 'package:magic_doodle/domain/usecases/fetch_3d_asset_usecase.dart';

class _MockAssetRepository extends Mock implements AssetRepository {}

void main() {
  late FetchAssetUseCase sut;
  late _MockAssetRepository mockRepo;

  const tLabel = 'cat';
  final tAsset = Asset3DEntity(
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
    sut = FetchAssetUseCase(mockRepo);
  });

  group('FetchAssetUseCase', () {
    test('returns Asset3DEntity when asset is available locally', () async {
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
