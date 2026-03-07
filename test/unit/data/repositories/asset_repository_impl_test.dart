import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:magic_doodle/core/errors/failures.dart';
import 'package:magic_doodle/core/network/network_info.dart';
import 'package:magic_doodle/data/datasources/local/asset_local_datasource.dart';
import 'package:magic_doodle/data/datasources/remote/firebase_storage_service.dart';
import 'package:magic_doodle/data/datasources/remote/firestore_service.dart';
import 'package:magic_doodle/data/repositories/asset_repository_impl.dart';
import 'package:magic_doodle/domain/entities/asset_3d_entity.dart';

class _MockLocalDs extends Mock implements AssetLocalDatasource {}

class _MockStorage extends Mock implements FirebaseStorageService {}

class _MockFirestore extends Mock implements FirestoreService {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late AssetRepositoryImpl sut;
  late _MockLocalDs mockLocal;
  late _MockStorage mockStorage;
  late _MockFirestore mockFirestore;
  late _MockNetworkInfo mockNetworkInfo;

  const tLabel = 'cat';
  const tModelPath = '/cache/cat.glb';
  const tAudioEnPath = '/cache/cat_en.mp3';
  const tAudioViPath = '/cache/cat_vi.mp3';

  setUp(() {
    mockLocal = _MockLocalDs();
    mockStorage = _MockStorage();
    mockFirestore = _MockFirestore();
    mockNetworkInfo = _MockNetworkInfo();
    sut = AssetRepositoryImpl(
      mockLocal,
      mockStorage,
      mockFirestore,
      mockNetworkInfo,
    );
  });

  group('AssetRepositoryImpl.getAsset', () {
    test('returns cached entity when local files exist', () async {
      when(() => mockLocal.getFilePath(tLabel, 'model'))
          .thenAnswer((_) async => tModelPath);
      when(() => mockLocal.getFilePath(tLabel, 'audio_en'))
          .thenAnswer((_) async => tAudioEnPath);
      when(() => mockLocal.getFilePath(tLabel, 'audio_vi'))
          .thenAnswer((_) async => tAudioViPath);
      when(() => mockLocal.updateLastAccessed(tLabel)).thenAnswer((_) async {});

      final result = await sut.getAsset(tLabel);

      final expected = Asset3DEntity(
        label: tLabel,
        localModelPath: tModelPath,
        localAudioPathEn: tAudioEnPath,
        localAudioPathVi: tAudioViPath,
        vocabularyEn: 'Cat',
        vocabularyVi: tLabel,
        category: 'general',
      );
      expect(result, Right(expected));
      verify(() => mockLocal.updateLastAccessed(tLabel)).called(1);
    });

    test('returns AssetNotFoundFailure when not cached and offline', () async {
      when(() => mockLocal.getFilePath(tLabel, 'model'))
          .thenAnswer((_) async => null);
      when(() => mockLocal.getFilePath(tLabel, 'audio_en'))
          .thenAnswer((_) async => null);
      when(() => mockLocal.getFilePath(tLabel, 'audio_vi'))
          .thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await sut.getAsset(tLabel);

      expect(result, const Left(AssetNotFoundFailure(tLabel)));
    });
  });
}
