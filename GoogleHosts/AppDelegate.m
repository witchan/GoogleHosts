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
    
    NSString *order = [NSString stringWithFormat:@"echo '%@' >~/../../private/etc/hosts", hosts];
    
    NSArray *args = @[@"-c", order, @"killall -HUP mDNSResponder"];
    
    const char **argv = (const char **)malloc(sizeof(char *) * [args count] + 1);
    int argvIndex = 0;
    for (NSString *string in args) {
        argv[argvIndex] = [string UTF8String];
        argvIndex++;
    }
    argv[argvIndex] = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

    OSErr processError = AuthorizationExecuteWithPrivileges([[self.authView authorization] authorizationRef], [@"/bin/sh" UTF8String],
                                                            kAuthorizationFlagDefaults, (char *const *)argv, nil);
#pragma clang diagnostic pop
    free(argv);
    
    if (processError == errAuthorizationSuccess) {
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


#pragma mark - Custom Accessors

- (NSString *)hostsPath {
    if (_hostsPath == nil) {
        _hostsPath = @"/private/etc/hosts";
    }
    return _hostsPath;
}

- (SFAuthorizationView *)authView {
    if (_authView == nil) {
        _authView = [[SFAuthorizationView alloc] init];
        AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
        AuthorizationRights rights = {1, &items};
        [_authView setAuthorizationRights:&rights];
        [_authView updateStatus:nil];
    }
    return _authView;
}

@end
