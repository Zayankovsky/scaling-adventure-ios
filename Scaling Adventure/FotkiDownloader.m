//
//  FotkiDownloader.m
//  Scaling Adventure
//
//  Created by Vitaly Zayankovsky on 09.05.17.
//  Copyright © 2017 Vitaly Zayankovsky. All rights reserved.
//

#import "FotkiDownloader.h"

#import <AFURLSessionManager.h>
#import "GDataXMLNode.h"

typedef void (^FeedCompletionHandler)(NSURLResponse *response, id responseObject, NSError *error);
typedef NSURL * (^Destination)(NSURL *targetPath, NSURLResponse *response);
typedef void (^ImageCompletionHandler)(NSURLResponse *, NSURL *, NSError *);

@interface FotkiDownloader ()

@property AFURLSessionManager *feedManager;
@property AFURLSessionManager *imageManager;
@property void (^downloadedFeedHandler)(NSArray<Fotka *> *);
@property void (^downloadedImageHandler)(NSUInteger);

@end

@implementation FotkiDownloader

- (instancetype)initWithDownloadedFeedHandler:(void (^)(NSArray<Fotka *> *))downloadedFeedHandler
                       downloadedImageHandler:(void (^)(NSUInteger))downloadedImageHandler {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

        AFHTTPResponseSerializer *atomXmlResponseSerializer = [AFHTTPResponseSerializer serializer];
        atomXmlResponseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/atom+xml"];

        self.feedManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        self.feedManager.responseSerializer = atomXmlResponseSerializer;

        self.imageManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        self.imageManager.responseSerializer = [AFImageResponseSerializer serializer];

        self.downloadedFeedHandler = downloadedFeedHandler;
        self.downloadedImageHandler = downloadedImageHandler;
    }
    return self;
}

- (void)downloadFeed:(NSString *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    FeedCompletionHandler completionHandler = ^(NSURLResponse * _Nonnull response,
                                                id _Nullable responseObject,
                                                NSError * _Nullable error) {
        NSMutableArray<Fotka *> *images = nil;
        if (!error) {
            GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithData:responseObject error:nil];
            NSArray<GDataXMLElement *> *entries = [document.rootElement elementsForName:@"entry"];
            images = [NSMutableArray arrayWithCapacity:[entries count]];
            for (GDataXMLElement *entry in entries) {
                [images addObject:[[Fotka alloc] initWithEntry:entry]];
            }
        }
        if (_downloadedFeedHandler) {
            _downloadedFeedHandler(images);
        }
    };
    
    [[_feedManager dataTaskWithRequest:request
                     completionHandler:completionHandler] resume];
}

- (void)downloadImage:(Fotka *)image index:(NSUInteger)index {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[image href]]];
    
    Destination destination = ^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return image.filePath;
    };
    
    ImageCompletionHandler completionHandler = ^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error) {
            if (_downloadedImageHandler) {
                _downloadedImageHandler(index);
            }
        }
    };
    
    [[_imageManager downloadTaskWithRequest:request
                                   progress:nil
                                destination:destination
                          completionHandler:completionHandler] resume];
}

- (void)cancelDownloads {
    _downloadedFeedHandler = nil;
    _downloadedImageHandler = nil;
    [_feedManager invalidateSessionCancelingTasks:YES];
    [_imageManager invalidateSessionCancelingTasks:YES];
}

@end
