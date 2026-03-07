import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:magic_doodle/core/errors/failures.dart';
import 'package:magic_doodle/domain/entities/asset_3d_entity.dart';
import 'package:magic_doodle/domain/repositories/asset_repository.dart';
import 'package:magic_doodle/domain/usecases/fetch_3d_asset_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockAssetRepository extends Mock implements AssetRepository {}

void main() {
  late FetchAssetUseCase sut;
  late _MockAssetRepository mockRepo;

  const tLabel = 'cat';
  const tAsset = Asset3DEntity(
    label: tLabel,
    localModelPath: '/cache/cat.glb',
    localAudioPathEn: '/cache/cat_en.mp3',
    localAudioPathVi: '/cache/cat_vi.mp3',
    vocabularyEn: 'Cat',
    vocabularyVi: 'Mèo',
    category: 'animal',
  );

  setUp(() {
    mockRepo = _MockAssetRepository();
    sut = FetchAssetUseCase(mockRepo);
  });

  group('FetchAssetUseCase', () {
    test('returns Asset3DEntity when asset is available locally', () async {
      when(() => mockRepo.getAsset(tLabel))
          .thenAnswer((_) async => Right<Failure, Asset3DEntity>(tAsset));

      final result = await sut(tLabel);

      expect(result, Right<Failure, Asset3DEntity>(tAsset));
      verify(() => mockRepo.getAsset(tLabel)).called(1);
    });

    test('returns AssetNotFoundFailure when asset missing', () async {
      const failure = AssetNotFoundFailure('not found');
      when(() => mockRepo.getAsset(tLabel)).thenAnswer(
        (_) async => const Left<Failure, Asset3DEntity>(failure),
      );

      final result = await sut(tLabel);

      expect(result, const Left<Failure, Asset3DEntity>(failure));
    });
  });
}
