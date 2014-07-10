//
//  Dimmer.h
//  Dim
//
//  Created by inket on 09/07/2014.
//  Copyright (c) 2014 inket. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Safari.h"
#import "WebKit.h"

#import "Displays.h"

#define kSafariBundleIdentifier @"com.apple.Safari"
#define kSafariPluginBundleIdentifier @"com.apple.WebKit.PluginProcess"
#define kSafari8PluginBundleIdentifier @"com.apple.WebKit.Plugin.64"

#define kWebKitBundleIdentifier @"org.webkit.nightly.WebKit"

#define kFirefoxPluginBundleIdentifier @"org.mozilla.plugincontainer"

@interface Dimmer : NSObject

@property (assign) float oldBrightnessValue;
@property (assign) BOOL dimmedAutomatically;

+ (instancetype)sharedInstance;
- (void)dimOrRestoreIfNeeded;

- (void)dimCurrentDisplay;
- (void)restoreCurrentDisplay;
- (void)toggleDimCurrentDisplay;

@end