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

@interface CZPhotoPickerPermissionAlert ()
<UIAlertViewDelegate>
@end

@implementation CZPhotoPickerPermissionAlert

#pragma mark - Class methods

+ (CZPhotoPickerPermissionAlert *)sharedInstance
{
  static CZPhotoPickerPermissionAlert *_sharedInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _sharedInstance = [[CZPhotoPickerPermissionAlert alloc] init];
  });

  return _sharedInstance;
}

#pragma mark - Methods

- (void)showAlert
{
  NSString *title = NSLocalizedString(@"Can’t access camera", nil);
  NSString *message = NSLocalizedString(@"To enable camera access, open\nSettings > Privacy and allow access.", nil);
  NSString *cancel = NSLocalizedString(@"OK", nil);

  UIAlertView *alert;
  if ([CZPhotoPickerController isOS8OrHigher]) {
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:NSLocalizedString(@"Open Settings", nil), nil];
  }
  else {
    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:nil];
  }

  [alert show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != alertView.cancelButtonIndex) {
    NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:URL];
  }
}

@end
