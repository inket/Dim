//
//  AppDelegate.h
//  Dim
//
//  Created by inket on 9/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <ShortcutRecorder/PTHotKey+ShortcutRecorder.h>
#import <ShortcutRecorder/PTHotKey+ShortcutRecorder.h>
#import <ShortcutRecorder/PTHotKeyCenter.h>
#import <ShortcutRecorder/PTKeyCodeTranslator.h>
#import <ShortcutRecorder/PTKeyCombo.h>
#import "Displays.h"
#import "Dimmer.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSPopUpButton* displayList;
@property (assign) IBOutlet SRRecorderControl* shortcutRecorderControl;
@property (assign) IBOutlet NSMenu *statusMenu;
@property (assign) IBOutlet NSButton* autoDimCheckbox;
@property (assign) IBOutlet NSMenuItem* autoDimMenuItem;
@property (assign) BOOL autoDimSetting;

@property (strong) NSStatusItem* statusItem;

@property (strong) Displays* displaysController;
@property (strong) Dimmer* dimmer;

- (void)reconfigureApp;

@end
