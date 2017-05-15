//
//  FotkiDownloader.h
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 09.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "Fotka.h"

@interface FotkiDownloader : NSObject

-(instancetype)initWithDownloadedFeedHandler:(void (^)(NSArray<Fotka *> *))downloadedFeedHandler
                      downloadedImageHandler:(void (^)(NSUInteger))downloadedImageHandler;

-(void)downloadFeed:(NSString *)url;
-(void)downloadImage:(Fotka *)fotka index:(NSUInteger)index;
-(void)cancelDownloads;

@end
