//
//  FotkiCollectionViewController.m
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 04.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "FotkiCollectionViewController.h"
#import "FotkiCollectionViewCell.h"
#import "FotkiDownloader.h"

#import <UIKit/UIRefreshControl.h>

#import "math.h"

@interface FotkiCollectionViewController ()

@property(nonatomic) NSMutableArray<Fotka *> *images;
@property FotkiDownloader *downloader;
@property BOOL useBackup;
@property NSString *backupPath;
@property NSDateFormatter *dateFormatter;

@end

@implementation FotkiCollectionViewController

static NSString * const reuseIdentifier = @"FotkiCollectionViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    // [self.collectionView registerClass:[FotkiCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    NSURL *cachesDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                                    inDomain:NSUserDomainMask
                                                           appropriateForURL:nil
                                                                      create:YES
                                                                       error:nil];
    _backupPath = [cachesDirectory URLByAppendingPathComponent:@"feed"].path;
    _images = [NSMutableArray array];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    _dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    [self resetDownloader];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(resetDownloader) forControlEvents:UIControlEventValueChanged];
    self.collectionView.refreshControl = refreshControl;    
}

- (void)resetDownloader {
    [_downloader cancelDownloads];
    
    void (^downloadedFeedHandler)(NSArray<Fotka *> *) = ^(NSArray<Fotka *> *newImages) {
        [self.collectionView.refreshControl endRefreshing];
        
        if (!newImages) {
            if (_useBackup && [[NSFileManager defaultManager] fileExistsAtPath:_backupPath]) {
                newImages = [NSKeyedUnarchiver unarchiveObjectWithFile:_backupPath];
            }
        }
        
        if (newImages) {
            _useBackup = NO;
            NSMutableArray<NSIndexPath *> *updatedIndexes = [NSMutableArray arrayWithCapacity:[newImages count] + 1];

            @synchronized (_images) {
                for (NSUInteger index = 0; index < [newImages count]; ++index) {
                    [updatedIndexes addObject:[NSIndexPath indexPathForItem:[_images count] + index inSection:0]];
                }
                [_images addObjectsFromArray:newImages];
                [NSKeyedArchiver archiveRootObject:_images toFile:_backupPath];

                [updatedIndexes addObject:[NSIndexPath indexPathForItem:[_images count] inSection:0]];
                [_images addObject:[Fotka null]];
                
                [self.collectionView insertItemsAtIndexPaths:updatedIndexes];
            }
        }
    };
    
    void (^downloadedImageHandler)(NSUInteger) = ^(NSUInteger index) {
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
    };
    
    _useBackup = YES;
    _downloader = [[FotkiDownloader alloc] initWithDownloadedFeedHandler:downloadedFeedHandler
                                                  downloadedImageHandler:downloadedImageHandler];
    @synchronized (_images) {
        [_images removeAllObjects];
        [_images addObject:[Fotka null]];

        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    @synchronized (_images) {
        return [_images count];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FotkiCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    Fotka *image = nil;

    @synchronized (_images) {
        image = _images[indexPath.item];
        if ([image isNull]) {
            [_images removeLastObject];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            });
            image = nil;
        }
    }

    if (image) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:image.filePath.path]) {
            cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:image.filePath]];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"defaultImage"];
            if (!image.required) {
                image.required = YES;
                [_downloader downloadImage:image index:indexPath.item];
            }
        }
    } else {
        cell.imageView.image = nil;
        NSString *url = @"https://api-fotki.yandex.ru/api/podhistory/";
        @synchronized (_images) {
            if ([_images count] > 0) {
                NSDate *date = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitSecond
                                                                        value:-1
                                                                       toDate:[_images lastObject].date
                                                                      options:0];
                url = [url stringByAppendingString:[NSString stringWithFormat:@"poddate;%@/", [_dateFormatter stringFromDate:date]]];
            }
        }
        
        [_downloader downloadFeed:url];
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize collectionViewSize = collectionView.bounds.size;
    CGFloat size = fmin(collectionViewSize.width, collectionViewSize.height) / 4;
    return CGSizeMake(size, size);
}

@end
