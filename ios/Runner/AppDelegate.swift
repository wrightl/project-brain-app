import Flutter
import UIKit
import Foundation
import GoogleMaps

public class StorageHelper {
    static let storage = UserDefaults.init(suiteName: "group.com.dotdash.projectbrain")

    public static func setValue(key: String, value: Any) {
        storage?.set(value, forKey: key)
    }

    public static func setBool(key: String, value: Bool) {
        storage?.set(value, forKey: key)
    }

    public static func getString(key: String) -> String? {
        return storage?.string(forKey: key)
    }

    public static func getBool(key: String) -> Bool? {
        return storage?.bool(forKey: key)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty,
       !apiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(apiKey)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    let storageChannel = FlutterMethodChannel(
      name: "com.dotdash.projectbrain/storage",
      binaryMessenger: messenger
    )

    storageChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "savePreferences" {
        guard let args = call.arguments as? [String: Any] else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "It's required send arguments",
              details: nil
            )
          )
          return
        }

        guard let key = args["key"] as? String else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "Its required send a key",
              details: nil
            )
          )
          return
        }

        if let boolValue = args["value"] as? Bool {
          StorageHelper.setBool(key: key, value: boolValue)
          result(StorageHelper.getBool(key: key)?.description)
        } else {
          StorageHelper.setValue(key: key, value: args["value"] as Any)
          result(StorageHelper.getString(key: key))
        }
      } else if call.method == "getPreferences" {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let type = args["type"] as? String else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "It's required send key and type",
              details: nil
            )
          )
          return
        }

        if type == "bool" {
          result(StorageHelper.getBool(key: key)?.description)
        } else {
          result(StorageHelper.getString(key: key))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    let mapsChannel = FlutterMethodChannel(
      name: "com.dotdash.projectbrain/google_maps",
      binaryMessenger: messenger
    )

    mapsChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "configureApiKey" {
        guard let args = call.arguments as? [String: Any],
              let apiKey = args["apiKey"] as? String,
              !apiKey.isEmpty else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "apiKey is required",
              details: nil
            )
          )
          return
        }
        GMSServices.provideAPIKey(apiKey)
        result(nil)
      } else if call.method == "isApiKeyConfigured" {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
           !apiKey.isEmpty,
           !apiKey.hasPrefix("$(") {
          result(true)
        } else {
          result(false)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if let goalData = userInfo["goal"] as? [String: Any],
       let index = goalData["index"] as? Int,
       let completed = goalData["completed"] as? Bool {
      StorageHelper.setBool(key: "egg_\(index)_completed", value: completed)
      completionHandler(.newData)
    } else {
      completionHandler(.noData)
    }
  }
}
