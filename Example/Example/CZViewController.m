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

#import <QuartzCore/QuartzCore.h>
#import "CZPhotoPickerController.h"
#import "CZViewController.h"

@interface CZViewController ()
@property(nonatomic,weak) IBOutlet UISwitch *cropPreviewSwitch;
@property(nonatomic,weak) IBOutlet UIImageView *imageView;
@property(nonatomic,strong) CZPhotoPickerController *photoPickerController;
@end

@implementation CZViewController

#pragma mark - Methods

- (IBAction)takePicture:(id)sender
{
  __weak typeof(self) weakSelf = self;

  self.photoPickerController = [[CZPhotoPickerController alloc] initWithPresentingViewController:self withCompletionBlock:^(UIImagePickerController *imagePickerController, NSDictionary *imageInfoDict) {

    UIImage *image = imageInfoDict[UIImagePickerControllerEditedImage];
    if (!image) {
      image = imageInfoDict[UIImagePickerControllerOriginalImage];
    }

    weakSelf.imageView.image = image;

    [weakSelf dismissViewControllerAnimated:YES completion:nil];

  }];

  self.photoPickerController.barButtonItem = sender;
  self.photoPickerController.saveToCameraRoll = NO;

  if (self.cropPreviewSwitch.on) {
    self.photoPickerController.allowsEditing = NO;
    self.photoPickerController.cropOverlaySize = CGSizeMake(320, 100);
  }
  else {
    self.photoPickerController.allowsEditing = YES;
    self.photoPickerController.cropOverlaySize = CGSizeZero;
  }

  [self.photoPickerController show];
}

- (IBAction)toggleCropPreviewSwitch:(id)sender
{
  [self.cropPreviewSwitch setOn:!self.cropPreviewSwitch.on animated:YES];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.imageView.clipsToBounds = YES;
}

@end
