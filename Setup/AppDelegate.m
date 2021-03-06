//
//  AppDelegate.m
//  GrabBox
//
//  Created by Jørgen Tjernø on 5/15/13.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import "AppDelegate.h"

// If this fails, then you need to copy DropboxAPIKey_Private.inl.dist to DropboxAPIKey_Private.inl, and edit it.
#import "../Common/DropboxAPIKey_Private.inl"

#import <DropboxOSX/DropboxOSX.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DBSession *session = [[DBSession alloc] initWithAppKey:dropboxConsumerKey
                                                 appSecret:dropboxConsumerSecret
                                                      root:kDBRootAppFolder];
    [DBSession setSharedSession:session];
    
    self.step = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(authHelperStateChangedNotification:)
                                                 name:DBAuthHelperOSXStateChangedNotification
                                               object:[DBAuthHelperOSX sharedHelper]];
    [self updateLinkButton];
    
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self
            andSelector:@selector(getUrl:withReplyEvent:)
          forEventClass:kInternetEventClass
             andEventID:kAEGetURL];

    [self advanceToAppropriateStepAndSkipTutorial:YES];
}

- (void)advanceToAppropriateStepAndSkipTutorial:(BOOL)skipTutorial
{
    if (self.step == 0 && ![[DBSession sharedSession] isLinked])
    {
        return;
    }
    else if (true) // TODO: Check for sandbox access to screenshot location.
    {
        if (self.step != 1)
        {
            self.step = 1;
            self.step2.image = [NSImage imageNamed:@"progressbutton_active"];
        }
    }
    else if (!skipTutorial)
    {
        if (self.step != 2)
        {
            self.step = 2;
            self.step2.image = [NSImage imageNamed:@"progressbutton_active"];
            self.step3.image = [NSImage imageNamed:@"progressbutton_active"];
            self.contentBox.contentView = /* TODO: VIEW. */ nil;
        }
    }
    else
    {
        // TODO: Launch app.
    }
}

- (IBAction)didPressLinkDropbox:(id)sender {
    if ([[DBSession sharedSession] isLinked]) {
        // The link button turns into an unlink button when you're linked
        [[DBSession sharedSession] unlinkAll];
        [self updateLinkButton];
    } else {
        [[DBAuthHelperOSX sharedHelper] authenticate];
        [self updateLinkButton];        
    }
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    // This gets called when the user clicks Show "App name". You don't need to do anything for Dropbox here
}

- (void)authHelperStateChangedNotification:(NSNotification *)notification {
	[self updateLinkButton];
    [self advanceToAppropriateStepAndSkipTutorial:NO];
}

- (void)updateLinkButton
{
	if (![[DBSession sharedSession] isLinked])
    {
        if ([[DBAuthHelperOSX sharedHelper] isLoading])
        {
            self.linkButton.enabled = NO;
            [self.progressIndicator startAnimation:self];
        }
        else
        {
            self.linkButton.enabled = YES;
            [self.progressIndicator stopAnimation:self];
        }
	}
    else
    {
        self.linkButton.enabled = NO;
        [self.progressIndicator stopAnimation:self];
    }
}

@end
