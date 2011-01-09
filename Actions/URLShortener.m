//
//  URLShortener.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "URLShortener.h"

#import "GrabBoxAppDelegate.h"
#import "NSString+URLParameters.h"
#import "JSON.h"

@interface URLShortener ()

+ (NSString *) bitlyShorten:(NSString *)url;

@end

@implementation URLShortener

static NSString *BITLY_APIURL = @"http://api.bit.ly/v3/%@?login=%@&apiKey=%@&",
                *BITLY_LOGIN = @"jorgenpt",
                *BITLY_APIKEY = @"R_3a2a07cb1af817ab7de18d17e7f0f57f";

+ (NSString *) shortenURLForFile:(NSString *)file
{
    int dropboxId = [(GrabBoxAppDelegate*)[NSApp delegate] dropboxId];
    int service = [[NSUserDefaults standardUserDefaults] integerForKey:CONFIG(URLShortener)];
    NSString *escapedFile = [file stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *directURL = [NSString stringWithFormat:@"http://dl.dropbox.com/u/%d/Screenshots/%@", dropboxId, escapedFile];
    NSString *shortURL = nil;

    DLog(@"Shortening with service %i.", service);
    switch (service)
    {
        case SHORTENER_BITLY:
            shortURL = [self bitlyShorten:directURL];
            break;
    }

    if (shortURL)
        return shortURL;
    else
        return directURL;
}

+ (NSString *) bitlyShorten:(NSString *)url
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *urlWithoutParams = [NSString stringWithFormat:BITLY_APIURL, @"shorten", BITLY_LOGIN, BITLY_APIKEY];
    NSMutableArray *parameters = [NSMutableArray array];
    [parameters addObject:[NSString stringWithKey:@"longUrl" value:url]];
    
    NSString *xLogin = [defaults stringForKey:CONFIG(BitlyLogin)],
             *xApiKey = [defaults stringForKey:CONFIG(BitlyApiKey)];
    if ([xLogin length] && [xApiKey length])
    {
        [parameters addObject:[NSString stringWithKey:@"x_login" value:xLogin]];
        [parameters addObject:[NSString stringWithKey:@"x_apiKey" value:xApiKey]];
    }

    NSURL *requestUrl = [NSURL URLWithString:[urlWithoutParams stringByAppendingString:[parameters componentsJoinedByString:@"&"]]];
    
    DLog(@"Shortening with url: %@", url);
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:requestUrl];
    
    NSHTTPURLResponse *urlResponse = nil;  
    NSError *error = [[[NSError alloc] init] autorelease];  
    
    NSData *data = [NSURLConnection sendSynchronousRequest:req
                                         returningResponse:&urlResponse
                                                     error:&error];
    
    if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300)
    {
        SBJsonParser *jsonParser = [[SBJsonParser new] autorelease];
        NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSDictionary *dict = (NSDictionary*)[jsonParser objectWithString:jsonString];
        NSNumber *statusCode = [dict objectForKey:@"status_code"];
        
        if ([statusCode intValue] == 200)
        {
            NSString *shortURL = [[dict objectForKey:@"data"] objectForKey:@"url"];
            DLog(@"Got OK! ShortURL: %@", shortURL);
            return shortURL;
        }
        else
        {
            NSLog(@"Could not shorten using bit.ly: %@ %@", statusCode, [dict objectForKey:@"status_txt"]);
            return nil;
        }
    }
    else
    {
        NSLog(@"Could not shorten using bit.ly: %@", urlResponse);
        return nil;
    }
}

@end
