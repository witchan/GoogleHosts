//
//  AppDelegate.h
//  GoogleHosts
//
//  Created by WitChan on 16/8/29.
//  Copyright © 2016年 Wit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <SecurityInterface/SFAuthorizationView.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    
}

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *tipsLabel;
@property (weak) IBOutlet NSButton *updateButton;
@property (weak) IBOutlet NSButton *recoverButton;
@property (weak) IBOutlet SFAuthorizationView *authView;

- (BOOL)isUnlocked;

@end

