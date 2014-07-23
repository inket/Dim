//
//  Dimmer.m
//  Dim
//
//  Created by inket on 09/07/2014.
//  Copyright (c) 2014 inket. All rights reserved.
//

#import "Dimmer.h"

@implementation Dimmer

+ (instancetype)sharedInstance {
    static Dimmer* dimmer = nil;
    
    if (!dimmer)
    {
        dimmer = [[Dimmer alloc] init];
    }
    
    return dimmer;
}

#pragma mark - Determining whether a dimming/restore is needed

+ (pid_t)safariPID {
    NSRunningApplication* frontmostApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    
    if ([kSafariBundleIdentifier isEqualToString:[frontmostApp bundleIdentifier]])
    {
        return [frontmostApp processIdentifier];
    }

    return 0;
}

+ (pid_t)webkitPID {
    NSRunningApplication* frontmostApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    
    if ([kWebKitBundleIdentifier isEqualToString:[frontmostApp bundleIdentifier]])
    {
        return [frontmostApp processIdentifier];
    }

    return 0;
}

+ (BOOL)foregroundAppIsBrowserPlugin {
    NSString* foregroundAppBundleIdentifier = [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier];

    if ([kSafari8PluginBundleIdentifier isEqualToString:foregroundAppBundleIdentifier]
        || [kSafariPluginBundleIdentifier isEqualToString:foregroundAppBundleIdentifier]
        || [kFirefoxPluginBundleIdentifier isEqualToString:foregroundAppBundleIdentifier])
    {
        return YES;
    }
    
    return NO;
}

+ (BOOL)foregroundAppIsBrowser {
    NSString* foregroundAppBundleIdentifier = [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier];

    if ([kSafariBundleIdentifier isEqualToString:foregroundAppBundleIdentifier]
        || [kWebKitBundleIdentifier isEqualToString:foregroundAppBundleIdentifier])
    {
        return YES;
    }
    
    return NO;
}

+ (BOOL)fullscreenVideoInForeground {
    @autoreleasepool {
        pid_t pid = [Dimmer safariPID];
        SafariApplication* safari = pid == 0 ? nil : [SBApplication applicationWithProcessIdentifier:pid];
        BOOL isPlayingVideoInFullscreen = NO;
        
        @try {
            if (safari && [safari isKindOfClass:[NSClassFromString(@"SafariApplication") class]])
            {
                BOOL safari8 = [[safari version] hasPrefix:@"8"];
                
                for (SafariWindow* window in [safari windows]) {
//                    NSLog(@"%@", window.properties);
                    
                    BOOL zoomed = [window zoomed];
                    BOOL untitled = ![window titled];
                    BOOL visible = [window visible];
                    BOOL permanent = ![window closeable];
                    BOOL unnamed = [window name] == nil || [[window name] isEqualToString:@""];
                    
                    BOOL safariWindowIsFullscreenPlayer = NO;
                    
                    if (safari8)
                    {
                        safariWindowIsFullscreenPlayer = !zoomed && untitled && visible && permanent;
                    }
                    else
                    {
                        safariWindowIsFullscreenPlayer = zoomed && untitled && visible && permanent && unnamed;
                    }
                    
                    if (safariWindowIsFullscreenPlayer)
                    {
                        // Make sure it's not on the screen that we're going to dim
                        NSNumber* mainScreenID = [[[NSScreen mainScreen] deviceDescription] objectForKey:@"NSScreenNumber"];
                        if (![mainScreenID isEqualToNumber:[Displays sharedInstance].currentDisplay])
                        {
                            isPlayingVideoInFullscreen = YES;
                            break;
                        }
                    }
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Safari didn't respond to scripting, causing an exception.");
        }
        
        if (!isPlayingVideoInFullscreen)
        {
            pid_t pid = [Dimmer webkitPID];
            WebKitApplication* webkit = pid == 0 ? nil : [SBApplication applicationWithProcessIdentifier:pid];
            
            @try {
                if (webkit && [webkit isKindOfClass:[NSClassFromString(@"WebKitApplication") class]])
                {
                    for (WebKitWindow* window in [webkit windows]) {
                        BOOL zoomed = [window zoomed];
                        BOOL untitled = ![window titled];
                        BOOL visible = [window visible];
                        BOOL permanent = ![window closeable];
                        BOOL unnamed = [[window name] isEqualToString:@""];
                        
                        if (zoomed && untitled && visible && permanent && unnamed)
                        {
                            // Make sure it's not on the screen that we're going to dim
                            NSNumber* mainScreenID = [[[NSScreen mainScreen] deviceDescription] objectForKey:@"NSScreenNumber"];
                            if (![mainScreenID isEqualToNumber:[Displays sharedInstance].currentDisplay])
                            {
                                isPlayingVideoInFullscreen = YES;
                                break;
                            }
                        }
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"WebKit didn't respond to scripting, causing an exception.");
            }
        }
        
        
        return isPlayingVideoInFullscreen;
    }
}

- (void)dimOrRestoreIfNeeded {
    BOOL browserPlugin = [Dimmer foregroundAppIsBrowserPlugin];
    BOOL fullscreenVideoInBrowser = [Dimmer foregroundAppIsBrowser] && [Dimmer fullscreenVideoInForeground];
    
    if (browserPlugin || fullscreenVideoInBrowser)
    {
        [self autoDim];
    }
    else
    {
        [self autoRestore];
    }
}

- (void)autoDim {
    // Make sure the screen that we're going to dim isn't active
    NSNumber* mainScreenID = [[[NSScreen mainScreen] deviceDescription] objectForKey:@"NSScreenNumber"];
    NSNumber* currentDisplay = [Displays sharedInstance].currentDisplay;
    
    if (![mainScreenID isEqualToNumber:currentDisplay] && [[Displays displays] count] > 1)
    {
        if ([Displays getBrightness:currentDisplay] > 0 && !self.dimmedAutomatically)
        {
            self.dimmedAutomatically = YES;
            [self dimCurrentDisplay];
        }
    }
}

- (void)autoRestore {
    if (self.dimmedAutomatically)
    {
        [self restoreCurrentDisplay];
    }
}

#pragma mark - Dim/Restore/Toggle

- (void)dimCurrentDisplay {
    NSNumber* currentDisplay = [Displays sharedInstance].currentDisplay;
    
    self.oldBrightnessValue = [Displays getBrightness:currentDisplay];
    [Displays setBrightness:0.0 display:currentDisplay];
}

- (void)restoreCurrentDisplay {
    NSNumber* currentDisplay = [Displays sharedInstance].currentDisplay;

    [Displays setBrightness:self.oldBrightnessValue display:currentDisplay];
    self.dimmedAutomatically = NO;
}

- (void)toggleDimCurrentDisplay {
    NSNumber* currentDisplay = [Displays sharedInstance].currentDisplay;

    self.dimmedAutomatically = NO;
    
    if ([Displays getBrightness:currentDisplay] == 0.0)
        [self restoreCurrentDisplay];
    else
        [self dimCurrentDisplay];
}

@end