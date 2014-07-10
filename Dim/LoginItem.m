//
//  LoginItem.m
//  Dim
//
//  Created by inket on 01/01/14.
//  Copyright (c) 2014 inket. All rights reserved.
//

#import "LoginItem.h"

@implementation LoginItem

- (void)awakeFromNib {
    self.launchOnLogin = [LoginItem loginItemExists];
}

- (void)setLaunchOnLogin:(BOOL)launchOnLogin {
    if (_launchOnLogin != launchOnLogin)
    {
        if (launchOnLogin && ![LoginItem loginItemExists])
            [LoginItem addLoginItem:NO];
        else if (!launchOnLogin)
            [LoginItem removeLoginItem];
    }
    
    _launchOnLogin = launchOnLogin;
}

+ (void)addLoginItem:(BOOL)hideOnLaunch {
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginItems)
    {
        NSURL* url = [[NSBundle mainBundle] bundleURL];
        NSDictionary *properties = @{@"com.apple.loginitem.HideOnLaunch": [NSNumber numberWithBool:hideOnLaunch]};
        
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
																	 kLSSharedFileListItemLast, NULL, NULL,
																	 (__bridge CFURLRef)url, (__bridge CFDictionaryRef)properties, NULL);
		if (item) CFRelease(item);
        CFRelease(loginItems);
	}
}

+ (void)removeLoginItem {
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
	NSURL* url = [[NSBundle mainBundle] bundleURL];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginItems)
    {
		UInt32 seedValue;
		NSArray* loginItemsArray = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
        
		for(int i=0 ; i<[loginItemsArray count]; i++)
        {
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray objectAtIndex:i];
            CFURLRef newUrl = (__bridge_retained CFURLRef)url;
            
			if (LSSharedFileListItemResolve(itemRef, 0, &newUrl, NULL) == noErr)
            {
				NSString * urlPath = [(__bridge NSURL*)newUrl path];
				if ([urlPath isEqualToString:appPath])
                {
                    CFRelease(newUrl);
					LSSharedFileListItemRemove(loginItems, itemRef);
                    break;
				}
			}
            
            CFRelease(newUrl);
		}
        
        CFRelease(loginItems);
	}
}

+ (BOOL)loginItemExists {
    BOOL found = NO;
    
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
	NSURL* url = [[NSBundle mainBundle] bundleURL];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginItems)
    {
		UInt32 seedValue;
		NSArray* loginItemsArray = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
                
		for(int i=0 ; i<[loginItemsArray count]; i++)
        {
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray objectAtIndex:i];
            CFURLRef newUrl = (__bridge_retained CFURLRef)url;
            
			if (LSSharedFileListItemResolve(itemRef, 0, &newUrl, NULL) == noErr)
            {
				NSString * urlPath = [(__bridge NSURL*)newUrl path];
				if ([urlPath isEqualToString:appPath])
                {
                    CFRelease(newUrl);
					found = YES;
                    break;
				}
			}
            
            CFRelease(newUrl);
		}
        
        CFRelease(loginItems);
	}
    
    return found;
}

@end
