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

@interface FotkiCollectionViewController ()

@property FotkiDownloader *downloader;

@end

@implementation FotkiCollectionViewController

static NSString * const reuseIdentifier = @"FotkiCollectionViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    // [self.collectionView registerClass:[FotkiCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [self resetDownloader];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshFeed) forControlEvents:UIControlEventValueChanged];
    self.collectionView.refreshControl = refreshControl;
    
    [_downloader downloadFeed:@"https://api-fotki.yandex.ru/api/podhistory/"];
}

- (void)resetDownloader {
    [_downloader cancelDownloads];
    
    void (^downloadedFeedHandler)() = ^() {
        [self.collectionView.refreshControl endRefreshing];
    };
    
    void (^downloadedImageHandler)(NSUInteger) = ^(NSUInteger index) {
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
    };
    
    _downloader = [[FotkiDownloader alloc] initWithDownloadedFeedHandler:downloadedFeedHandler
                                                  downloadedImageHandler:downloadedImageHandler];
}

- (void)refreshFeed {
    [self resetDownloader];
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    [_downloader downloadFeed:@"https://api-fotki.yandex.ru/api/podhistory/"];
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
    return 100;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FotkiCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    Fotka *fotka = [_downloader fotkaForIndex:[NSNumber numberWithInteger:indexPath.item]];
    @synchronized (fotka) {
        if (fotka.filePath && [[NSFileManager defaultManager] fileExistsAtPath:fotka.filePath.path]) {
            cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:fotka.filePath]];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"defaultImage"];
            if (!fotka.required) {
                fotka.required = YES;
                if (fotka.src) {
                    [_downloader downloadImage:fotka index:indexPath.item];
                }
            }
        }
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

@end
