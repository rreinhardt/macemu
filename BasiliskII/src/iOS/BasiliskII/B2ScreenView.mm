//
//  B2ScreenView.m
//  BasiliskII
//
//  Created by Jesús A. Álvarez on 09/03/2014.
//  Copyright (c) 2014 namedfork. All rights reserved.
//

#import "B2ScreenView.h"
#include "sysdeps.h"
#include "adb.h"
#include "video.h"
#import "B2AppDelegate.h"

B2ScreenView *sharedScreenView = nil;

@implementation B2ScreenView
{
    // when using absolute mouse mode, button events are processed before the position is updated
    NSTimeInterval mouseButtonDelay;
    CGPoint previousTouchLoc;
    NSTimeInterval previousTouchTime;
    NSTimeInterval touchTimeThreshold;
    CGFloat touchDistanceThreshold;
    NSMutableSet *currentTouches;
    
    CGImageRef screenImage;
    CGRect screenBounds;
}

- (void)awakeFromNib {
    ADBSetRelMouseMode(false);
    sharedScreenView = self;
    mouseButtonDelay = 0.05;
    touchTimeThreshold = 0.25;
    touchDistanceThreshold = 16;
    currentTouches = [NSMutableSet setWithCapacity:4];
    [self initVideoModes];
    ADBKeyDown(0); ADBKeyUp(0);
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
    [self setScreenSize:_screenSize];
    [self setNeedsDisplay];
}

- (void)setScreenSize:(CGSize)screenSize {
    _screenSize = screenSize;
    CGRect viewBounds = self.bounds;
    CGFloat screenScale = MAX(screenSize.width / viewBounds.size.width, screenSize.height / viewBounds.size.height);
    screenBounds = CGRectMake(0, 0, screenSize.width / screenScale, screenSize.height / screenScale);
    screenBounds.origin.x = (viewBounds.size.width - screenBounds.size.width)/2;
    screenBounds = CGRectIntegral(screenBounds);
}

- (void)drawRect:(CGRect)rect {
    CGImageRef imageRef = CGImageRetain(screenImage);
    if (imageRef) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(ctx, 0, screenBounds.size.height);
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextDrawImage(ctx, screenBounds, imageRef);
        CGImageRelease(imageRef);
    }
}

- (void)updateImage:(CGImageRef)newImage {
    CGImageRef oldImage = screenImage;
    screenImage = CGImageRetain(newImage);
    CGImageRelease(oldImage);
    [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

- (Point)mouseLocForCGPoint:(CGPoint)point {
    Point mouseLoc;
    mouseLoc.h = (point.x - screenBounds.origin.x) * (_screenSize.width/screenBounds.size.width);
    mouseLoc.v = (point.y - screenBounds.origin.y) * (_screenSize.height/screenBounds.size.height);
    return mouseLoc;
}

- (void)mouseDown {
    ADBMouseDown(0);
}

- (void)mouseUp {
    ADBMouseUp(0);
}

- (CGPoint)effectiveTouchPointForEvent:(UIEvent *)event {
    CGPoint touchLoc = [[event touchesForView:self].anyObject locationInView:self];
    if (event.timestamp - previousTouchTime < touchTimeThreshold &&
        fabs(previousTouchLoc.x - touchLoc.x) < touchDistanceThreshold &&
        fabs(previousTouchLoc.y - touchLoc.y) < touchDistanceThreshold)
        return previousTouchLoc;
    previousTouchLoc = touchLoc;
    previousTouchTime = event.timestamp;
    return touchLoc;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [currentTouches unionSet:touches];
    if (![B2AppDelegate sharedInstance].emulatorRunning) return;
    CGPoint touchLoc = [self effectiveTouchPointForEvent:event];
    Point mouseLoc = [self mouseLocForCGPoint:touchLoc];
    ADBMouseMoved(mouseLoc.h, mouseLoc.v);
    [self performSelector:@selector(mouseDown) withObject:nil afterDelay:mouseButtonDelay];
    previousTouchLoc = touchLoc;
    previousTouchTime = event.timestamp;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (![B2AppDelegate sharedInstance].emulatorRunning) return;
    CGPoint touchLoc = [self effectiveTouchPointForEvent:event];
    Point mouseLoc = [self mouseLocForCGPoint:touchLoc];
    ADBMouseMoved(mouseLoc.h, mouseLoc.v);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [currentTouches minusSet:touches];
    if (![B2AppDelegate sharedInstance].emulatorRunning) return;
    if (currentTouches.count > 0) return;
    CGPoint touchLoc = [self effectiveTouchPointForEvent:event];
    Point mouseLoc = [self mouseLocForCGPoint:touchLoc];
    ADBMouseMoved(mouseLoc.h, mouseLoc.v);
    [self performSelector:@selector(mouseUp) withObject:nil afterDelay:mouseButtonDelay];
    previousTouchLoc = touchLoc;
    previousTouchTime = event.timestamp;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [currentTouches minusSet:touches];
}

@end
