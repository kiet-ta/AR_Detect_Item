import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

/// Registers third-party instances that cannot use @injectable directly
/// (because we don’t own their constructors).
///
/// Injectable will use these factory methods to satisfy dependencies.
@module
abstract class RegisterModule {
  /// Provides [FirebaseFirestore] singleton to the DI graph.
  @singleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Provides [FirebaseStorage] singleton to the DI graph.
  @singleton
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Provides [Connectivity] singleton for network monitoring.
  @singleton
  Connectivity get connectivity => Connectivity();
}
