//
//  PhotosHorizontalScrollingViewController.m
//  PhotoBox
//
//  Created by Nico Prananta on 9/1/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import "PhotosHorizontalScrollingViewController.h"

#import "PhotoBoxModel.h"
#import "PhotoZoomableCell.h"
#import "Photo.h"

#import "UIViewController+Additionals.h"
#import "UIView+Additionals.h"

@interface PhotosHorizontalScrollingViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSInteger previousPage;
@property (nonatomic, assign) BOOL justOpened;

@end

@implementation PhotosHorizontalScrollingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.previousPage = 0;
    self.justOpened = YES;
	
    [self.collectionView setAlwaysBounceVertical:NO];
    [self.collectionView setAlwaysBounceHorizontal:YES];
    [self.collectionView setPagingEnabled:YES];
    
    [self.dataSource setCellIdentifier:[self cellIdentifier]];
    
    [self.collectionView reloadData];
    
    [self.navigationController.interactivePopGestureRecognizer setDelegate:self];
    
    UITapGestureRecognizer *tapOnce = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnce:)];
    [tapOnce setDelegate:self];
    [tapOnce setNumberOfTapsRequired:1];
    [self.collectionView addGestureRecognizer:tapOnce];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDownloadImage:) name:NPRDidSetImageNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self scrollToFirstShownPhoto];
    [self performSelector:@selector(scrollViewDidEndDecelerating:) withObject:self.collectionView afterDelay:1];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.interactivePopGestureRecognizer setDelegate:nil];
}

- (void)showViewOriginalButtonForPage:(NSInteger)page{
    PhotoZoomableCell *cell = (PhotoZoomableCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:page inSection:0]];
    if (cell) {
        [self showViewOriginalButton:![cell hasDownloadedOriginalImage]];
    }
}

- (void)showViewOriginalButton:(BOOL)show {
    if (show) {
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"View Original", nil) style:UIBarButtonItemStylePlain target:self action:@selector(viewOriginalButtonTapped:)];
        [self.navigationItem setRightBarButtonItem:rightButton];
    } else {
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonTapped:)];
        [self.navigationItem setRightBarButtonItem:rightButton];
    }
    
}

- (void)scrollToFirstShownPhoto {
    NSAssert(self.items!=nil, @"Items should not be nil here");
    int index = [self.items indexOfObject:self.firstShownPhoto];
    if (index != NSNotFound) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Override setup

- (NSString *)cellIdentifier {
    return @"photoZoomableCell";
}

- (void)setupPinchGesture {
    // pinch not needed
}

- (void)setupRefreshControl {
    // refresh control not needed
}

- (ResourceType)resourceType {
    return PhotoResource;
}

- (NSString *)resourceId {
    return self.item.itemId;
}


#pragma mark - Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // empty to override superclass
}

#pragma mark - Interactive Gesture Recognizer Delegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.navigationController.interactivePopGestureRecognizer) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gestureRecognizer;
        if (tap.numberOfTapsRequired == 1) {
            if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *other = (UITapGestureRecognizer *)otherGestureRecognizer;
                if (other.numberOfTapsRequired == 2) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)tapOnce:(UITapGestureRecognizer *)tapGesture {
    BOOL show = !self.navigationController.isNavigationBarHidden;
    [self.navigationController setNavigationBarHidden:show animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:show withAnimation:UIStatusBarAnimationSlide];
}


#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = collectionView.frame.size.width;
    CGFloat height = collectionView.frame.size.height - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom;
    return CGSizeMake(width, height);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger page = [self currentCollectionViewPage:scrollView];
    if (self.previousPage != page) {
        self.previousPage = page;
        [self showViewOriginalButtonForPage:page];
        Photo *photo = (Photo *)[self.items objectAtIndex:page];
        if (!self.justOpened) {
            NSLog(@"Tell delegate");
            if (self.delegate && [self.delegate respondsToSelector:@selector(photosHorizontalScrollingViewController:didChangePage:item:)]) {
                [self.delegate photosHorizontalScrollingViewController:self didChangePage:page item:photo];
            }
        } else {
            self.justOpened = NO;
        }
    }
}

- (NSInteger)currentCollectionViewPage:(UIScrollView *)scrollView{
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    return page;
}


#pragma mark - Button

- (void)viewOriginalButtonTapped:(id)sender {
    PhotoZoomableCell *cell = (PhotoZoomableCell *)[[self.collectionView visibleCells] objectAtIndex:0];
    if (cell) {
        [cell loadOriginalImage];
    }
}

- (void)actionButtonTapped:(id)sender {
    PhotoZoomableCell *cell = (PhotoZoomableCell *)[[self.collectionView visibleCells] objectAtIndex:0];
    [self openActivityPickerForImage:[cell originalImage]];
}

#pragma mark - Notification

- (void)didDownloadImage:(NSNotification *)notification {
    [self showViewOriginalButtonForPage:[self currentCollectionViewPage:self.collectionView]];
}

#pragma mark - Custom Animation Transition Delegate

- (UIView *)viewToAnimate {
    PhotoZoomableCell *cell = (PhotoZoomableCell *)[[self.collectionView visibleCells] objectAtIndex:0];
    return cell.thisImageview;
}

- (UIImage *)imageToAnimate {
    return nil;
}

- (CGRect)startRectInContainerView:(UIView *)view {
    PhotoZoomableCell *cell = (PhotoZoomableCell *)[[self.collectionView visibleCells] objectAtIndex:0];
    return [cell.thisImageview convertFrameRectToView:view];
}

- (CGRect)endRectInContainerView:(UIView *)view {
    return CGRectZero;
}

@end