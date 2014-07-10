//
//  LoginItem.h
//  Dim
//
//  Created by inket on 01/01/14.
//  Copyright (c) 2014 inket. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LoginItem : NSObject

@property (assign, nonatomic) BOOL launchOnLogin;

+ (void)addLoginItem:(BOOL)hideOnLaunch;
+ (void)removeLoginItem;
+ (BOOL)loginItemExists;

@end
