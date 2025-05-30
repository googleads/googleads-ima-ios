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

#import "ConsentManager.h"
#import <UserMessagingPlatform/UserMessagingPlatform.h>


@implementation ConsentManager

+ (instancetype)sharedInstance {
  static ConsentManager *shared;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[ConsentManager alloc] init];
  });
  return shared;
}

- (BOOL)canRequestAds {
  return UMPConsentInformation.sharedInstance.canRequestAds;
}

// [START is_privacy_options_required]
- (BOOL)isPrivacyOptionsRequired {
  return UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus ==
         UMPPrivacyOptionsRequirementStatusRequired;
}
// [START is_privacy_options_required]

- (void)gatherConsentFromConsentPresentationViewController:(UIViewController *)viewController
                                  consentGatheringComplete:
                                      (void (^)(NSError *_Nullable))consentGatheringComplete {
  UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
  // Set tag for under age of consent. Use NO constant to indicate that the user is not under age.
  parameters.tagForUnderAgeOfConsent = NO;

  UMPDebugSettings *debugSettings = [[UMPDebugSettings alloc] init];
  // Uncomment the following line to simulate a consent request from users in the
  // European Economic Area (EEA) for testing purposes.
  // debugSettings.geography = UMPDebugGeographyEEA;
  parameters.debugSettings = debugSettings;

  // [START request_consent_info_update]
  // Requesting an update to consent information should be called on every app launch.
  [UMPConsentInformation.sharedInstance
      requestConsentInfoUpdateWithParameters:parameters
                           completionHandler:^(NSError *_Nullable requestConsentError) {
                             // [START_EXCLUDE]
                             if (requestConsentError) {
                               consentGatheringComplete(requestConsentError);
                             } else {
                               [self loadAndPresentIfRequiredFromViewController:viewController
                                                  completionHandler:consentGatheringComplete];
                             }
                             // [END_EXCLUDE]
                           }];
  // [END request_consent_info_update]
}

- (void)loadAndPresentIfRequiredFromViewController:(UIViewController *)viewController
                           completionHandler:(void (^)(NSError *_Nullable))completionHandler {
  // [START load_and_present_consent_form]
  [UMPConsentForm
      loadAndPresentIfRequiredFromViewController:viewController
                               completionHandler:^(NSError *_Nullable loadAndPresentError) {
                                   // Consent gathering process is complete.
                                   // [START_EXCLUDE silent]
                                   completionHandler(loadAndPresentError);
                                   // [END_EXCLUDE]
                                  }];
  // [END load_and_present_consent_form]
}

- (void)presentPrivacyOptionsFormFromViewController:(UIViewController *)viewController
                                  completionHandler:
                                      (void (^)(NSError *_Nullable))completionHandler {
  // [START present_privacy_options_form]
  [UMPConsentForm presentPrivacyOptionsFormFromViewController:viewController
                                            completionHandler:completionHandler];
  // [END present_privacy_options_form]
}

@end
