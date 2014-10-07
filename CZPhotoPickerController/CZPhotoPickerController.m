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

@import AVFoundation;
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "CZPhotoPickerController.h"
#import "CZCropPreviewOverlayView.h"
#import "CZPhotoPickerPermissionAlert.h"
#import "CZPhotoPreviewViewController.h"


typedef enum {
  PhotoPickerButtonUseLastPhoto,
  PhotoPickerButtonTakePhoto,
  PhotoPickerButtonChooseFromLibrary,
} PhotoPickerButtonKind;


@interface CZPhotoPickerController ()
<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIPopoverControllerDelegate>

@property(nonatomic,strong) ALAssetsLibrary *assetsLibrary;
@property(nonatomic,copy) CZPhotoPickerCompletionBlock completionBlock;
@property(nonatomic,strong) UIImage *lastPhoto;
@property(nonatomic,strong) UIPopoverController *popoverController;
@property(nonatomic,weak) UIBarButtonItem *showFromBarButtonItem;
@property(nonatomic,assign) CGRect showFromRect;
@property(nonatomic,weak) UITabBar *showFromTabBar;
@property(nonatomic,weak) UIViewController *showFromViewController;
@property(nonatomic,assign) UIImagePickerControllerSourceType sourceType;

@end


@implementation CZPhotoPickerController

#pragma mark - Class Methods

+ (BOOL)canTakePhoto
{
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
    return NO;
  }

  NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];

  if ([availableMediaTypes containsObject:(NSString *)kUTTypeImage] == NO) {
    return NO;
  }

  return YES;
}

+ (BOOL)isOS7OrHigher
{
  return ([UIDevice currentDevice].systemVersion.floatValue >= 7.0);
}

+ (BOOL)isOS8OrHigher
{
  return ([UIDevice currentDevice].systemVersion.floatValue >= 8.0);
}

#pragma mark - Lifecycle

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (id)initWithPresentingViewController:(UIViewController *)aViewController withCompletionBlock:(CZPhotoPickerCompletionBlock)completionBlock;
{
  self = [super init];

  if (self) {
    self.completionBlock = completionBlock;
    self.offerLastTaken = YES;
    self.saveToCameraRoll = YES;
    self.showFromViewController = aViewController;
    [self observeApplicationDidEnterBackgroundNotification];
  }

  return self;
}

#pragma mark - Methods

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
  [self.popoverController dismissPopoverAnimated:YES];
  self.popoverController = nil;

  if (self.completionBlock) {
    self.completionBlock(nil, nil);
  }
}

- (ALAssetsLibrary *)assetsLibrary
{
  if (_assetsLibrary == nil) {
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
  }

  return _assetsLibrary;
}

- (NSString *)buttonTitleForButtonIndex:(NSUInteger)buttonIndex
{
  switch (buttonIndex) {
    case PhotoPickerButtonUseLastPhoto:
      return NSLocalizedString(@"Use Last Photo Taken", nil);

    case PhotoPickerButtonTakePhoto:
      return NSLocalizedString(@"Take Photo", nil);

    case PhotoPickerButtonChooseFromLibrary:
      return NSLocalizedString(@"Choose from Library", nil);

    default:
      return nil;
  }
}

- (UIImage *)cropImage:(UIImage *)image
{
  CGFloat resizeScale = (image.size.width / self.cropOverlaySize.width);

  CGSize size = image.size;
  CGSize cropSize = CGSizeMake(self.cropOverlaySize.width * resizeScale, self.cropOverlaySize.height * resizeScale);

  CGFloat scalex = cropSize.width / size.width;
  CGFloat scaley = cropSize.height / size.height;
  CGFloat scale = MAX(scalex, scaley);

  UIGraphicsBeginImageContext(cropSize);

  CGFloat width = size.width * scale;
  CGFloat height = size.height * scale;

  CGFloat originX = ((cropSize.width - width) / 2.0f);
  CGFloat originY = ((cropSize.height - height) / 2.0f);

  CGRect rect = CGRectMake(originX, originY, size.width * scale, size.height * scale);
  [image drawInRect:rect];

  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return newImage;
}

