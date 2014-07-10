//
//  AppDelegate.m
//  Dim
//
//  Created by inket on 9/9/13.
//  Copyright (c) 2013 inket. All rights reserved.
//

#import "AppDelegate.h"
#import <IOKit/graphics/IOGraphicsLib.h>

@implementation AppDelegate

#pragma mark - AutoDim/Restore triggers

- (void)spaceChanged:(NSNotification*)notification {
    if ([[Displays displays] count] == 1)
        return;
    
    [[Dimmer sharedInstance] dimOrRestoreIfNeeded];
}

- (void)appActivated:(NSNotification*)note {
    if ([[Displays displays] count] == 1)
        return;
    
    [[Dimmer sharedInstance] dimOrRestoreIfNeeded];
}

#pragma mark - Dim/Restore actions

- (IBAction)dim:(id)sender {
    [self.dimmer dimCurrentDisplay];
}

- (IBAction)restore:(id)sender {
    [self.dimmer restoreCurrentDisplay];
}

- (IBAction)toggleDim:(id)sender {
    [self.dimmer toggleDimCurrentDisplay];
}

#pragma mark - Configuring the app

#define startObserving(xsel, xname) ([[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:xsel name:xname object:nil])
#define stopObserving(x) ([[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self name:x object:nil])

- (void)reconfigureApp {
    [self updateDisplaysMenu];
    
    stopObserving(NSWorkspaceActiveSpaceDidChangeNotification);
    stopObserving(@"NSWorkspaceActiveDisplayDidChangeNotification");
    stopObserving(NSWorkspaceDidActivateApplicationNotification);
    
    if ([[[[self displayList] menu] itemArray] count] > 1 && self.autoDimSetting)
    {
        startObserving(@selector(spaceChanged:), NSWorkspaceActiveSpaceDidChangeNotification);
        startObserving(@selector(spaceChanged:), @"NSWorkspaceActiveDisplayDidChangeNotification");
        startObserving(@selector(appActivated:), NSWorkspaceDidActivateApplicationNotification);
    }
}

- (void)updateDisplaysMenu {
    NSMenu* menu = [[NSMenu alloc] init];
    [menu setAutoenablesItems:NO];
    
    BOOL atLeastOneIsConfigurable = NO;
    NSArray* displays = [Displays displays];
    
    for (NSNumber* displayID in displays) {
        NSString* displayName = [Displays displayName:displayID];
        if (!displayName) displayName = @"Untitled";
        
        BOOL configurable = ([Displays getBrightness:displayID] > -1);
        atLeastOneIsConfigurable = atLeastOneIsConfigurable || configurable;
        
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:displayName action:@selector(changeCurrentDisplay:) keyEquivalent:@""];
        [item setEnabled:configurable];
        [item setTag:[displayID integerValue]];
        
        [menu addItem:item];
    }
    
    [_displayList setMenu:menu];
    [_displayList selectItemWithTag:[self.displaysController.currentDisplay integerValue]];
    [_displayList setEnabled:atLeastOneIsConfigurable];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.displaysController = [Displays sharedInstance];
    self.dimmer = [Dimmer sharedInstance];
    [self reconfigureApp];
    
    // Quit if no brightness-configurable displays are present
    if ([[Displays configurableDisplays] count] == 0)
    {
        [[NSAlert alertWithMessageText:@"No configurable displays" defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The displays you're using do not have configurable brightness."] runModal];
        [NSApp terminate:nil];
    }
    
    // Prep the shortcut recorder and register the hotkey
    [_shortcutRecorderControl bind:NSValueBinding
                           toObject:[NSUserDefaultsController sharedUserDefaultsController]
                        withKeyPath:@"values.shortcut"
                            options:nil];
    [_shortcutRecorderControl setDelegate:(id<SRRecorderControlDelegate>)self];
    [self resetShortcut];
    
    // Add the menubar item
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:24];
    [_statusItem setTitle:@"D"];
    [_statusItem setMenu:_statusMenu];
    [_statusItem setHighlightMode:YES];
}

#pragma mark - Preferences

- (void)awakeFromNib {
    [self setAutoDimSetting:[[NSUserDefaults standardUserDefaults] boolForKey:@"autoDim"]];
    [_autoDimCheckbox setState:_autoDimSetting ? NSOnState : NSOffState];
    [_autoDimMenuItem setState:_autoDimSetting ? NSOnState : NSOffState];
}

- (IBAction)openPreferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [_window makeKeyAndOrderFront:nil];
    
    [self updateDisplaysMenu];
}

- (IBAction)changeCurrentDisplay:(id)sender {
    NSNumber* displayID = @([sender tag]);
    
    NSArray* configurableDisplays = [Displays configurableDisplays];
    if ([configurableDisplays containsObject:displayID])
    {
        self.displaysController.currentDisplay = displayID;
        
        float currentDisplayBrightness = [Displays getBrightness:displayID];
        self.dimmer.oldBrightnessValue = currentDisplayBrightness > 0 ? currentDisplayBrightness : 0.5;
        
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:self.displaysController.currentDisplay forKey:@"currentDisplay"];
        [userDefaults synchronize];
    }
    else
    {
        [self updateDisplaysMenu];
    }
}

- (IBAction)changeAutoDim:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]])
        [sender setState:![sender state]];
    
    NSUInteger state = [(NSButton*)sender state];
    
    [self setAutoDimSetting:state == NSOnState];
    [_autoDimCheckbox setState:state];
    [_autoDimMenuItem setState:state];
    
    [[NSUserDefaults standardUserDefaults] setBool:_autoDimSetting forKey:@"autoDim"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self reconfigureApp];
}


#pragma mark Setting up keyboard shortcuts

- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder {
    [self resetShortcut];
}

- (void)resetShortcut {
    NSDictionary* shortcut = [_shortcutRecorderControl objectValue];
    
    PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
    
    PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:@"shortcut"];
    [hotKeyCenter unregisterHotKey:oldHotKey];
    
    PTHotKey *newHotKey = [PTHotKey hotKeyWithIdentifier:@"shortcut" keyCombo:shortcut target:self action:@selector(toggleDim:)];
    [hotKeyCenter registerHotKey:newHotKey];
}

@end
