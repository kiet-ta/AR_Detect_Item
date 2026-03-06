import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ar/core/errors/failures.dart';
import 'package:ar/data/datasources/local/asset_local_datasource.dart';
import 'package:ar/data/datasources/remote/firebase_storage_service.dart';
import 'package:ar/data/datasources/remote/firestore_service.dart';
import 'package:ar/data/models/asset_3d_model.dart';
import 'package:ar/data/repositories/asset_repository_impl.dart';
import 'package:ar/domain/entities/asset_3d_entity.dart';

class _MockLocalDs extends Mock implements AssetLocalDatasource {}
class _MockFirestore extends Mock implements FirestoreService {}
class _MockStorage extends Mock implements FirebaseStorageService {}

void main() {
  late AssetRepositoryImpl sut;
  late _MockLocalDs mockLocal;
  late _MockFirestore mockFirestore;
  late _MockStorage mockStorage;

  const tLabel = 'cat';
  final tEntity = Asset3dEntity(
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
    mockLocal = _MockLocalDs();
    mockFirestore = _MockFirestore();
    mockStorage = _MockStorage();
    sut = AssetRepositoryImpl(mockLocal, mockFirestore, mockStorage);
  });

  group('AssetRepositoryImpl.getAsset', () {
    test('returns cached entity when local file exists', () async {
      when(() => mockLocal.getAsset(tLabel))
          .thenAnswer((_) async => tEntity.toModel());

      final result = await sut.getAsset(tLabel);

      expect(result, Right(tEntity));
      verifyNever(() => mockFirestore.getDocument(any(), any()));
    });

    test('returns AssetNotFoundFailure when no local + no remote', () async {
      when(() => mockLocal.getAsset(tLabel)).thenAnswer((_) async => null);
      when(() => mockFirestore.getDocument(any(), any()))
          .thenAnswer((_) async => null);

      final result = await sut.getAsset(tLabel);

      expect(result,
          const Left(AssetNotFoundFailure('Asset not found: $tLabel')));
    });
  });
}

extension on Asset3dEntity {
  Asset3dModel toModel() => Asset3dModel(
        label: label,
        vocabularyEn: vocabularyEn,
        vocabularyVi: vocabularyVi,
        category: category,
        remoteModelPath: remoteModelPath ?? '',
        remoteAudioPathEn: '',
        remoteAudioPathVi: '',
        localModelPath: localModelPath,
        localAudioPathEn: localAudioPathEn,
        localAudioPathVi: localAudioPathVi,
        version: version,
      );
}
