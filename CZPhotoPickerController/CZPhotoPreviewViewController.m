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

#import "CZPhotoPreviewViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface CZPhotoPreviewViewController ()

@property(nonatomic,copy) dispatch_block_t cancelBlock;
@property(nonatomic,copy) CZPhotoPreviewChooseBlock chooseBlock;
@property(nonatomic,assign) CGSize cropOverlaySize;
@property(nonatomic,strong) UIImage *image;
@property(nonatomic,weak) IBOutlet UIImageView *imageView;
@property(nonatomic,weak) IBOutlet UILabel *previewLabel;
@property(nonatomic,weak) IBOutlet UIToolbar *toolbar;

@end

@implementation CZPhotoPreviewViewController

#pragma mark - Lifecycle

- (id)initWithImage:(UIImage *)anImage cropOverlaySize:(CGSize)cropOverlaySize chooseBlock:(CZPhotoPreviewChooseBlock)chooseBlock cancelBlock:(dispatch_block_t)cancelBlock
{
  NSParameterAssert(chooseBlock);
  NSParameterAssert(cancelBlock);

  self = [super initWithNibName:nil bundle:nil];

  if (self) {
    _cropOverlaySize = cropOverlaySize;
    self.cancelBlock = cancelBlock;
    self.chooseBlock = chooseBlock;
    self.image = anImage;
    self.title = NSLocalizedString(@"Choose Photo", nil);
  }

  return self;
}

#pragma mark - Methods

- (UIImage *)cropImage:(UIImage *)image
{
  BOOL imageIsLandscape = (self.image.size.width > self.image.size.height);
  CGFloat scale;

  if (imageIsLandscape == YES) {
    scale = roundf(self.image.size.width / self.cropOverlaySize.width);
  }
  else {
    scale = roundf(self.image.size.height / self.cropOverlaySize.height);
  }

  CGSize scaledCropSize = CGSizeMake(self.cropOverlaySize.width * scale, self.cropOverlaySize.height * scale);

  CGFloat cropX = 0;
  CGFloat cropY = 0;

  if (imageIsLandscape == YES) {
    cropY = (self.image.size.height - scaledCropSize.height) / 2;
  }
  else {
    cropX = (self.image.size.width - scaledCropSize.width) / 2;
  }

  CGRect cropRect = CGRectMake(cropX, cropY, scaledCropSize.width, scaledCropSize.height);
  CGImageRef croppedImageRef = CGImageCreateWithImageInRect(self.image.CGImage, cropRect);
  UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef scale:self.image.scale orientation:self.image.imageOrientation];

  return croppedImage;
}

- (IBAction)didCancel:(id)sender
{
  self.cancelBlock();
}

- (IBAction)didChoose:(id)sender
{
  UIImage *croppedImage = [self cropImage:self.image];
  self.chooseBlock(croppedImage);
}

- (CGRect)previewFrame
{
  return CGRectMake(0, 20, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.toolbar.frame) - 20);
}

- (void)setupCropOverlay
{
  CGFloat y = (CGRectGetHeight([self previewFrame]) - self.cropOverlaySize.height) / 2;

  UIView *topMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([self previewFrame]), y)];
  UIView *bottomMask = [[UIView alloc] initWithFrame:CGRectMake(0, y + self.cropOverlaySize.height, CGRectGetWidth([self previewFrame]), CGRectGetHeight([self previewFrame]) - (y + self.cropOverlaySize.height))];

  UIColor *backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.85];
  topMask.backgroundColor = backgroundColor;
  bottomMask.backgroundColor = backgroundColor;

  [self.view insertSubview:topMask aboveSubview:self.imageView];  
  [self.view insertSubview:bottomMask aboveSubview:self.imageView];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.imageView.image = self.image;

  if (self.image.size.height > self.image.size.width) {
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
  }

  // No toolbar on iPad, use the nav bar. Mimic how Mail.app’s picker works

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.toolbar.hidden = YES;
    self.previewLabel.hidden = YES;

    // Intentionally not using the bar buttons from the xib as that causes
    // a weird re-layout.

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didCancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Use", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(didChoose:)];
  }
  else {
    self.toolbar.tintColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
  }

  if (CGSizeEqualToSize(self.cropOverlaySize, CGSizeZero) == NO) {
    // UIImagePickerController is a UINavigationController subclass with wantsFullScreenLayout set to YES.
    // We need to apply a small offset to make sure that the image view is centered beneath the overlay view.
    // The offset is the height of the status bar / 2.
    self.imageView.frame = CGRectMake(0, 10 + (CGRectGetHeight([self previewFrame]) - CGRectGetHeight(self.imageView.frame)) / 2, CGRectGetWidth(self.imageView.frame), CGRectGetHeight(self.imageView.frame));

    // Configure the preview label for the cropping use case
    self.previewLabel.shadowColor = [UIColor blackColor];
    self.previewLabel.shadowOffset = CGSizeMake(0, -1);
    self.previewLabel.text = NSLocalizedString(@"Crop Photo", nil);
    [self.previewLabel sizeToFit];
    self.previewLabel.center = self.toolbar.center;

    [self setupCropOverlay];
  }

  [self.view bringSubviewToFront:self.toolbar];
  [self.view bringSubviewToFront:self.previewLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
  CGSize size = CGSizeMake(320, 480);

  self.contentSizeForViewInPopover = size;

  [super viewWillAppear:animated];
}

@end
