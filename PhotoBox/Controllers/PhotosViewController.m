//
//  PhotosViewController.m
//  PhotoBox
//
//  Created by Nico Prananta on 8/31/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import "PhotosViewController.h"

#import "Album.h"
#import "Photo.h"

#import "LocationManager.h"

#import "PhotosSectionHeaderView.h"
#import "PhotoBoxCell.h"

#import "PhotosHorizontalScrollingViewController.h"

#import "UIView+Additionals.h"

@interface PhotosViewController () <UICollectionViewDelegateFlowLayout, PhotosHorizontalScrollingViewControllerDelegate>

@property (nonatomic, strong) PhotoBoxCell *selectedItem;
@property (nonatomic, strong) NSMutableDictionary *locationDictionary;
@property (nonatomic, strong) NSMutableDictionary *placemarkDictionary;
@end

@implementation PhotosViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setPhotosCount:0 max:0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [NPRImageView cancelAllOperations];
}


- (CollectionViewHeaderCellConfigureBlock)headerCellConfigureBlock {
    void (^configureCell)(PhotosSectionHeaderView*, id,NSIndexPath*) = ^(PhotosSectionHeaderView* cell, id item, NSIndexPath *indexPath) {
        [cell setTitleLabelText:item];
        if ([self.placemarkDictionary objectForKey:@(indexPath.section)]) {
            [cell setLocation:[self.placemarkDictionary objectForKey:@(indexPath.section)]];
        } else {
            [cell setLocation:nil];
        }
    };
    return configureCell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)cellIdentifier {
    return @"photoCell";
}

- (NSString *)groupKey {
    return @"dateTakenString";
}

- (NSString *)sectionHeaderIdentifier {
    return @"photoSection";
}

- (ResourceType)resourceType {
    return PhotoResource;
}

- (Class)resourceClass {
    return [Photo class];
}

- (NSString *)resourceId {
    return self.item.itemId;
}

- (NSString *)relationshipKeyPathWithItem {
    return @"albums";
}

- (NSArray *)sortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"dateTaken" ascending:YES]];
}

- (void)didFetchItems {
    int count = [self.dataSource numberOfItems];
    [self setPhotosCount:count max:self.totalItems];
    [self getLocationForEachSection];
}


- (void)setPhotosCount:(int)count max:(int)max{
    NSString *title = NSLocalizedString(@"Photos", nil);
    Album *album = (Album *)self.item;
    if (album) {
        title = album.name;
    }
    if (count == 0) {
        self.title = title;
    } else {
        [self setTitle:title subtitle:[NSString stringWithFormat:NSLocalizedString(@"Showing %1$d of %2$d photos", nil), count, max]];
    }
}

#pragma mark - Header Things

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(CGRectGetWidth(self.collectionView.frame), 44);
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"pushPhoto"]) {
        PhotosHorizontalScrollingViewController *destination = (PhotosHorizontalScrollingViewController *)segue.destinationViewController;
        PhotoBoxCell *cell = (PhotoBoxCell *)sender;
        [destination setItem:self.item];
        [destination setFirstShownPhoto:cell.item];
        [destination setFirstShownPhotoIndex:[self.dataSource positionOfItem:cell.item]];
        [destination setDelegate:self];
        self.selectedItem = cell;
    }
}

#pragma mark - CustomAnimationTransitionFromViewControllerDelegate

- (UIImage *)imageToAnimate {
    return self.selectedItem.cellImageView.image;
}

- (CGRect)startRectInContainerView:(UIView *)containerView {
    return [self.selectedItem convertFrameRectToView:containerView];
}

- (CGRect)endRectInContainerView:(UIView *)containerView {
    return [self.selectedItem convertFrameRectToView:containerView];
}

- (UIView *)viewToAnimate {
    return nil;
}

#pragma mark - PhotosHorizontalScrollingViewControllerDelegate

- (void)photosHorizontalScrollingViewController:(PhotosHorizontalScrollingViewController *)viewController didChangePage:(NSInteger)page item:(Photo *)item {
    NSIndexPath *indexPath = [self.dataSource indexPathOfItem:item];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    self.selectedItem = (PhotoBoxCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark - Location

- (void)getLocationForEachSection {
    if (!self.locationDictionary) {
        self.locationDictionary = [NSMutableDictionary dictionary];
    }
    int i = 0;
    for (id<NSFetchedResultsSectionInfo> section in self.dataSource.fetchedResultsController.sections) {
        for (NSManagedObject *photo in section.objects) {
            NSNumber *latitude = [photo valueForKey:@"latitude"];
            NSNumber *longitude = [photo valueForKey:@"longitude"];
            if (latitude && ![latitude isKindOfClass:[NSNull class]] && longitude && ![longitude isKindOfClass:[NSNull class]]) {
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
                [self.locationDictionary setObject:location forKey:@(i)];
                break;
            }
        }
        i++;
    }
    
    for (NSNumber *section in self.locationDictionary.allKeys) {
        CLLocation *location = [self.locationDictionary objectForKey:section];
        [[LocationManager sharedManager] nameForLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if (!error && placemarks.count > 0) {
                [self updateSectionHeader:[section integerValue] placemark:placemarks[0]];
            }
        }];
    }
}

- (void)updateSectionHeader:(NSInteger)section placemark:(CLPlacemark *)placemark {
    if (!self.placemarkDictionary) {
        self.placemarkDictionary = [NSMutableDictionary dictionary];
    }
    if (placemark) {
        [self.placemarkDictionary setObject:placemark forKey:@(section)];
        [[NSNotificationCenter defaultCenter] postNotificationName:PhotoBoxLocationPlacemarkDidFetchNotification object:@{@"placemark": placemark, @"section":@(section)}];
    }
}

@end
