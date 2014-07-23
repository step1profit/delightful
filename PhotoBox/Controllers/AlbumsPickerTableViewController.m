//
//  AlbumsPickerTableViewController.m
//  Delightful
//
//  Created by  on 7/23/14.
//  Copyright (c) 2014 Touches. All rights reserved.
//

#import "AlbumsPickerTableViewController.h"

#import "Album.h"

#import "PhotoBoxClient.h"

typedef NS_ENUM(NSInteger, AlbumsPickerState) {
    AlbumsPickerStateNormal,
    AlbumsPickerStateFetching
};

@interface AlbumsPickerTableViewController ()

@property (nonatomic, strong) NSMutableArray *albums;

@property (nonatomic, assign) BOOL isFetchingAlbums;

@property (nonatomic, strong) UIView *headerView;

@property (nonatomic, strong) UIButton *headerViewButton;

@property (nonatomic, assign) AlbumsPickerState state;

@end

@implementation AlbumsPickerTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Albums", nil);
    
    if (!self.headerView) {
        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.navigationController.view.frame), self.tableView.contentInset.top, CGRectGetWidth(self.view.frame), 44)];
        self.headerView.alpha = 0;
        [self.headerView setBackgroundColor:[UIColor whiteColor]];
        UIButton *newAlbumButton = [[UIButton alloc] initWithFrame:self.headerView.bounds];
        [newAlbumButton setTitle:NSLocalizedString(@"Fetching albums ...", nil) forState:UIControlStateNormal];
        [newAlbumButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [newAlbumButton setTitleColor:[[[[UIApplication sharedApplication] delegate] window] tintColor] forState:UIControlStateNormal];
        [newAlbumButton addTarget:self action:@selector(addAlbumButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.headerView addSubview:newAlbumButton];
        self.headerViewButton = newAlbumButton;
    }
    [self.navigationController.view insertSubview:self.headerView belowSubview:self.navigationController.navigationBar];
    
    self.tableView.contentInset = ({
        UIEdgeInsets inset = self.tableView.contentInset;
        inset.top += CGRectGetHeight(self.headerView.frame);
        inset;
    });
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    self.headerView.frame = ({
        CGRect frame = self.headerView.frame;
        frame.origin.y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
        frame;
    });
    
    [self.headerView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.headerView.layer setShadowOffset:CGSizeMake(0, 1)];
    [self.headerView.layer setShadowRadius:0];
    [self.headerView.layer setShadowOpacity:0.1];
    [self.headerView.layer setShadowPath:[UIBezierPath bezierPathWithRect:self.headerView.bounds].CGPath];
    
    [self fetchAlbums];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.headerView.frame = ({
            CGRect frame = self.headerView.frame;
            frame.origin.x = 0;
            frame;
        });
        [self.headerView setAlpha:1];
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.headerViewButton removeFromSuperview];
    self.headerViewButton = nil;
    [self.headerView removeFromSuperview];
    self.headerView = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setState:(AlbumsPickerState)state {
    _state = state;
    
    if (state == AlbumsPickerStateFetching) {
        [self.headerViewButton setTitle:NSLocalizedString(@"Fetching albums ...", nil) forState:UIControlStateNormal];
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithCustomView:activityView];
        [activityView startAnimating];
        [self.navigationItem setRightBarButtonItem:addButton];
        self.isFetchingAlbums = YES;
    } else {
        [self.headerViewButton setTitle:NSLocalizedString(@"Create new album", nil) forState:UIControlStateNormal];
        [self.navigationItem setRightBarButtonItem:nil];
        self.isFetchingAlbums = NO;
    }
}

- (void)fetchAlbums {
    if (!self.isFetchingAlbums) {
        self.state = AlbumsPickerStateFetching;
        
        [[PhotoBoxClient sharedClient] getResource:AlbumResource action:ListAction resourceId:nil page:0 success:^(NSArray *objects) {
            NSLog(@"Objects = %@", objects);
            self.state = AlbumsPickerStateNormal;
            
            Album *a = [[Album alloc] init];
            [a setValue:@"Test album" forKey:@"name"];
            Album *b = [[Album alloc] init];
            [b setValue:@"Album album" forKey:@"name"];
            Album *c = [[Album alloc] init];
            [c setValue:@"Anon album" forKey:@"name"];
            objects = @[a, b, c];
            
            if (objects.count > 0) {
                UILocalizedIndexedCollation *theCollation = [UILocalizedIndexedCollation currentCollation];
                
                for (Album *theAlbum in objects) {
                    NSInteger sect = [theCollation sectionForObject:theAlbum collationStringSelector:@selector(name)];
                    theAlbum.sectionNumber = sect;
                }
                
                NSInteger highSection = [[theCollation sectionTitles] count];
                NSMutableArray *sectionArrays = [NSMutableArray arrayWithCapacity:highSection];
                for (int i = 0; i < highSection; i++) {
                    NSMutableArray *sectionArray = [NSMutableArray arrayWithCapacity:1];
                    [sectionArrays addObject:sectionArray];
                }
                
                for (Album *theAlbum in objects) {
                    [(NSMutableArray *)[sectionArrays objectAtIndex:theAlbum.sectionNumber] addObject:theAlbum];
                }
                
                if (!self.albums) {
                    self.albums = [NSMutableArray array];
                }
                
                for (NSMutableArray *sectionArray in sectionArrays) {
                    NSArray *sortedSection = [theCollation sortedArrayFromArray:sectionArray
                                                        collationStringSelector:@selector(name)];
                    [self.albums addObject:sortedSection];
                }
                
                [self.tableView reloadData];
            }
            
        } failure:^(NSError *error) {
            self.state = AlbumsPickerStateNormal;
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.albums.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [(NSArray *)[self.albums  objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"albumCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"albumCell"];
    }
    cell.textLabel.text = ((Album *)[(NSArray *)[self.albums objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]).name;
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.albums.count == 0) {
        return nil;
    }
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([(NSArray *)[self.albums objectAtIndex:section] count] > 0) {
        return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(albumsPickerViewController:didSelectAlbum:)]) {
        [self.delegate albumsPickerViewController:self didSelectAlbum:[(NSArray *)[self.albums objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
    }
}

#pragma mark - Button actions

- (void)addAlbumButtonTapped:(id)sender {
    NSLog(@"add tapped");
}

@end