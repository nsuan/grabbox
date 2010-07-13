//
//  InitialStartup.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "InitialStartup.h"

@interface InitialStartup ()
@property (nonatomic, retain) NSTimer *timer;
@end

@implementation InitialStartup

@synthesize window;
@synthesize dropboxId;
@synthesize appDelegate;
@synthesize timer;
@synthesize preferences;
@synthesize autoLaunch;

- (void) awakeFromNib
{
    [self setTimer:nil];
    lastIdFromUrl = 0;
}

- (void) dealloc
{
    [self setTimer:nil];
    [super dealloc];
}

- (BOOL)windowShouldClose:(id)sender
{
    NSString* enteredValue = [dropboxId stringValue];
    int intValue = [enteredValue integerValue];
    NSString* stringRepresentation = [NSString stringWithFormat:@"%d", intValue];
    NSAlert* alert = nil;

    if (!intValue)
    {
        alert = [NSAlert alertWithMessageText:nil
                                defaultButton:nil
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@"You must enter a valid Dropbox ID to continue!"];
    }
    else if (![enteredValue isEqualToString:stringRepresentation])
    {
        alert = [NSAlert alertWithMessageText:nil
                                defaultButton:nil
                              alternateButton:nil
                                  otherButton:nil
                    informativeTextWithFormat:@"The entered Dropbox ID contains invalid characters!"];

    }

    if (!alert)
    {
        NSLog(@"Should close: YES.");
        [appDelegate setDropboxId:intValue];
        [appDelegate startMonitoring];
        [preferences setEnabled:YES];
        return YES;
    }
    else
    {
        NSLog(@"Should close: NO.");
        [alert beginSheetModalForWindow:window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:nil];
        return NO;
    }
}
- (void) windowDidBecomeKey:(NSNotification *)aNotification
{
    if (!timer)
    {
        if ([autoLaunch state] != NSOnState)
            [autoLaunch performClick:self];
        [preferences setEnabled:NO];
        [dropboxId setIntValue:[appDelegate dropboxId]];
        timer = [[NSTimer scheduledTimerWithTimeInterval: 0.5
                                                  target: self
                                                selector: @selector(checkClipboard:)
                                                userInfo: nil
                                                 repeats: YES] retain];
    }
}

- (void) checkClipboard: (NSTimer *) timer
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [NSArray arrayWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    if (!copiedItems)
        return;

    NSURL *url = [NSURL URLWithString:[copiedItems objectAtIndex:0]];
    if (!url)
        return;

    if ([[url host] hasSuffix:@".dropbox.com"])
    {
        NSArray* components = [url pathComponents];
        NSString* dirComponent = [components objectAtIndex:1];
        if (![dirComponent isEqualToString:@"u"])
            return;

        NSString* idComponent = [components objectAtIndex:2];
        int idFromUrl = [idComponent intValue];
        if (idFromUrl && idFromUrl != lastIdFromUrl)
        {
            lastIdFromUrl = idFromUrl;
            [dropboxId setIntValue:idFromUrl];
        }
    }
}

@end