//
//  FotkiDownloader.h
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 09.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "Fotka.h"

@interface FotkiDownloader : NSObject

-(instancetype)initWithDownloadedFeedHandler:(void (^)())downloadedFeedHandler
                      downloadedImageHandler:(void (^)(NSUInteger))downloadedImageHandler;

-(void)downloadFeed;
-(void)downloadImage:(Fotka *)fotka index:(NSUInteger)index;
-(Fotka *)fotkaForIndex:(NSNumber *)index;
-(void)cancelDownloads;

@end
