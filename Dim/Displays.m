//
//  Displays.m
//  Dim
//
//  Created by inket on 09/07/2014.
//  Copyright (c) 2014 inket. All rights reserved.
//

#import "Displays.h"
#import "AppDelegate.h"

const int kMaxDisplays = 16;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);

@implementation Displays

void displayReconfigurationCallback(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void *userInfo)
{
    [[Displays sharedInstance] determineCurrentDisplay];
    [(AppDelegate*)[[NSApplication sharedApplication] delegate] reconfigureApp];
}

- (id)init {
    self = [super init];
    
    if (self)
    {
        // Listen to display changes
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, NULL);
        [self determineCurrentDisplay];
    }
    
    return self;
}

+ (instancetype)sharedInstance {
    static Displays* instance = nil;
    if (!instance)
    {
        instance = [[Displays alloc] init];
    }
    
    return instance;
}

- (void)determineCurrentDisplay {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray* configurableDisplays = [Displays configurableDisplays];
    
    if ([configurableDisplays count] == 1)
    {
        self.currentDisplay = configurableDisplays[0];
    }
    else if ([configurableDisplays count] > 1)
    {
        NSNumber* currentDisplay = [userDefaults objectForKey:@"currentDisplay"];
        if (currentDisplay && [configurableDisplays containsObject:currentDisplay])
        {
            self.currentDisplay = currentDisplay;
        }
        else
        {
            self.currentDisplay = configurableDisplays[0];
        }
    }
    
    if (self.currentDisplay)
    {
        // Don't overwrite setting so when the user has a configurable display unplugged his setting won't get lost
        if ([userDefaults objectForKey:@"currentDisplay"] == nil)
        {
            [userDefaults setObject:self.currentDisplay forKey:@"currentDisplay"];
            [userDefaults synchronize];
        }
    }
}

#pragma mark - Detecting connected displays

+ (NSArray*)displays {
    CGDirectDisplayID display[kMaxDisplays];
    CGDisplayCount numDisplays;
    CGDisplayErr error = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
    
    if (error != CGDisplayNoErr)
    {
        NSLog(@"Couldn't get display list. %d", error);
        return @[];
    }
    
    NSMutableArray* displays = [NSMutableArray array];
    
    for (CGDisplayCount i = 0; i < numDisplays; ++i) {
        CGDirectDisplayID displayID = display[i];
        if (![Displays validDisplay:displayID]) continue;
        
        [displays addObject:@(displayID)];
    }
    
    return displays;
}

+ (NSArray*)configurableDisplays {
    CGDirectDisplayID display[kMaxDisplays];
    CGDisplayCount numDisplays;
    CGDisplayErr error = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
    
    if (error != CGDisplayNoErr)
    {
        NSLog(@"Couldn't get display list. %d", error);
        return @[];
    }
    
    NSMutableArray* configurableDisplays = [NSMutableArray array];
    
    for (CGDisplayCount i = 0; i < numDisplays; ++i) {
        float currentBrightness;
        
        CGDirectDisplayID displayID = display[i];
        if (![Displays validDisplay:displayID]) continue;
        
        io_service_t service = CGDisplayIOServicePort(displayID);
        if (IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness, &currentBrightness) == kIOReturnSuccess)
            [configurableDisplays addObject:@(displayID)];
    }
    
    return configurableDisplays;
}

#pragma mark - Getting Display Info

+ (BOOL)validDisplay:(CGDirectDisplayID)displayID {
    CGDisplayModeRef originalMode = CGDisplayCopyDisplayMode(displayID);
    BOOL valid = originalMode != NULL;
    
    CGDisplayModeRelease(originalMode);
    return valid;
}

+ (NSString*)displayName:(NSNumber*)displayID {
    NSDictionary *deviceInfo = (__bridge NSDictionary *)(IODisplayCreateInfoDictionary(CGDisplayIOServicePort([displayID unsignedIntValue]), kIODisplayOnlyPreferredName));
    NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    CFRelease((__bridge CFTypeRef)(deviceInfo));
    
    NSString *screenName = nil;
    if ([localizedNames count] > 0) {
        screenName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    }
    
    return screenName;
}

#pragma mark - Controlling Brightness

+ (float)getBrightness:(NSNumber*)targetDisplayID {
    CGDirectDisplayID displayID = [targetDisplayID unsignedIntValue];
    if (![Displays validDisplay:displayID]) return -1;
    
    io_service_t service = CGDisplayIOServicePort(displayID);
    float currentBrightness;
    if (IODisplayGetFloatParameter(service, kNilOptions, kDisplayBrightness, &currentBrightness) == kIOReturnSuccess)
        return currentBrightness;
    else
        return -1;
}

+ (BOOL)setBrightness:(float)newValue display:(NSNumber*)targetDisplayID {
    CGDirectDisplayID displayID = [targetDisplayID unsignedIntValue];
    if (![Displays validDisplay:displayID]) return NO;
    
    io_service_t service = CGDisplayIOServicePort(displayID);
    if (IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness, newValue) == kIOReturnSuccess)
        return YES;
    else
        return NO;
}

@end