//
//  B2InputSettingsViewController.m
//  BasiliskII
//
//  Created by Jesús A. Álvarez on 10/04/2016.
//  Copyright © 2016 namedfork. All rights reserved.
//

#import "B2InputSettingsViewController.h"
#import "B2AppDelegate.h"

typedef enum : NSInteger {
    B2InputSectionKeyboardLayout,
    B2InputSectionMouse
} B2InputSection;

@interface B2InputSettingsViewController ()

@end

@implementation B2InputSettingsViewController
{
    NSArray *keyboardLayouts;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    keyboardLayouts = [B2AppDelegate sharedInstance].availableKeyboardLayouts;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case B2InputSectionMouse:
            return 0;
        case B2InputSectionKeyboardLayout:
            return keyboardLayouts.count;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case B2InputSectionMouse:
            return L(@"settings.input.mouse");
        case B2InputSectionKeyboardLayout:
            return L(@"settings.input.keyboard.layout.header");
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case B2InputSectionKeyboardLayout:
            return L(@"settings.input.keyboard.layout.footer");
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basic" forIndexPath:indexPath];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (indexPath.section == B2InputSectionKeyboardLayout) {
        NSString *layout = keyboardLayouts[indexPath.row];
        cell.textLabel.text = layout.lastPathComponent.stringByDeletingPathExtension;
        BOOL selected = [[defaults stringForKey:@"keyboardLayout"] isEqualToString:layout.lastPathComponent];
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.section == B2InputSectionKeyboardLayout) {
        NSString *layout = keyboardLayouts[indexPath.row];
        [defaults setValue:layout.lastPathComponent forKey:@"keyboardLayout"];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
