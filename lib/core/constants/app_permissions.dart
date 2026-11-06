import 'package:in_sreerajp_imgvidgal/models/settings/app_permission_info.dart';

/// Every Android permission the app declares, plus the ones it strips from
/// the merged manifest on purpose.
///
/// This list must match `android/app/src/main/AndroidManifest.xml` and the
/// table in `docs/security.md` §11. `test/core/constants/app_permissions_test.dart`
/// fails the build if it drifts from the manifest.
///
/// `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` is not in the source manifest.
/// AndroidX adds it to the merged manifest as `<applicationId>.DYNAMIC_...`.
const List<AppPermissionInfo> kAppPermissions = <AppPermissionInfo>[
  // You allow these.
  AppPermissionInfo(
    id: AppPermissionId.photosVideos,
    kind: AppPermissionKind.explicit,
    androidNames: <AndroidPermissionName>[
      AndroidPermissionName('READ_MEDIA_IMAGES', minApi: 33),
      AndroidPermissionName('READ_MEDIA_VIDEO', minApi: 33),
      AndroidPermissionName('READ_MEDIA_VISUAL_USER_SELECTED', minApi: 34),
      AndroidPermissionName('READ_EXTERNAL_STORAGE', maxApi: 32),
    ],
  ),
  AppPermissionInfo(
    id: AppPermissionId.camera,
    kind: AppPermissionKind.explicit,
    androidNames: <AndroidPermissionName>[AndroidPermissionName('CAMERA')],
  ),

  // Granted at install.
  AppPermissionInfo(
    id: AppPermissionId.biometric,
    kind: AppPermissionKind.implicit,
    androidNames: <AndroidPermissionName>[
      AndroidPermissionName('USE_BIOMETRIC'),
      AndroidPermissionName('USE_FINGERPRINT', maxApi: 28),
    ],
  ),
  AppPermissionInfo(
    id: AppPermissionId.network,
    kind: AppPermissionKind.implicit,
    androidNames: <AndroidPermissionName>[AndroidPermissionName('INTERNET')],
  ),
  AppPermissionInfo(
    id: AppPermissionId.wifiState,
    kind: AppPermissionKind.implicit,
    androidNames: <AndroidPermissionName>[
      AndroidPermissionName('ACCESS_WIFI_STATE'),
    ],
  ),
  AppPermissionInfo(
    id: AppPermissionId.networkState,
    kind: AppPermissionKind.implicit,
    androidNames: <AndroidPermissionName>[
      AndroidPermissionName('ACCESS_NETWORK_STATE'),
    ],
  ),
  AppPermissionInfo(
    id: AppPermissionId.changeWifi,
    kind: AppPermissionKind.implicit,
    androidNames: <AndroidPermissionName>[
      AndroidPermissionName('CHANGE_WIFI_STATE'),
    ],
  ),
  AppPermissionInfo(
    id: AppPermissionId.receiverPrivate,
    kind: AppPermissionKind.implicit,
    androidNames: <AndroidPermissionName>[
      AndroidPermissionName('DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'),
    ],
  ),

  // Removed on purpose.
  AppPermissionInfo(
    id: AppPermissionId.wakeLock,
    kind: AppPermissionKind.removed,
    androidNames: <AndroidPermissionName>[AndroidPermissionName('WAKE_LOCK')],
  ),
  AppPermissionInfo(
    id: AppPermissionId.recordAudio,
    kind: AppPermissionKind.removed,
    androidNames: <AndroidPermissionName>[
      AndroidPermissionName('RECORD_AUDIO'),
    ],
  ),
  AppPermissionInfo(
    id: AppPermissionId.writeStorage,
    kind: AppPermissionKind.removed,
    androidNames: <AndroidPermissionName>[
      AndroidPermissionName('WRITE_EXTERNAL_STORAGE'),
    ],
  ),
];

/// The name AndroidX adds to the merged manifest only; never in the source.
const String kMergedOnlyPermission = 'DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION';
