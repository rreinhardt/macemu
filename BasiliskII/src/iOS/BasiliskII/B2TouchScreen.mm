//
//  B2TouchScreen.m
//  BasiliskII
//
//  Created by Jesús A. Álvarez on 18/04/2016.
//  Copyright © 2016 namedfork. All rights reserved.
//

#import "B2TouchScreen.h"
#import "B2ScreenView.h"
#import "B2AppDelegate.h"
#include "sysdeps.h"
#include "adb.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation B2TouchScreen
{
    // when using absolute mouse mode, button events are processed before the position is updated
    NSTimeInterval mouseButtonDelay;
    CGPoint previousTouchLoc;
    NSTimeInterval previousTouchTime;
    NSTimeInterval touchTimeThreshold;
    CGFloat touchDistanceThreshold;
    NSMutableSet *currentTouches;
    #ifdef __IPHONE_13_4
    UIPointerInteraction* interaction;
    #endif
}

#ifdef __IPHONE_13_4
- (UIPointerRegion *)pointerInteraction:(UIPointerInteraction *)interaction regionForRequest:(UIPointerRegionRequest *)request defaultRegion:(UIPointerRegion *)defaultRegion  API_AVAILABLE(ios(13.4)){
    if (request != nil) {
        Point mouseLoc = [self mouseLocForCGPoint:request.location];
        // NSLog(@"Interaction: x2: %hi, y2: %hi", (short)mouseLoc.h, (short)mouseLoc.v);
        ADBMouseMoved(mouseLoc.h, mouseLoc.v);
    }
    return defaultRegion;
}

- (UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region {
    return [UIPointerStyle hiddenPointerStyle];

}
#endif

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        mouseButtonDelay = 0.05;
        touchTimeThreshold = 0.25;
        touchDistanceThreshold = 16;
        currentTouches = [NSMutableSet setWithCapacity:4];
    }
    
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.4")) {
        interaction = [[UIPointerInteraction alloc] initWithDelegate: self];
        [self addInteraction:interaction];
    }
    
    UIHoverGestureRecognizer *hover = [[UIHoverGestureRecognizer alloc] initWithTarget:self action:@selector(hover:)];
    [self addGestureRecognizer:hover];
    
    return self;
}


- (void)willMoveToSuperview:(UIView *)newSuperview {
    ADBSetRelMouseMode(false);
}

- (Point)mouseLocForCGPoint:(CGPoint)point {
    Point mouseLoc;
    CGRect screenBounds = sharedScreenView.screenBounds;
    CGSize screenSize = sharedScreenView.screenSize;
    mouseLoc.h = (point.x - screenBounds.origin.x) * (screenSize.width/screenBounds.size.width);
    mouseLoc.v = (point.y - screenBounds.origin.y) * (screenSize.height/screenBounds.size.height);
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
    [self touchesEnded:touches withEvent:event];
}

- (void)hover:(UIHoverGestureRecognizer *)pan
{
    CGPoint p = [pan locationInView:self];
    
    Point mouseLoc = [self mouseLocForCGPoint:p];
    
    ADBMouseMoved(mouseLoc.h, mouseLoc.v);
//    [[AppDelegate sharedEmulator] setMouseX:mouseLoc.h Y:mouseLoc.v];
}

//-(id)pointerInteraction:(id)p regionForRequest:(id)r defaultRegion:(id)d
//{
//    return [NSClassFromString(@"UIPointerRegion") regionWithRect:self.bounds identifier:@"Blah"];
//}
//
//-(id)pointerInteraction:(id)p styleForRegion:(int)a
//{
//    id style = [NSClassFromString(@"UIPointerStyle") hiddenPointerStyle];
//    
//    return style;
//}

@end
