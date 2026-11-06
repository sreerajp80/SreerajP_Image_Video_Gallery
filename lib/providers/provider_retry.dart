/// The retry rule for every provider in the app: never retry.
///
/// Riverpod 3 retries a provider that throws, with growing delays. This app
/// was written for "fail once, show the fallback" (hard rule 5). A thumbnail
/// of a corrupt photo, a refused permission or a missing file will not get
/// better on its own, so retrying only costs battery and time. A screen that
/// wants another try asks for it (for example with `ref.invalidate`).
///
/// Passed to the app's `ProviderScope` and to test containers.
Duration? noProviderRetry(int retryCount, Object error) => null;
