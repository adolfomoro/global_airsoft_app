import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeSharedPreferencesFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func excludeSharedPreferencesFromBackup() {
    let preferencesDirectoryPath = NSHomeDirectory() + "/Library/Preferences"
    let preferencesDirectoryURL = URL(fileURLWithPath: preferencesDirectoryPath)

    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true

    do {
      var mutableDirectoryURL = preferencesDirectoryURL
      try mutableDirectoryURL.setResourceValues(resourceValues)
    } catch {
      #if DEBUG
        print("Failed to exclude Preferences directory from backup: \(error)")
      #endif
    }

    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
      return
    }

    let preferencesPlistPath =
      NSHomeDirectory() + "/Library/Preferences/\(bundleIdentifier).plist"
    let preferencesURL = URL(fileURLWithPath: preferencesPlistPath)

    guard FileManager.default.fileExists(atPath: preferencesURL.path) else {
      return
    }

    do {
      var mutableURL = preferencesURL
      try mutableURL.setResourceValues(resourceValues)
    } catch {
      #if DEBUG
        print("Failed to exclude preferences from backup: \(error)")
      #endif
    }
  }
}
