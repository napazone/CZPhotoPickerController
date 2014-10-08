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
#import "CZCroppingScrollView.h"
#import "CZPhotoPickerController.h"

@interface CZPhotoPreviewViewController ()

@property(nonatomic,copy) dispatch_block_t cancelBlock;
@property(nonatomic,retain) IBOutlet UIBarButtonItem *cancelButton;
@property(nonatomic,copy) void (^chooseBlock)(UIImage *image);
@property(nonatomic,retain) IBOutlet UIBarButtonItem *chooseButton;
@property(nonatomic,assign) CGSize cropOverlaySize;
@property(nonatomic,strong) UIImage *image;
@property(nonatomic,weak) IBOutlet UILabel *previewLabel;
@property(nonatomic,weak) IBOutlet CZCroppingScrollView *croppingScrollView;
@property(nonatomic,weak) IBOutlet UIToolbar *toolbar;

@end

@implementation CZPhotoPreviewViewController

#pragma mark - Lifecycle

- (id)initWithImage:(UIImage *)anImage cropOverlaySize:(CGSize)cropOverlaySize chooseBlock:(void (^)(UIImage *image))chooseBlock cancelBlock:(dispatch_block_t)cancelBlock
{
  NSParameterAssert(chooseBlock);
  NSParameterAssert(cancelBlock);

  NSString *mainBundlePath = [[NSBundle mainBundle] resourcePath];
  NSString *frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"CZPhotoPickerController.bundle"];
  NSBundle *bundle = [NSBundle bundleWithPath:frameworkBundlePath];

  self = [super initWithNibName:nil bundle:bundle];

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

- (BOOL)allowMoveAndScale
{
  return (CGSizeEqualToSize(self.cropOverlaySize, CGSizeZero) == NO);
}

- (IBAction)didCancel:(id)sender
{
  self.cancelBlock();
}

- (IBAction)didChoose:(id)sender
{
  if (self.allowMoveAndScale) {
    self.image = [self.croppingScrollView croppedImage];
  }

  self.chooseBlock(self.image);
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

#if __IPHONE_7_0
  self.cancelButton.tintColor = [UIColor whiteColor];
  self.chooseButton.tintColor = [UIColor whiteColor];
  self.previewLabel.hidden = YES;
#endif

  // No toolbar on iPad, use the nav bar. Mimic how Mail.app’s picker works

  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    self.toolbar.hidden = YES;
    self.previewLabel.hidden = YES;

    // Intentionally not using the bar buttons from the xib as that causes
    // a weird re-layout.

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didCancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Use", nil) style:UIBarButtonItemStyleDone target:self action:@selector(didChoose:)];
  }
  else {
    self.toolbar.tintColor = [UIColor blackColor];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
  }

  if (self.allowMoveAndScale) {
    // Configure the preview label for the cropping use case

    self.previewLabel.shadowColor = [UIColor blackColor];
    self.previewLabel.shadowOffset = CGSizeMake(0, -1);
    self.previewLabel.text = NSLocalizedString(@"Move and Scale", nil);
    [self.previewLabel sizeToFit];
    self.previewLabel.center = self.toolbar.center;

    self.title = self.previewLabel.text;
  }

  [self.view bringSubviewToFront:self.toolbar];
  [self.view bringSubviewToFront:self.previewLabel];
}

- (void)viewWillAppear:(BOOL)animated
{
  CGSize preferredSize = CGSizeMake(320, 480);
  if ([CZPhotoPickerController isOS7OrHigher]) {
    self.preferredContentSize = preferredSize;
  }
  else {
    self.contentSizeForViewInPopover = preferredSize;
  }

  [self.croppingScrollView setImage:self.image withCropSize:self.cropOverlaySize];

  [super viewWillAppear:animated];
}

@end
