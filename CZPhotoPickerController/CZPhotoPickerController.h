// Copyright 2013 Care Zone Inc.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^CZPhotoPickerCompletionBlock)(UIImagePickerController *imagePickerController, NSDictionary *imageInfoDict);

@interface CZPhotoPickerController : NSObject

+ (UIAlertController *)makePermissionAlertController;

/**
 Defaults to NO. This value is passed to UIImagePickerController.
 */
@property(nonatomic,assign) BOOL allowsEditing;

/**
 The bar button item on which to anchor the popover. Either this or sourceView must be set on iPad.
*/
@property(nonatomic,strong) UIBarButtonItem *barButtonItem;

/**
 Defaults to CGSizeZero. When set to a non-zero value, a crop
 overlay view will be displayed atop the selected image at the
 provided size.
 */
@property(nonatomic,assign) CGSize cropOverlaySize;

/**
 Defaults to YES.
*/
@property(nonatomic,assign) BOOL offerLastTaken;

/**
 Defaults to YES.
*/
@property(nonatomic,assign) BOOL saveToCameraRoll;

/**
 The rectangle in the specified view in which to anchor the popover.
 */
@property(nonatomic,assign) CGRect sourceRect;

/**
 The view containing the anchor rectangle for the popover. Either this or `barButtonItem` must be set.
*/
@property(nonatomic,strong) UIView *sourceView;

/**
 The block will be called right before the UIAlertController is presented. Use it if you need \
 to add some custom options to the alert.
 */
@property(nonatomic,copy) void (^willPresentAlertController)(UIAlertController *);

/**
 @param completionBlock Called when a photo has been picked or cancelled (`imageInfoDict` will be `nil` if canceled).
 If `UIImagePickerController` is set, it is your responsibility to dismiss it.
 */
- (instancetype)initWithCompletionBlock:(CZPhotoPickerCompletionBlock)completionBlock;

/**
 @param controller The view controller to present the action sheet and UIImagePickerController from.
*/
- (void)presentFromViewController:(UIViewController *)controller;

@end
