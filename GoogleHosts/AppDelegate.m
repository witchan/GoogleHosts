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
@property (assign, nonatomic) AuthorizationRef authorizationRef;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [self authorizationRef];
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
    
    OSErr processError = AuthorizationExecuteWithPrivileges(self.authorizationRef, [@"/bin/sh" UTF8String],
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

- (AuthorizationRef) authorizationRef {
    if (_authorizationRef == nil) {
        
        OSStatus myStatus;
        
        myStatus = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment,
                                        kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed , &_authorizationRef);
        AuthorizationItem myItems[1];
        
        myItems[0].name = kAuthorizationRightExecute;
        myItems[0].valueLength = 0;
        myItems[0].value = NULL;
        myItems[0].flags = 0;
        
        AuthorizationRights myRights;
        myRights.count = sizeof (myItems) / sizeof (myItems[0]);
        myRights.items = myItems;
        
        AuthorizationFlags myFlags;
        myFlags = kAuthorizationFlagDefaults |
        kAuthorizationFlagInteractionAllowed |
        kAuthorizationFlagExtendRights;
        
        myStatus = AuthorizationCopyRights (_authorizationRef, &myRights,
                                            kAuthorizationEmptyEnvironment, myFlags, NULL);
        
        if (myStatus !=errAuthorizationSuccess)
        {
            _authorizationRef = nil;
        }
    }
    return _authorizationRef;
}


@end
