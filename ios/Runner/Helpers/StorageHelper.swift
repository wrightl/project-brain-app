import Foundation

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