- (void)dismissAnimated:(BOOL)animated
{
  if (self.showFromViewController.presentedViewController) {
    [self.showFromViewController dismissViewControllerAnimated:animated completion:nil];
  }
  else if (self.popoverController) {
    [self.popoverController dismissPopoverAnimated:animated];
  }
}

- (void)getLastPhotoTakenWithCompletionBlock:(void (^)(UIImage *))completionBlock
{
  [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {

    if (*stop == YES) {
      return;
    }

    group.assetsFilter = [ALAssetsFilter allPhotos];

    if ([group numberOfAssets] == 0) {
      completionBlock(nil);
    }
    else {
      [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *innerStop) {

          // `index` will be `NSNotFound` on last call

          if (index == NSNotFound || result == nil) {
            return;
          }

          ALAssetRepresentation *representation = [result defaultRepresentation];
          completionBlock([UIImage imageWithCGImage:[representation fullScreenImage]]);

          *innerStop = YES;
        }];
    }

    *stop = YES;

  } failureBlock:^(NSError *error) {
    completionBlock(nil);
  }];
}

- (UIPopoverController *)makePopoverController:(UIImagePickerController *)mediaUI
{
  if (self.popoverControllerClass) {
    return [[self.popoverControllerClass alloc] initWithContentViewController:mediaUI];
  }
  else {
    return [[UIPopoverController alloc] initWithContentViewController:mediaUI];
  }
}

- (void)observeApplicationDidEnterBackgroundNotification
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)show
{
  if ([[self class] canTakePhoto] == NO) {
    [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
  }
  else {
    void (^showActionSheetBlock)(UIImage *) = ^(UIImage *lastPhoto) {

      self.lastPhoto = lastPhoto;

      UIActionSheet *sheet;

      if (lastPhoto) {
        sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:[self buttonTitleForButtonIndex:PhotoPickerButtonUseLastPhoto], [self buttonTitleForButtonIndex:PhotoPickerButtonTakePhoto], [self buttonTitleForButtonIndex:PhotoPickerButtonChooseFromLibrary], nil];
      }
      else {
        sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:[self buttonTitleForButtonIndex:PhotoPickerButtonTakePhoto], [self buttonTitleForButtonIndex:PhotoPickerButtonChooseFromLibrary], nil];
      }

      if (self.showFromBarButtonItem) {
        [sheet showFromBarButtonItem:self.showFromBarButtonItem animated:YES];
      }
      else if (self.showFromTabBar) {
        [sheet showFromTabBar:self.showFromTabBar];
      }
      else {
        [sheet showFromRect:self.showFromRect inView:self.showFromViewController.view animated:YES];
      }
    };

    if (self.offerLastTaken) {
      [self getLastPhotoTakenWithCompletionBlock:showActionSheetBlock];
    }
    else {
      showActionSheetBlock(nil);
    }
  }
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)barButtonItem
{
  self.showFromBarButtonItem = barButtonItem;
  [self show];
}

- (void)showFromTabBar:(UITabBar *)tabBar
{
  self.showFromTabBar = tabBar;
  [self show];
}

- (void)showFromRect:(CGRect)rect
{
  self.showFromRect = rect;
  [self show];
}

