// Copyright 2014 Care Zone Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "CZPhotoPickerPermissionAlert.h"
#import "CZPhotoPickerController.h"

@implementation CZPhotoPickerPermissionAlert

#pragma mark - Class methods

+ (UIAlertController *)alertController
{
  NSString *title = NSLocalizedString(@"Can’t access camera", nil);
  NSString *message = NSLocalizedString(@"To enable camera access, open Settings and allow access.", nil);

  UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

  [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];

  [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:URL];
  }]];

  return controller;
}

@end
