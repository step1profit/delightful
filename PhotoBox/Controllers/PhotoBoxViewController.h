//
//  PhotoBoxViewController.h
//  PhotoBox
//
//  Created by Nico Prananta on 8/31/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PhotoBoxClient.h"
#import "CollectionViewDataSource.h"

extern NSString *const galleryContainerType;

typedef NS_ENUM(NSUInteger, PinchDirection) {
    PinchIn,
    PinchOut
};

@class PhotoBoxModel;

@interface PhotoBoxViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, assign) ResourceType resourceType;
@property (nonatomic, strong) Class resourceClass;
@property (nonatomic, strong) NSString *resourceId;
@property (nonatomic, strong) NSString *relationshipKeyPathWithItem;
@property (nonatomic, strong, readonly) NSString *cellIdentifier;
@property (nonatomic, strong, readonly) NSString *sectionHeaderIdentifier;
@property (nonatomic, strong, readonly) NSString *footerIdentifier;

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) int numberOfColumns;
@property (nonatomic, strong) id selectedItem;
@property (nonatomic, strong) UILabel *navigationTitleLabel;

@property (nonatomic) CollectionViewDataSource *dataSource;

@property (nonatomic, assign) BOOL registerSyncingNotification;

@property (nonatomic, assign) BOOL isFetching;
@property (nonatomic, assign) BOOL isDoneSyncing;

- (UICollectionViewCell *)selectedCell;
- (Class)dataSourceClass;
- (void)refresh;
- (void)showError:(NSError *)error;
- (CollectionViewCellConfigureBlock)cellConfigureBlock;
- (CollectionViewHeaderCellConfigureBlock)headerCellConfigureBlock;
- (void)setupDataSourceConfigureBlock;
- (void)setTitle:(NSString *)title subtitle:(NSString *)sub;
- (void)didChangeNumberOfColumns;
- (void)setAttributedTitle:(NSAttributedString *)title;
- (void)restoreContentInset;
- (void)restoreContentInsetForSize:(CGSize)size;

- (void)userDidLogout;

- (void)showEmptyLoading:(BOOL)show;
- (void)showEmptyLoading:(BOOL)show withText:(id)text;
- (void)showNoItems:(BOOL)show;
- (void)showRightBarButtonItem:(BOOL)show;

@end
