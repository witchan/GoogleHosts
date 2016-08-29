//
//  AppDelegate.m
//  GoogleHosts
//
//  Created by WitChan on 16/8/29.
//  Copyright © 2016年 Wit. All rights reserved.
//

#import "AppDelegate.h"

static NSString *kOldHostsKey = @"oldHostsKey";

@interface AppDelegate ()

@property (copy, nonatomic) NSString *hostsPath;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &items};
    [self.authView setAuthorizationRights:&rights];
    self.authView.delegate = self;
    [self.authView updateStatus:nil];
    
    [self.updateButton setEnabled:[self isUnlocked]];
    [self.recoverButton setEnabled:[self isUnlocked]];
}


#pragma mark - Private

- (void)hostsBackups {
    
    NSString *oldHosts = [NSString stringWithContentsOfFile:self.hostsPath encoding:NSUTF8StringEncoding error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:oldHosts forKey:kOldHostsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)writeHosts:(NSString *)hosts {
    
    if (hosts.length <= 0) {
        self.tipsLabel.stringValue = @"hosts为空，更新失败";
        return NO;
    }
    
    NSString *order = [NSString stringWithFormat:@"echo '%@' >/private/etc/hosts", hosts];
    
    int result = system([order UTF8String]);
    
    if (result == 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)enableButton:(BOOL)isEnable {
    self.updateButton.enabled = isEnable;
    self.recoverButton.enabled = isEnable;
}

- (BOOL)isUnlocked {
    
    return [self.authView authorizationState] == SFAuthorizationViewUnlockedState;
}


#pragma mark - IBActions

- (IBAction)updateButtonOnClicked:(id)sender {
    
    self.tipsLabel.stringValue = @"正在更新...";
    [self enableButton:NO];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self hostsBackups];
        
        NSURL *url = [NSURL URLWithString:@"https://raw.githubusercontent.com/racaljk/hosts/master/hosts"];
        NSString *hosts = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        
        BOOL isSeccess = [self writeHosts:hosts];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isSeccess) {
                self.tipsLabel.stringValue = @"更新成功";
            } else {
                self.tipsLabel.stringValue = @"更新失败";
            }
            [self enableButton:YES];
        });
    });
}

- (IBAction)recoverButtonOnClicked:(id)sender {
    NSString *lastHosts = [[NSUserDefaults standardUserDefaults] objectForKey:kOldHostsKey];
    BOOL isSeccess = [self writeHosts:lastHosts];
    if (isSeccess) {
        self.tipsLabel.stringValue = @"恢复成功";
    } else {
        self.tipsLabel.stringValue = @"恢复失败";
    }
}


#pragma mark - SFAuthorizationViewDelegate

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
    self.tipsLabel.stringValue = @"请点击更新按钮更新Google hosts";
    [self enableButton:[self isUnlocked]];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
    self.tipsLabel.stringValue = @"请先解锁";
    
    [self enableButton:[self isUnlocked]];
}


#pragma mark - Custom Accessors

- (NSString *)hostsPath {
    if (_hostsPath == nil) {
        _hostsPath = @"/private/etc/hosts";
    }
    return _hostsPath;
}

@end
