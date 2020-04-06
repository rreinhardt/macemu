//
//  B2TouchScreen.h
//  BasiliskII
//
//  Created by Jesús A. Álvarez on 18/04/2016.
//  Copyright © 2016 namedfork. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __IPHONE_13_4
API_AVAILABLE(ios(13.4))
@interface B2TouchScreen : UIControl <UIPointerInteractionDelegate>
#else
@interface B2TouchScreen : UIControl <UIPointerInteractionDelegate>
#endif
@end
