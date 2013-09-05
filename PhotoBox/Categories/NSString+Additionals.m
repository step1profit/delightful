//
//  NSString+Additionals.m
//  PhotoBox
//
//  Created by Nico Prananta on 9/6/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import "NSString+Additionals.h"

@implementation NSString (Additionals)

- (BOOL)isValidURL {
    NSError *error;
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:&error];
    NSInteger numberOfMatches = [detector numberOfMatchesInString:self options:0 range:NSMakeRange(0, self.length)];
    if (numberOfMatches > 0) {
        return YES;
    }
    return NO;
}

- (NSString *)stringWithHttpSchemeAddedIfNeeded {
    NSString *urlToTest = self;
    if (![self hasPrefix:@"http://"]) {
        urlToTest = [NSString stringWithFormat:@"http://%@", self];
    }
    return urlToTest;
}

@end