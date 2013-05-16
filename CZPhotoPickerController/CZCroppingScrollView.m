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

// This implementation is based heavily on code graciously provided by
// Justin Driscoll – http://www.adevelopingstory.com/

#import "CZCroppingScrollView.h"
#import "CZCropPreviewOverlayView.h"

const NSInteger kCZCroppingScrollViewMaxSharedImageSize = 1024;

double czRad(double deg)
{
  return (deg / 180.0 * M_PI);
}

@interface CZCroppingScrollView ()
<UIScrollViewDelegate>

@property(nonatomic,assign) CGSize cropSize;
@property(nonatomic,strong) UIImage *image;
@property(nonatomic,assign) CGFloat imageOffsetX;
@property(nonatomic,assign) CGFloat imageOffsetY;
@property(nonatomic,strong) UIImageView *imageView;

@end

@implementation CZCroppingScrollView

#pragma mark - Methods

- (UIImage *)croppedImage
{
  CGRect cropFrame = CGRectMake(self.imageOffsetX, self.imageOffsetY, self.cropSize.width, self.cropSize.height);
  CGRect cropRect = [self.superview convertRect:cropFrame toView:self];
  cropRect = [self imageRectFromRect:cropRect];

  CGAffineTransform rectTransform;
  switch (self.image.imageOrientation) {
    case UIImageOrientationLeft:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(czRad(90)), 0, -self.image.size.height);
      break;

    case UIImageOrientationRight:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(czRad(-90)), -self.image.size.width, 0);
      break;

    case UIImageOrientationDown:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(czRad(-180)), -self.image.size.width, -self.image.size.height);
      break;

    default:
      rectTransform = CGAffineTransformIdentity;
  }

  rectTransform = CGAffineTransformScale(rectTransform, self.image.scale, self.image.scale);

  CGImageRef imageRef = CGImageCreateWithImageInRect(self.image.CGImage, CGRectApplyAffineTransform(cropRect, rectTransform));
  UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:self.image.scale orientation:self.image.imageOrientation];
  CGImageRelease(imageRef);

  return croppedImage;
}

- (CGRect)imageRectFromRect:(CGRect)rect
{
  CGFloat scale = 1.0 / self.zoomScale;

  CGPoint origin = rect.origin;
  origin.x = (origin.x - self.imageOffsetX) * scale;
  origin.y = (origin.y - self.imageOffsetY) * scale;

  CGSize size = rect.size;
  size.height = size.height * scale;
  size.width = size.width * scale;

  rect.origin = origin;
  rect.size = size;

  return rect;
}

- (void)setImage:(UIImage *)image
{
  [self.imageView removeFromSuperview];

  _image = image;

  // reset our zoomScale to 1.0 before doing any further calculations
  self.zoomScale = 1.0;

  self.imageOffsetX = (CGRectGetWidth(self.bounds) - self.cropSize.width) / 2;
  self.imageOffsetY = (CGRectGetHeight(self.bounds) - self.cropSize.height) / 2;

  self.imageView = [[UIImageView alloc] initWithImage:self.image];
  self.imageView.frame = CGRectMake(self.imageOffsetX, self.imageOffsetY, image.size.width, image.size.height);

  [self addSubview:self.imageView];

  [self setMaxMinZoomScalesForCurrentBounds];
  [self setZoomScale:self.minimumZoomScale];

  CGSize contentSize = self.imageView.frame.size;
  contentSize.width = contentSize.width + (self.imageOffsetX * 2);
  contentSize.height = contentSize.height + (self.imageOffsetY * 2);
  self.contentSize = contentSize;

  CGSize boundsSize = self.frame.size;
  CGFloat offsetX = (self.contentSize.width - boundsSize.width) / 2;
  CGFloat offsetY = (self.contentSize.height - boundsSize.height) / 2;

  self.contentOffset = CGPointMake(offsetX, offsetY);
}

- (void)setImage:(UIImage *)image withCropSize:(CGSize)cropSize
{
  if (CGSizeEqualToSize(cropSize, CGSizeZero) == NO) {
    self.cropSize = cropSize;

    CZCropPreviewOverlayView *cropOverlayView = [[CZCropPreviewOverlayView alloc] initWithFrame:self.frame cropOverlaySize:cropSize];
    [self.superview insertSubview:cropOverlayView aboveSubview:self];
  }
  else {
    self.scrollEnabled = NO;
    self.cropSize = self.frame.size;
  }

  self.image = image;

  if (CGSizeEqualToSize(cropSize, CGSizeZero)) {
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.frame = self.frame;
  }
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
  CGSize imageSize = self.image.size;

  // calculate min/max zoomscale
  CGFloat xScale = self.cropSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
  CGFloat yScale = self.cropSize.height / imageSize.height;   // the scale needed to perfectly fit the image height-wise

  CGFloat minScale = fmaxf(xScale, yScale);

  // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
  // maximum zoom scale to 0.5.
  xScale = self.cropSize.width / kCZCroppingScrollViewMaxSharedImageSize;
  yScale = self.cropSize.width / kCZCroppingScrollViewMaxSharedImageSize;

  CGFloat maxScale = fminf(1.0 / [[UIScreen mainScreen] scale], fminf(xScale, yScale));

  // Make sure we fill the crop area even for small images
  if (minScale > maxScale) {
    maxScale = minScale;
  }

  self.maximumZoomScale = maxScale;
  self.minimumZoomScale = minScale;
}

#pragma mark - UIView

- (void)awakeFromNib
{
  [super awakeFromNib];

  self.showsVerticalScrollIndicator = NO;
  self.showsHorizontalScrollIndicator = NO;
  self.decelerationRate = UIScrollViewDecelerationRateFast;
  self.delegate = self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGSize contentSize = self.imageView.frame.size;
  contentSize.width = contentSize.width + (self.imageOffsetX * 2);
  contentSize.height = contentSize.height + (self.imageOffsetY * 2);
  self.contentSize = contentSize;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return self.imageView;
}

@end
