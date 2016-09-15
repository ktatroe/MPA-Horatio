//
//  Copyright © 2016 Kevin Tatroe. All rights reserved.
//  See LICENSE.txt for this sample’s licensing information

import UIKit


enum AppVersionUpdateStyle {
    case None
    case Optional
    case Mandatory
}


class UpgradeAlertOperation: GroupOperation {
    // MARK: - Constants

    private struct LocalizationKeys {
        static let AlertTitle = "UpdateAlertTitle"
        static let AlertMessage = "UpdateAlertBody"

        static let AlertCancelButtonTitle = "UpdateAlertCancelButtonTitle"
        static let AlertUpdateButtonTitle = "UpdateAlertAcceptButtonTitle"
    }


    // MARK: - Initialization

    init() {
        super.init(operations: [])

        guard let environmentManager = Container.resolve(EnvironmentController.self) else { return }
        guard let _ = environmentManager.currentEnvironment() else { return }

        let updateStyle = AppVersionController.sharedController.appUpdateStyle()

        if updateStyle != .None {
            let alertOperation = AlertOperation()
            alertOperation.title = NSLocalizedString(LocalizationKeys.AlertTitle, comment: "")
            alertOperation.message = NSLocalizedString(LocalizationKeys.AlertMessage, comment: "")

            alertOperation.addAction(NSLocalizedString(LocalizationKeys.AlertUpdateButtonTitle, comment: "")) { alertOperation in
                if let appStoreURL = AppVersionController.sharedController.appStoreURL {
                    UIApplication.sharedApplication().openURL(appStoreURL)
                }
            }

            if updateStyle != .Mandatory {
                alertOperation.addAction(NSLocalizedString(LocalizationKeys.AlertCancelButtonTitle, comment: ""), style: .Cancel)
            }

            addOperation(alertOperation)
        }

        name = "Upgrade Alert Operation"
    }
    }


    class AppVersionController: NSObject {
    // MARK: - Constants

    private struct JSONKeys {
        static let GeneralSectionKey = "general"

        static let MandatoryVersionKey = "mandatory_version"
        static let LatestVersionKey = "latest_version"

        static let AppStoreURLKey = "appstore_url"
    }

    private struct UserDefaultsKeys {
        static let AppVersionNotifiedVersions = "MMLAPIEnvironment.NotifiedVersions"
    }


    // MARK: Properties


    static let sharedController = AppVersionController()

    var currentVersion: String? = nil

    var latestVersion: String? = nil
    var mandatoryVersion: String? = nil

    var appStoreURL: NSURL? = nil


    // MARK: Initialization


    override init() {
        self.currentVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? String

        super.init()

        guard let config = Container.resolve(AppConfiguration.self) else { return }

        self.updateFromConfig(config.values)
    }


    // MARK: App Updates


    func appUpdateStyle() -> AppVersionUpdateStyle {
        guard let currentVersion = currentVersion else { return .None }

        if let mandatoryVersion = mandatoryVersion {
            if mandatoryVersion.compare(currentVersion, options:.NumericSearch) == .OrderedDescending {
                return .Mandatory
            }
        }

        if let latestVersion = latestVersion {
            if latestVersion.compare(currentVersion, options: .NumericSearch) == .OrderedDescending {
                if let notifiedVersions = NSUserDefaults.standardUserDefaults().arrayForKey(UserDefaultsKeys.AppVersionNotifiedVersions) as? [String] {
                    if !notifiedVersions.contains(latestVersion) {
                        var mutableVersions = notifiedVersions
                        mutableVersions.append(latestVersion)

                        NSUserDefaults.standardUserDefaults().setObject(mutableVersions, forKey: UserDefaultsKeys.AppVersionNotifiedVersions)

                        return .Optional
                    }
                } else {
                    var mutableVersions = [String]()
                    mutableVersions.append(latestVersion)

                    NSUserDefaults.standardUserDefaults().setObject(mutableVersions, forKey: UserDefaultsKeys.AppVersionNotifiedVersions)

                    return .Optional
                }
            }
        }

        return .None
    }


    // MARK: Private


    private func updateFromConfig(config: EnvironmentConfigValues) -> Void {
        if let appStoreURL = config[AppConfiguration.Values.AppStoreURL] as? NSURL {
            self.appStoreURL = appStoreURL
        } else {
            print("Got an App Store URL that was not a valid URL. Ignoring.")
        }

        if let mandatoryVersionString = config[AppConfiguration.Values.MandatoryVersion] as? String {
            self.mandatoryVersion = mandatoryVersionString
        } else if let mandatoryVersionNumber = config[AppConfiguration.Values.MandatoryVersion] as? Int {
            self.mandatoryVersion = "\(mandatoryVersionNumber)"
        } else {
            print("Got a mandatory version that was neither a string nor a number. Ignoring.")
        }

        if let latestVersionString = config[AppConfiguration.Values.LatestVersion] as? String {
            self.latestVersion = latestVersionString
        } else if let latestVersionNumber = config[AppConfiguration.Values.LatestVersion] as? Int {
            self.latestVersion = "\(latestVersionNumber)"
        } else {
            print("Got a latest version that was neither a string nor a number. Ignoring.")
        }
    }
}
