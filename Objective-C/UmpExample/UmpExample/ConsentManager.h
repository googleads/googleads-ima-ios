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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Manages app user's consent using the Google User Messaging Platform SDK or a Consent Management
/// Platform (CMP) that has been certified by Google . See
/// https://support.google.com/admanager/answer/10113209 for more information about GDPR messages
/// for apps. See also https://support.google.com/adsense/answer/13554116 for more information about
/// Google consent management requirements for serving ads in the EEA and UK.
@interface ConsentManager : NSObject

@property(class, atomic, readonly, strong, nonnull) ConsentManager *sharedInstance;
@property(nonatomic, readonly) BOOL canRequestAds;
@property(nonatomic, readonly) BOOL isPrivacyOptionsRequired;

/// Helper method to call the UMP SDK methods to request consent information and load/present a
/// consent form if necessary.
- (void)gatherConsentFromConsentPresentationViewController:(UIViewController *)viewController
                                  consentGatheringComplete:
                                      (void (^)(NSError *_Nullable error))completionHandler;

/// Helper method to call the UMP SDK method to present the privacy options form.
- (void)presentPrivacyOptionsFormFromViewController:(UIViewController *)viewController
                                  completionHandler:
                                      (void (^)(NSError *_Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
