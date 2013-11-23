//
//  AlbumSectionHeaderView.m
//  Delightful
//
//  Created by Nico Prananta on 11/21/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import "AlbumSectionHeaderView.h"

#import <UIView+AutoLayout.h>

#import <AMBlurView.h>

#import "UIView+Additionals.h"

@interface AlbumSectionHeaderView ()

@property (nonatomic, weak) UIImageView *arrowImage;

@end

@implementation AlbumSectionHeaderView

- (void)setup {
    [super setup];
    
    [self.titleLabel setHidden:YES];
    [self.locationLabel setTextColor:[UIColor whiteColor]];
    
}

- (UIImageView *)arrowImage {
    if (!_arrowImage) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"right.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [imageView setBackgroundColor:[UIColor clearColor]];
        [imageView setTintColor:[UIColor whiteColor]];
        [self addSubview:imageView];
        _arrowImage = imageView;
    }
    return _arrowImage;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [self addSubviewClass:[UIView class]];
        [_lineView setBackgroundColor:[UIColor colorWithRed:0.297 green:0.284 blue:0.335 alpha:1.000]];
    }
    return _lineView;
}

- (void)setupConstrains {
    [self.arrowImage autoCenterInSuperviewAlongAxis:ALAxisHorizontal];
    [self.arrowImage autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self withOffset:-80];
    
    [self.locationLabel autoCenterInSuperviewAlongAxis:ALAxisHorizontal];
    [self.locationLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self withOffset:10];
    
    [self.titleLabel autoCenterInSuperviewAlongAxis:ALAxisHorizontal];
    [self.titleLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self withOffset:-80];
    
    [self.blurView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
    [self.blurView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
    [self.blurView autoCenterInSuperview];
    
    [self.lineView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withOffset:-20];
    [self.lineView autoSetDimension:ALDimensionHeight toSize:1];
    [self.lineView autoCenterInSuperviewAlongAxis:ALAxisVertical];
    [self.lineView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
}

@end
