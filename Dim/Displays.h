//
//  Displays.h
//  Dim
//
//  Created by inket on 09/07/2014.
//  Copyright (c) 2014 inket. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Displays : NSObject

@property (strong) NSNumber* currentDisplay;

+ (instancetype)sharedInstance;

+ (NSArray*)displays;
+ (NSArray*)configurableDisplays;

+ (BOOL)validDisplay:(CGDirectDisplayID)displayID;
+ (NSString*)displayName:(NSNumber*)displayID;

+ (float)getBrightness:(NSNumber*)targetDisplayID;
+ (BOOL)setBrightness:(float)newValue display:(NSNumber*)targetDisplayID;

@end