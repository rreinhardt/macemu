//
//  B2ViewController.m
//  BasiliskII
//
//  Created by Jesús A. Álvarez on 08/03/2014.
//  Copyright (c) 2014 namedfork. All rights reserved.
//

#import "B2ViewController.h"
#import "B2AppDelegate.h"
#import "KBKeyboardView.h"
#import "KBKeyboardLayout.h"

@implementation B2ViewController
{
    KBKeyboardView *keyboardView;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)showSettings:(id)sender {
    [self performSegueWithIdentifier:@"settings" sender:sender];
}

- (void)unwindToMainScreen:(UIStoryboardSegue*)segue {
    [[B2AppDelegate sharedInstance] startEmulator];
    [self performSelector:@selector(showKeyboard:) withObject:self afterDelay:1.0];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [keyboardView removeFromSuperview];
    keyboardView = nil;
    [self performSelector:@selector(showKeyboard:) withObject:self afterDelay:1.0];
}

- (void)showKeyboard:(id)sender {
    [self loadKeyboardView];
    if (keyboardView.layout == nil) {
        [keyboardView removeFromSuperview];
    } else {
        [self.view addSubview:keyboardView];
        keyboardView.frame = CGRectOffset(keyboardView.frame, 0, self.view.bounds.size.height - keyboardView.frame.size.height);
    }
}

- (void)loadKeyboardView {
    if (keyboardView == nil) {
        keyboardView = [[KBKeyboardView alloc] initWithFrame:self.view.frame];
        keyboardView.layout = [self keyboardLayout];
        keyboardView.delegate = [B2AppDelegate sharedInstance];
    }
}

- (KBKeyboardLayout*)keyboardLayout {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *layoutName = [defaults stringForKey:@"keyboardLayout"];
    NSString *layoutPath = [[NSBundle mainBundle] pathForResource:layoutName ofType:nil inDirectory:@"Keyboard Layouts"];
    if (layoutPath == nil) {
        NSLog(@"Layout not found: %@", layoutPath);
    }
    return layoutPath ? [[KBKeyboardLayout alloc] initWithContentsOfFile:layoutPath] : nil;
}

@end