- (void)showImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
  if (sourceType == UIImagePickerControllerSourceTypeCamera) {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
      case AVAuthorizationStatusAuthorized:
      case AVAuthorizationStatusNotDetermined:
        // Show UIImagePickerController; it will ask for permission if the status
        // is not determined.
        break;

      case AVAuthorizationStatusDenied:
      case AVAuthorizationStatusRestricted:
        [[CZPhotoPickerPermissionAlert sharedInstance] showAlert];
        break;
    }
  }

  self.sourceType = sourceType;

  UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
  mediaUI.allowsEditing = self.allowsEditing;
  mediaUI.delegate = self;
  mediaUI.mediaTypes = @[ (NSString *)kUTTypeImage ];
  mediaUI.sourceType = sourceType;

  if (sourceType == UIImagePickerControllerSourceTypeCamera && CGSizeEqualToSize(self.cropOverlaySize, CGSizeZero) == NO) {
    CGRect overlayFrame = mediaUI.view.frame;

    BOOL isPhone = (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone);
    BOOL isTallPhone = (isPhone && CGRectGetHeight(UIScreen.mainScreen.bounds) > 480);

    if ([CZPhotoPickerController isOS7OrHigher]) {
      if (isTallPhone) {
        overlayFrame = UIEdgeInsetsInsetRect(overlayFrame, UIEdgeInsetsMake(68, 0, 72, 0));
      }
    }
    else if (isPhone) {
      if (isTallPhone) {
        overlayFrame.size.height -= 96;
      }
      else {
        overlayFrame.size.height -= 54;
      }
    }

    CZCropPreviewOverlayView *overlayView = [[CZCropPreviewOverlayView alloc] initWithFrame:overlayFrame cropOverlaySize:self.cropOverlaySize];
    mediaUI.cameraOverlayView = overlayView;
  }

  if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && (sourceType == UIImagePickerControllerSourceTypePhotoLibrary)) {
    self.popoverController = [self makePopoverController:mediaUI];
    self.popoverController.delegate = self;

    // Bug Workaround (as of iOS 8.0.2) :
    // Presenting popover from popover does not work unless performed with a delay.
    //
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.showFromBarButtonItem) {
        [self.popoverController presentPopoverFromBarButtonItem:self.showFromBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
      }
      else {
        [self.popoverController presentPopoverFromRect:self.showFromRect inView:self.showFromViewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
      }
    });
  }
  else {
    dispatch_async(dispatch_get_main_queue(), ^{ // ditto. see comment above
      [self.showFromViewController presentViewController:mediaUI animated:YES completion:nil];
    });
  }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  actionSheet.delegate = nil;

  if (buttonIndex == actionSheet.cancelButtonIndex) {
    self.completionBlock(nil, nil);
    return;
  }

  if (self.lastPhoto == nil) {
    buttonIndex++;
  }

  switch (buttonIndex) {
    case 0:
      self.completionBlock(nil, @{ UIImagePickerControllerOriginalImage : self.lastPhoto, UIImagePickerControllerEditedImage : self.lastPhoto });
      break;

    case 1:
      [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
      return;

    case 2:
      [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
      break;

    default:
      break;
  }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  UIImage *image = info[(self.allowsEditing ? UIImagePickerControllerEditedImage : UIImagePickerControllerOriginalImage)];

  if (self.sourceType == UIImagePickerControllerSourceTypeCamera && self.saveToCameraRoll) {
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
  }

  // if they chose the photo, and didn't edit, push in a preview

  if (self.allowsEditing == NO && self.sourceType != UIImagePickerControllerSourceTypeCamera) {
    CZPhotoPreviewViewController *vc = [[CZPhotoPreviewViewController alloc] initWithImage:image cropOverlaySize:self.cropOverlaySize chooseBlock:^(UIImage *chosenImage) {
      [self.popoverController dismissPopoverAnimated:YES];

      NSMutableDictionary *mutableImageInfo = [info mutableCopy];
      mutableImageInfo[UIImagePickerControllerEditedImage] = chosenImage;

      self.completionBlock(picker, [mutableImageInfo copy]);
    } cancelBlock:^{
      [picker popViewControllerAnimated:YES];
    }];

    [picker pushViewController:vc animated:YES];
  }
  else {
    NSMutableDictionary *mutableImageInfo = [info mutableCopy];

    if (CGSizeEqualToSize(self.cropOverlaySize, CGSizeZero) == NO) {
      mutableImageInfo[UIImagePickerControllerEditedImage] = [self cropImage:image];
    }

    [self.popoverController dismissPopoverAnimated:YES];

    self.completionBlock(picker, mutableImageInfo);
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  self.completionBlock(nil, nil);
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
  self.popoverController = nil;
  self.completionBlock(nil, nil);
}

@end
