//
//  PhotosCollectionWithSearchViewController.m
//  Delightful
//
//  Created by  on 11/8/14.
//  Copyright (c) 2014 Touches. All rights reserved.
//

#import "PhotosCollectionWithSearchViewController.h"

#import "AlbumsDataSource.h"

#import <UIView+AutoLayout.h>

static char *kSearchBarCenterContext;

@interface PhotosCollectionWithSearchViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, assign, getter=isSearching) BOOL searching;

@property (nonatomic, assign) UIEdgeInsets collectionViewInsets;

@end

@implementation PhotosCollectionWithSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame), CGRectGetWidth(self.view.frame), 0)];
    [self.searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.searchBar setDelegate:self];
    [self.searchBar setSearchBarStyle:UISearchBarStyleProminent];
    [self.view addSubview:self.searchBar];
    [self.searchBar sizeToFit];
    
    NSLayoutConstraint *searchLeftConstraint = [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint *searchRightConstraint = [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    NSLayoutConstraint *searchTopConstraint = [NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self.view addConstraints:@[searchLeftConstraint, searchRightConstraint, searchTopConstraint]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillAppear:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidDisappear:) name:UIKeyboardDidHideNotification object:nil];
    
    [self.searchBar addObserver:self forKeyPath:NSStringFromSelector(@selector(center)) options:NSKeyValueObservingOptionNew context:&kSearchBarCenterContext];
    
    [self restoreContentInset];
}

- (void)restoreContentInset {
    [self.collectionView setContentInset:UIEdgeInsetsMake(self.searchBar.isHidden?CGRectGetMaxY(self.navigationController.navigationBar.frame):CGRectGetMaxY(self.searchBar.frame), 0, 0, 0)];
    [self.collectionView setScrollIndicatorInsets:self.collectionView.contentInset];
}

- (void)restoreContentInsetForSize:(CGSize)size {
    [self restoreContentInset];
}

- (void)showSearchBar:(BOOL)show {
    if (self.searchBar.isHidden == show) {
        [self.searchBar setHidden:!show];
        [self restoreContentInset];
        [self.collectionView setContentOffset:CGPointMake(0, -self.collectionView.contentInset.top)];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [((AlbumsDataSource *)self.dataSource) filterWithSearchText:[searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [((AlbumsDataSource *)self.dataSource) filterWithSearchText:nil];
    [searchBar setText:nil];
    [searchBar endEditing:YES];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    self.searching = YES;
    [self.searchBar setShowsCancelButton:YES];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    self.searching = NO;
    [self.searchBar setShowsCancelButton:NO];
    return YES;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
        if (!self.isSearching) {
            [self showSearchBar:([self.dataSource numberOfItems] > 0)?YES:NO];
        }
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(center))]) {
        BOOL needToRestoreOffset = NO;
        if (self.collectionView.contentOffset.y == -self.collectionView.contentInset.top) {
            needToRestoreOffset = YES;
        }
        [self restoreContentInset];
        if (needToRestoreOffset) {
            self.collectionView.contentOffset = CGPointMake(0,  -self.collectionView.contentInset.top);
        }
    }
}

#pragma mark - Keyboard

- (void)keyboardWillAppear:(NSNotification *)notification {
    self.collectionViewInsets = self.collectionView.contentInset;
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.collectionView.contentInset = ({
        UIEdgeInsets inset = self.collectionView.contentInset;
        inset.bottom += keyboardEndFrame.size.height;
        inset;
    });
    [self.collectionView setScrollIndicatorInsets:self.collectionView.contentInset];
}

- (void)keyboardDidDisappear:(NSNotification *)notification {
    [self.collectionView setContentInset:self.collectionViewInsets];
    self.collectionViewInsets = UIEdgeInsetsZero;
    [self.collectionView setScrollIndicatorInsets:self.collectionView.contentInset];
}

@end