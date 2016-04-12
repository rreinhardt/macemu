//
//  B2ViewController.h
//  BasiliskII
//
//  Created by Jesús A. Álvarez on 08/03/2014.
//  Copyright (c) 2014 namedfork. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface B2ViewController : UIViewController

- (IBAction)showSettings:(id)sender;
- (IBAction)unwindToMainScreen:(UIStoryboardSegue*)segue;

@end

NS_ASSUME_NONNULL_END