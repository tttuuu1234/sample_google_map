import UIKit
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let googleMapApiKey = Bundle.main.infoDictionary!["GOOGLE_MAP_API_KEY"] as! String
    GMSServices.provideAPIKey(googleMapApiKey)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}