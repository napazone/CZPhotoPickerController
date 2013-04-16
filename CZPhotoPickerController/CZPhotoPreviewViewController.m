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
  CGFloat scale = self.image.size.width / self.cropOverlaySize.width;
  CGSize scaledCropSize = CGSizeMake(self.cropOverlaySize.width * scale, self.cropOverlaySize.height * scale);

  CGFloat cropY = roundf((self.image.size.height - scaledCropSize.height) / 2);
  CGRect cropRect = CGRectMake(0, cropY, self.image.size.width, scaledCropSize.height);

  CGImageRef croppedImageRef = CGImageCreateWithImageInRect(self.image.CGImage, cropRect);
  UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef scale:self.image.scale orientation:self.image.imageOrientation];
  CGImageRelease(croppedImageRef);

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
  return CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.toolbar.frame));
}

- (void)setupCropOverlay
{
  CGFloat y = (CGRectGetHeight([self previewFrame]) - self.cropOverlaySize.height) / 2;
  y -= 10;
  
  UIView *topMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([self previewFrame]), y)];
  UIView *bottomMask = [[UIView alloc] initWithFrame:CGRectMake(0, y + self.cropOverlaySize.height, CGRectGetWidth([self previewFrame]), CGRectGetHeight([self previewFrame]) - (y + self.cropOverlaySize.height))];

  UIColor *backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.6];
  topMask.backgroundColor = backgroundColor;
  bottomMask.backgroundColor = backgroundColor;

  [self.view insertSubview:topMask aboveSubview:self.imageView];  
  [self.view insertSubview:bottomMask aboveSubview:self.imageView];

  CGRect highlightFrame = CGRectMake(0, CGRectGetMaxY(topMask.frame), CGRectGetWidth(self.view.frame), CGRectGetMinY(bottomMask.frame) - CGRectGetMaxY(topMask.frame));
  UIView *highlightView = [[UIView alloc] initWithFrame:highlightFrame];
  highlightView.backgroundColor = [UIColor clearColor];
  highlightView.layer.borderColor = [UIColor colorWithWhite:1 alpha:.6].CGColor;
  highlightView.layer.borderWidth = 1.0f;
  [self.view insertSubview:highlightView aboveSubview:self.imageView];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.imageView.image = self.image;
  self.imageView.frame = [self previewFrame];

  CGFloat widthRatio = self.imageView.frame.size.width / self.image.size.width;
  CGFloat heightRatio = self.imageView.frame.size.height / self.image.size.height;

  UIViewContentMode mode;

  if (widthRatio < heightRatio) {
    mode = UIViewContentModeScaleAspectFit;
  }
  else {
    mode = UIViewContentModeScaleAspectFill;
  }
  
  self.imageView.contentMode = mode;
  
  CGRect imageViewFrame = self.imageView.frame;
  imageViewFrame.origin.y = (CGRectGetHeight([self previewFrame]) - CGRectGetHeight(self.imageView.frame)) / 2;
  self.imageView.frame = imageViewFrame;

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
    self.imageView.frame = [self previewFrame];

    // Configure the preview label for the cropping use case
    self.previewLabel.shadowColor = [UIColor blackColor];
    self.previewLabel.shadowOffset = CGSizeMake(0, -1);
    self.previewLabel.text = NSLocalizedString(@"Crop Preview", nil);
    [self.previewLabel sizeToFit];
    self.previewLabel.center = self.toolbar.center;

    self.title = self.previewLabel.text;

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
