//
//  Photo.m
//  PhotoBox
//
//  Created by Nico Prananta on 8/31/13.
//  Copyright (c) 2013 Touches. All rights reserved.
//

#import "Photo.h"
#import "Tag.h"
#import "Album.h"
#import "FetchedIn.h"

#import "NSObject+Additionals.h"
#import "NSArray+Additionals.h"
#import "MTLModel+NSCoding.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <NSDate+Escort.h>

@implementation Photo

@synthesize originalImage = _originalImage;

- (id)initWithAsset:(ALAsset *)asset {
    self = [super init];
    if (self) {
        self.asset = asset;
    }
    return self;
}

#pragma mark - NSCoding

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *superBehaviour = [[super encodingBehaviorsByPropertyKey] mutableCopy];
    [self ignorePropertyInBehaviour:superBehaviour propertyKey:NSStringFromSelector(@selector(placeholderImage))];
    [self ignorePropertyInBehaviour:superBehaviour propertyKey:NSStringFromSelector(@selector(asAlbumCoverImage))];
    
    return superBehaviour;
}

+ (void)ignorePropertyInBehaviour:(NSMutableDictionary *)behaviour propertyKey:(NSString *)propertyKey {
    if ([behaviour objectForKey:propertyKey]) {
        [behaviour setObject:@(MTLModelEncodingBehaviorExcluded) forKey:propertyKey];
    }
}

#pragma mark - Setters

- (void)setAsset:(ALAsset *)asset {
    if (_asset != asset) {
        _asset = asset;
        
        if (_asset) {
            CGImageRef thumbnail = [_asset thumbnail];
            if (thumbnail) {
                self.placeholderImage = [UIImage imageWithCGImage:thumbnail];
            }
            
            NSDate *createdDate = [_asset valueForProperty:ALAssetPropertyDate];
            NSInteger dateTakenDay = [createdDate day];
            NSInteger dateTakenMonth = [createdDate month];
            NSInteger dateTakenYear = [createdDate gregorianYear];
            [self setValue:@(dateTakenDay) forKey:NSStringFromSelector(@selector(dateTakenDay))];
            [self setValue:@(dateTakenMonth) forKey:NSStringFromSelector(@selector(dateTakenMonth))];
            [self setValue:@(dateTakenYear) forKey:NSStringFromSelector(@selector(dateTakenYear))];
            [self setValue:[NSString stringWithFormat:@"%d", [self.placeholderImage hash]] forKey:NSStringFromSelector(@selector(photoHash))];
            [self setValue:[NSString stringWithFormat:@"%d", self.hash] forKey:NSStringFromSelector(@selector(photoId))];
        }
    }
}

#pragma mark - Getters

- (PhotoBoxImage *)originalImage {
    if (!_originalImage) {
        _originalImage = [[PhotoBoxImage alloc] initWithArray:@[(self.pathOriginal)?self.pathOriginal.absoluteString:@"", self.width?:@(0), self.height?:@(0)]];
    }
    return _originalImage;
}

- (PhotoBoxImage *)thumbnailImage {
    if (self.photo320x320) return self.photo320x320;
    else if (self.photo200x200) return self.photo200x200;
    else if (self.photo100x100) return self.photo100x100;
    return nil;
}

- (PhotoBoxImage *)normalImage {
    return self.photo640x640;
}

- (NSString *)itemId {
    return self.photoId;
}

- (NSString *)dateTakenString {
    NSString *toReturn = [NSString stringWithFormat:@"%d-%02d-%02d", [self.dateTakenYear intValue], [self.dateTakenMonth intValue], [self.dateTakenDay intValue]];
    return toReturn;
}

- (NSString *)dateMonthYearTakenString {
    return [NSString stringWithFormat:@"%d-%02d", [self.dateTakenYear intValue], [self.dateTakenMonth intValue]];
}

- (NSString *)dimension {
    return [NSString stringWithFormat:@"%dx%d", [self.width intValue], [self.height intValue]];
}

- (NSString *)latitudeLongitudeString {
    if (self.latitude && self.longitude) {
        return [NSString stringWithFormat:@"%@,%@", self.latitude, self.longitude];
    }
    return nil;
}

#pragma mark - JSON Serialization

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [[super class] photoBoxJSONKeyPathsByPropertyKeyWithDictionary:@{
                                                                            @"photoId": @"id",
                                                                            @"photoHash":@"hash",
                                                                            @"photoDescription":@"description",
                                                                            @"dateMonthYearTakenString":NSNull.null
                                                                            }];
}

+ (NSValueTransformer *)timestampJSONTransformer {
    static dispatch_once_t onceToken;
    static NSDateFormatter *dateFormatter;
    
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    });
    
    return [MTLValueTransformer transformerWithBlock:^id(NSString *string) {
        return [dateFormatter dateFromString:string];
    }];
}

+ (NSValueTransformer *)photo320x320JSONTransformer {
    return [[self class] photoImageTransformer];
}

+ (NSValueTransformer *)photo640x640JSONTransformer {
    return [[self class] photoImageTransformer];
}

+ (NSValueTransformer *)photo100x100JSONTransformer {
    return [[self class] photoImageTransformer];
}

+ (NSValueTransformer *)photo200x200JSONTransformer {
    return [[self class] photoImageTransformer];
}

+ (MTLValueTransformer *)photoImageTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSArray *imageArray) {
        return [[PhotoBoxImage alloc] initWithArray:imageArray];
    } reverseBlock:^(PhotoBoxImage *image) {
        return [image toArray];
    }];
}

// NOTE: override MTLModel's dictionaryValue to include dateTakenString in managed object serialization. By default, dateTakenString is not serialized because the isa is nil.
- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *dict = [[super dictionaryValue] mutableCopy];
    [dict setObject:[self dateTakenString] forKey:@"dateTakenString"];
    return dict;
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[Photo class]]) {
        return NO;
    }
    
    return [self isEqualToPhoto:object];
}

- (BOOL)isEqualToPhoto:(Photo *)photo {
    return [self.photoId isEqualToString:photo.photoId];
}

- (NSUInteger)hash {
    return [self.photoHash intValue];
}

@end
