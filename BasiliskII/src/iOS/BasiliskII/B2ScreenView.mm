//
//  B2ScreenView.m
//  BasiliskII
//
//  Created by Jesús A. Álvarez on 09/03/2014.
//  Copyright (c) 2014 namedfork. All rights reserved.
//

#import "B2ScreenView.h"
#include "sysdeps.h"
#include "video.h"
#import "B2AppDelegate.h"

B2ScreenView *sharedScreenView = nil;

@implementation B2ScreenView
{
    CGImageRef screenImage;
    CALayer *videoLayer;
}

- (void)awakeFromNib {
    sharedScreenView = self;
    [self initVideoModes];
    videoLayer = [CALayer layer];
    [self.layer addSublayer:videoLayer];
}

- (BOOL)hasRetinaVideoMode {
    return [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad && (int)[UIScreen mainScreen].scale == 2;
}

- (void)initVideoModes {
    NSMutableArray *videoModes = [[NSMutableArray alloc] initWithCapacity:8];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.width < screenSize.height) {
        auto swp = screenSize.width;
        screenSize.width = screenSize.height;
        screenSize.height = swp;
    }
    
    // current screen size
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"videoDepth": @(8), @"videoSize": NSStringFromCGSize(screenSize)}];
    [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(screenSize.width, screenSize.height)]];
    [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(screenSize.height, screenSize.width)]];
    if ([self hasRetinaVideoMode]) {
        [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(screenSize.width * 2, screenSize.height * 2)]];
        [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(screenSize.height * 2, screenSize.width * 2)]];
    }
    
    // default resolutions
    [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(512, 384)]];
    [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(640, 480)]];
    [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(800, 600)]];
    [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(832, 624)]];
    if (screenSize.width > 1024) {
        [videoModes addObject:[NSValue valueWithCGSize:CGSizeMake(1024, 768)]];
    }
    _videoModes = [NSArray arrayWithArray:videoModes];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_screenSize.width > 0.0) {
        [self setScreenSize:_screenSize];
    }
}

- (CGRect)_threadsafeBounds {
    if ([NSThread isMainThread]) {
        return self.bounds;
    } else {
        __block CGRect bounds;
        dispatch_sync(dispatch_get_main_queue(), ^{
            bounds = self.bounds;
        });
        return bounds;
    }
}

- (void)setScreenSize:(CGSize)screenSize {
    _screenSize = screenSize;
    CGRect viewBounds = [self _threadsafeBounds];
    CGFloat screenScale = MAX(screenSize.width / viewBounds.size.width, screenSize.height / viewBounds.size.height);
    _screenBounds = CGRectMake(0, 0, screenSize.width / screenScale, screenSize.height / screenScale);
    _screenBounds.origin.x = (viewBounds.size.width - _screenBounds.size.width)/2;
    _screenBounds = CGRectIntegral(_screenBounds);
    videoLayer.frame = _screenBounds;
}

- (void)updateImage:(CGImageRef)newImage {
    CGImageRef oldImage = screenImage;
    screenImage = CGImageRetain(newImage);
    CGImageRelease(oldImage);
    [videoLayer performSelectorOnMainThread:@selector(setContents:) withObject:(__bridge id)screenImage waitUntilDone:NO];
}

@end
