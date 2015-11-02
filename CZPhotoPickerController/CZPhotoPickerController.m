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

typedef NS_ENUM (NSUInteger, PhotoPickerButtonKind) {
  PhotoPickerButtonUseLastPhoto,
  PhotoPickerButtonTakePhoto,
  PhotoPickerButtonChooseFromLibrary,
};

@interface CZPhotoPickerController ()
<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic,strong) ALAssetsLibrary *assetsLibrary;
@property(nonatomic,copy) CZPhotoPickerCompletionBlock completionBlock;
@property(nonatomic,strong) UIImage *lastPhoto;
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

#pragma mark - Lifecycle

- (id)initWithCompletionBlock:(CZPhotoPickerCompletionBlock)completionBlock;
{
  self = [super init];

  if (self) {
    _completionBlock = [completionBlock copy];
    _offerLastTaken = YES;
    _saveToCameraRoll = YES;
  }

  return self;
}

#pragma mark - Methods

- (ALAssetsLibrary *)assetsLibrary
{
  if (_assetsLibrary == nil) {
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
  }

  return _assetsLibrary;
}

- (NSString *)buttonTitleForButtonKind:(PhotoPickerButtonKind)kind
{
  switch (kind) {
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

- (void)observeApplicationDidEnterBackgroundNotification
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)presentFromViewController:(UIViewController *)fromViewController
{
  if ([[self class] canTakePhoto] == NO) {
    [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary fromViewController:fromViewController];
    return;
  }

  void (^showBlock)(UIImage *) = ^(UIImage *lastPhoto) {

    self.lastPhoto = lastPhoto;

    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    if (lastPhoto) {
      NSString *title = [self buttonTitleForButtonKind:PhotoPickerButtonUseLastPhoto];
      [controller addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.completionBlock(nil, @{ UIImagePickerControllerOriginalImage : lastPhoto, UIImagePickerControllerEditedImage : lastPhoto });
      }]];
    }

    NSString *takeTitle = [self buttonTitleForButtonKind:PhotoPickerButtonTakePhoto];
    [controller addAction:[UIAlertAction actionWithTitle:takeTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera fromViewController:fromViewController];
    }]];

    NSString *chooseTitle = [self buttonTitleForButtonKind:PhotoPickerButtonChooseFromLibrary];
    [controller addAction:[UIAlertAction actionWithTitle:chooseTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      [self showImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary fromViewController:fromViewController];
    }]];

    NSString *cancelTitle = NSLocalizedString(@"Cancel", nil);
    [controller addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
      self.completionBlock(nil, nil);
    }]];

    [fromViewController presentViewController:controller animated:YES completion:nil];

  };

  if (self.offerLastTaken) {
    [self getLastPhotoTakenWithCompletionBlock:showBlock];
  }
  else {
    showBlock(nil);
  }
}

- (void)showImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType fromViewController:(UIViewController *)fromViewController
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
      case AVAuthorizationStatusRestricted: {
        UIViewController *controller = [CZPhotoPickerPermissionAlert alertController];
        [fromViewController presentViewController:controller animated:YES completion:nil];
        break;
      }
    }
  }

  self.sourceType = sourceType;

  UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
  imagePickerController.allowsEditing = self.allowsEditing;
  imagePickerController.delegate = self;
  imagePickerController.mediaTypes = @[ (NSString *)kUTTypeImage ];
  imagePickerController.sourceType = sourceType;

  if (sourceType == UIImagePickerControllerSourceTypeCamera && CGSizeEqualToSize(self.cropOverlaySize, CGSizeZero) == NO) {

    CGRect overlayFrame = imagePickerController.view.frame;

    BOOL isPhone = (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone);
    BOOL isTallPhone = (isPhone && CGRectGetHeight(UIScreen.mainScreen.bounds) > 480);

    if (isTallPhone) {
      overlayFrame = UIEdgeInsetsInsetRect(overlayFrame, UIEdgeInsetsMake(68, 0, 72, 0));
    }

    CZCropPreviewOverlayView *overlayView = [[CZCropPreviewOverlayView alloc] initWithFrame:overlayFrame cropOverlaySize:self.cropOverlaySize];
    imagePickerController.cameraOverlayView = overlayView;
  }

  if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && (sourceType == UIImagePickerControllerSourceTypePhotoLibrary)) {
    imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
    if (self.barButtonItem) {
      imagePickerController.popoverPresentationController.barButtonItem = self.barButtonItem;
    }
    else {
      imagePickerController.popoverPresentationController.sourceView = self.sourceView;
      imagePickerController.popoverPresentationController.sourceRect = self.sourceRect;
    }
    [fromViewController presentViewController:imagePickerController animated:YES completion:nil];
  }
  else {
    [fromViewController presentViewController:imagePickerController animated:YES completion:nil];
  }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)pickerViewController didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  UIImage *image = info[(self.allowsEditing ? UIImagePickerControllerEditedImage : UIImagePickerControllerOriginalImage)];

  if (self.sourceType == UIImagePickerControllerSourceTypeCamera && self.saveToCameraRoll) {
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
  }

  // if they chose the photo, and didn't edit, push in a preview

  if (self.allowsEditing == NO && self.sourceType != UIImagePickerControllerSourceTypeCamera) {
    CZPhotoPreviewViewController *vc = [[CZPhotoPreviewViewController alloc] initWithImage:image cropOverlaySize:self.cropOverlaySize chooseBlock:^(UIImage *chosenImage) {
      [pickerViewController dismissViewControllerAnimated:YES completion:nil];

      NSMutableDictionary *mutableImageInfo = [info mutableCopy];
      mutableImageInfo[UIImagePickerControllerEditedImage] = chosenImage;

      self.completionBlock(pickerViewController, [mutableImageInfo copy]);
    } cancelBlock:^{
      [pickerViewController popViewControllerAnimated:YES];
    }];

    [pickerViewController pushViewController:vc animated:YES];
  }
  else {
    NSMutableDictionary *mutableImageInfo = [info mutableCopy];

    if (CGSizeEqualToSize(self.cropOverlaySize, CGSizeZero) == NO) {
      mutableImageInfo[UIImagePickerControllerEditedImage] = [self cropImage:image];
    }

    [pickerViewController dismissViewControllerAnimated:YES completion:nil];

    self.completionBlock(pickerViewController, mutableImageInfo);
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  self.completionBlock(nil, nil);
}

@end
