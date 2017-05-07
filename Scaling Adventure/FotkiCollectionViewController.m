//
//  FotkiCollectionViewController.m
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 04.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "FotkiCollectionViewController.h"
#import "FotkiCollectionViewCell.h"

#import <AFURLSessionManager.h>
#import "GDataXMLNode.h"

@interface FotkiCollectionViewController ()

@property(nonatomic) AFURLSessionManager *atomXmlManager;
@property(nonatomic) AFURLSessionManager *imageManager;
@property(nonatomic) NSMutableDictionary<NSNumber *, NSURL *> *images;

@end

@implementation FotkiCollectionViewController

static NSString * const reuseIdentifier = @"FotkiCollectionViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    // [self.collectionView registerClass:[FotkiCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    AFHTTPResponseSerializer *atomXmlResponseSerializer = [AFHTTPResponseSerializer serializer];
    atomXmlResponseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/atom+xml"];
    
    _atomXmlManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    _atomXmlManager.responseSerializer = atomXmlResponseSerializer;
    
    _imageManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    _imageManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    _images = [NSMutableDictionary dictionaryWithCapacity:100];
    
    [self downloadFeed:@"https://api-fotki.yandex.ru/api/podhistory/"];
}

-(void)downloadFeed:(NSString *)urlString {
    [[_atomXmlManager dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]
    completionHandler:^(NSURLResponse * _Nonnull response, id _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithData:responseObject error:nil];
            if (document) {
                NSArray *entries = [document.rootElement elementsForName:@"entry"];
                [entries enumerateObjectsUsingBlock:^(id _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
                    int maxWidth = 0;
                    NSString *href = nil;
                    for (GDataXMLElement *img in [entry elementsForName:@"f:img"]) {
                        int width = [img attributeForName:@"width"].stringValue.intValue;
                        if (width > maxWidth) {
                            maxWidth = width;
                            href = [img attributeForName:@"href"].stringValue;
                        }
                    }
                    [self downloadImage:href index:idx];
                }];
            }
        }
    }] resume];
}

-(void)downloadImage:(NSString *)urlString index:(NSUInteger)index {
    [[_imageManager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] progress:nil
    destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        NSURL *cachesDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                                           inDomain:NSUserDomainMask
                                                                  appropriateForURL:nil
                                                                             create:NO
                                                                              error:nil];
        return [cachesDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    }
    completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        @synchronized (_images) {
            _images[[NSNumber numberWithLong:index]] = filePath;
        }
        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
    }] resume];
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
    
    NSURL *filePath = nil;
    @synchronized (_images) {
        filePath = _images[[NSNumber numberWithLong:indexPath.item]];
    }
    if (filePath) {
        cell.image.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
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
