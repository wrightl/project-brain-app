import Flutter
import UIKit
import WidgetKit
import Foundation

public class StorageHelper {
    static let storage = UserDefaults.init(suiteName: "group.com.dotdash.projectbrain")
    
    public static func setValue(key: String, value: Any) {
        storage?.set(value, forKey: key)
    }
    
    public static func getString(key: String) -> String? {
        return storage?.string(forKey: key)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let storageChannel = FlutterMethodChannel(
        name: "com.dotdash.projectbrain/storage",
        binaryMessenger: controller.binaryMessenger
    )
      
      storageChannel.setMethodCallHandler(
        {
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "savePreferences" else {
                result(
                    FlutterMethodNotImplemented
                )
                return
            }
            
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
            };
            
            StorageHelper.setValue(key: key, value: args["value"] as Any)
            
            WidgetCenter.shared.reloadTimelines(ofKind: "ProjectBrainWidget")
            
            result(StorageHelper.getString(key: key))
        })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
