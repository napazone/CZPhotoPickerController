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
#import "CZCropPreviewOverlayView.h"

@interface CZCropPreviewOverlayView ()

@property(nonatomic,strong) UIView *bottomMaskView;
@property(nonatomic,assign) CGSize cropOverlaySize;
@property(nonatomic,strong) UIView *highlightView;
@property(nonatomic,strong) UIView *topMaskView;

@end

@implementation CZCropPreviewOverlayView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame cropOverlaySize:(CGSize)cropOverlaySize
{
  self = [super initWithFrame:frame];

  if (self) {
    self.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    self.cropOverlaySize = cropOverlaySize;

    self.topMaskView = [[UIView alloc] initWithFrame:CGRectZero];
    self.bottomMaskView = [[UIView alloc] initWithFrame:CGRectZero];

    [self addSubview:self.topMaskView];
    [self addSubview:self.bottomMaskView];

    UIColor *backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.7];
    self.topMaskView.backgroundColor = backgroundColor;
    self.bottomMaskView.backgroundColor = backgroundColor;

    CAGradientLayer *topGradient = [CAGradientLayer layer];
    topGradient.colors = @[ (id)[UIColor colorWithWhite:1 alpha:0].CGColor,
                            (id)[UIColor colorWithWhite:1 alpha:1].CGColor ];
    topGradient.startPoint = CGPointMake(0.5, 0);
    topGradient.endPoint = CGPointMake(0.5, 1);
    topGradient.frame = self.bottomMaskView.bounds;

    CAGradientLayer *bottomGradient = [CAGradientLayer layer];
    bottomGradient.colors = topGradient.colors;
    bottomGradient.startPoint = topGradient.endPoint;
    bottomGradient.endPoint = topGradient.startPoint;

    self.topMaskView.layer.mask = topGradient;
    self.bottomMaskView.layer.mask = bottomGradient;

    self.highlightView = [[UIView alloc] initWithFrame:CGRectZero];
    self.highlightView.backgroundColor = [UIColor clearColor];
    self.highlightView.layer.borderColor = [UIColor colorWithWhite:1 alpha:.6].CGColor;
    self.highlightView.layer.borderWidth = 1.0f;
    [self addSubview:self.highlightView];
  }

  return self;
}

#pragma mark - UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  // Has the side effect of disabling zoom when taking a picture, but
  // fixes issues related to passing touches through to camera controls
  return nil;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGFloat scale = (CGRectGetWidth(self.frame) / self.cropOverlaySize.width);
  CGSize scaledCropOverlay = CGSizeMake((self.cropOverlaySize.width * scale), (self.cropOverlaySize.height * scale));

  CGFloat yOrigin = (CGRectGetHeight(self.frame) - scaledCropOverlay.height) / 2;

  self.topMaskView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), yOrigin);
  self.bottomMaskView.frame = CGRectMake(0, yOrigin + scaledCropOverlay.height, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - (yOrigin + scaledCropOverlay.height));
  self.highlightView.frame = CGRectMake(0, CGRectGetMaxY(self.topMaskView.frame), CGRectGetWidth(self.frame), CGRectGetMinY(self.bottomMaskView.frame) - CGRectGetMaxY(self.topMaskView.frame));

  self.topMaskView.layer.mask.frame = self.topMaskView.layer.bounds;
  self.bottomMaskView.layer.mask.frame = self.bottomMaskView.layer.bounds;
}

@end
