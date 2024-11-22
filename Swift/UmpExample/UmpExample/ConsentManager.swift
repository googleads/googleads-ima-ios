//
//  Copyright (C) 2023 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UserMessagingPlatform

/// Manages app user's consent using the Google User Messaging Platform SDK or a Consent Management
/// Platform (CMP) that has been certified by Google . See
/// https://support.google.com/admanager/answer/10113209 for more information about GDPR messages
/// for apps. See also https://support.google.com/adsense/answer/13554116 for more information about
/// Google consent management requirements for serving ads in the EEA and UK.

class ConsentManager: NSObject {
  static let shared = ConsentManager()

  var canRequestAds: Bool {
    return UMPConsentInformation.sharedInstance.canRequestAds
  }

  // [START is_privacy_options_required]
  var isPrivacyOptionsRequired: Bool {
    return UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
  }
  // [END is_privacy_options_required]

  /// Helper method to call the UMP SDK methods to request consent information and load/present a
  /// consent form if necessary.
  func gatherConsent(
    from viewController: UIViewController,
    consentGatheringComplete: @escaping (Error?) -> Void
  ) {
    let parameters = UMPRequestParameters()

    //For testing purposes, you can force a UMPDebugGeography of EEA or not EEA.
    let debugSettings = UMPDebugSettings()
    // debugSettings.geography = UMPDebugGeography.EEA
    parameters.debugSettings = debugSettings

    // [START request_consent_info_update]
    // Requesting an update to consent information should be called on every app launch.
    UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) {
      requestConsentError in
      // [START_EXCLUDE]
      guard requestConsentError == nil else {
        return consentGatheringComplete(requestConsentError)
      }

      Task { @MainActor in
        do {
          // [START load_and_present_consent_form]
          try await UMPConsentForm.loadAndPresentIfRequired(from: viewController)
          // [END load_and_present_consent_form]
          // Consent has been gathered.
          consentGatheringComplete(nil)
        } catch {
          consentGatheringComplete(error)
        }
      }
      // [END_EXCLUDE]
    }
    // [END request_consent_info_update]
  }

  /// Helper method to call the UMP SDK method to present the privacy options form.
  func presentPrivacyOptionsForm(
    from viewController: UIViewController, completionHandler: @escaping (Error?) -> Void
  ) {
    // [START present_privacy_options_form]
    UMPConsentForm.presentPrivacyOptionsForm(
      from: viewController, completionHandler: completionHandler)
    // [END present_privacy_options_form]
  }
}
