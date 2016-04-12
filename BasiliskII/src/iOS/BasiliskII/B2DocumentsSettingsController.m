//
//  B2DocumentsSettingsController.m
//  BasiliskII
//
//  Created by Jesús A. Álvarez on 28/03/2016.
//  Copyright © 2016 namedfork. All rights reserved.
//

#import "B2DocumentsSettingsController.h"
#import "B2AppDelegate.h"
#import "B2FileChooser.h"
#import "B2DesktopDatabase.h"

@interface B2DocumentsSettingsController () <B2FileChooserDelegate>

@end

@implementation B2DocumentsSettingsController
{
    B2FileChooser *baseFileChooser;
    NSString *baseFilePath;
    B2DesktopDatabase *desktop;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    baseFilePath = [B2AppDelegate sharedInstance].documentsPath;
    baseFileChooser = [[B2FileChooser alloc] initWithStyle:UITableViewStylePlain];
    baseFileChooser.path = baseFilePath;
    baseFileChooser.delegate = self;
    self.viewControllers = @[baseFileChooser];
    [self loadDesktopFile];
}

#pragma mark - Desktop

- (void)loadDesktopFile {
    NSString *desktopPath = [baseFilePath stringByAppendingPathComponent:@"Desktop"];
    desktop = [[B2DesktopDatabase alloc] initWithDesktopFile:desktopPath];
    desktop.delegate = [B2AppDelegate sharedInstance];
    desktop.imageScale = 1.5;
}

#pragma mark - File Chooser Delegate

- (void)fileChooserWillRefresh:(B2FileChooser *)fileChooser {
    [self loadDesktopFile];
    [fileChooser.tableView reloadData];
}

- (void)fileChooser:(B2FileChooser *)fileChooser didChooseDirectory:(NSString *)path {
    B2FileChooser *newFileChooser = [[B2FileChooser alloc] initWithStyle:UITableViewStylePlain];
    newFileChooser.path = path;
    newFileChooser.delegate = self;
    [self pushViewController:newFileChooser animated:YES];
}

- (BOOL)fileChooser:(B2FileChooser *)fileChooser canDeletePath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager isDeletableFileAtPath:path];
}

- (UIImage*)fileChooser:(B2FileChooser *)fileChooser iconForFile:(NSString *)path isDirectory:(BOOL)isDirectory {
    UIImage *icon = [desktop iconForFile:path];
    if (icon == nil) {
        icon = [UIImage imageNamed:isDirectory ? @"DefaultFolder" : @"DefaultDocument"];
    }
    return icon;
}

@end
