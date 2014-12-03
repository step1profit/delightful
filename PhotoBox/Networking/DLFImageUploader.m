//
//  DLFImageUploader.m
//  Delightful
//
//  Created by Nico Prananta on 6/14/14.
//  Copyright (c) 2014 Touches. All rights reserved.
//

#import "DLFImageUploader.h"

#import "PhotoBoxClient.h"

#import "DLFAsset.h"

@import Photos;

NSString *const DLFAssetUploadProgressNotification = @"com.getdelightfulapp.DLFAssetUploadProgressNotification";

NSString *const DLFAssetUploadDidChangeNumberOfUploadsNotification = @"com.getdelightfulapp.DLFAssetUploadDidChangeNumberOfUploadsNotification";

NSString *const DLFAssetUploadDidChangeNumberOfFailUploadsNotification = @"com.getdelightfulapp.DLFAssetUploadDidChangeNumberOfFailUploadsNotification";

NSString *const DLFAssetUploadDidSucceedNotification = @"com.getdelightfulapp.DLFAssetUploadDidSucceedNotification";

NSString *const DLFAssetUploadDidFailNotification = @"com.getdelightfulapp.DLFAssetUploadDidFailNotification";

NSString *const kAssetURLKey = @"com.getdelightfulapp.kAssetURLKey";

NSString *const kProgressKey = @"com.getdelightfulapp.kProgressKey";

NSString *const kAssetKey = @"com.getdelightfulapp.kAssetKey";

NSString *const kErrorKey = @"com.getdelightfulapp.kErrorKey";

NSString *const kNumberOfUploadsKey = @"com.getdelightfulapp.kNumberOfUploadsKey";

NSString *const kNumberOfFailUploadsKey = @"com.getdelightfulapp.kNumberOfFailUploadsKey";

NSString *const DLFAssetUploadDidQueueAssetNotification = @"com.getdelightfulapp.DLFAssetUploadDidQueueAssetNotification";

@interface DLFImageUploader ()

@property (nonatomic, strong) NSMutableArray *uploadingAssets;

@property (nonatomic, strong) NSMutableOrderedSet *uploadFailAssets;

@end

@implementation DLFImageUploader

+ (instancetype)sharedUploader {
    static DLFImageUploader *_sharedUploader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedUploader = [[DLFImageUploader alloc] init];
        _sharedUploader.uploadingAssets = [[NSMutableArray alloc] init];
        _sharedUploader.uploadFailAssets = [[NSMutableOrderedSet alloc] init];
    });
    
    return _sharedUploader;
}

- (void)reloadUpload {
    NSArray *fails = [self.uploadFailAssets mutableCopy];
    [self clearFailUploads];
    for (DLFAsset *asset in fails) {
        [self queueAsset:asset];
    }
}

- (BOOL)queueAsset:(DLFAsset *)asset {
    if ([self isUploadingAsset:asset]) {
        return NO;
    }
    
    [self removeFailAsset:asset];
    [self addAsset:asset];
    __weak typeof (self) selfie = self;
    [[PhotoBoxClient sharedClient] uploadAsset:asset progress:^(float progress) {
        [selfie uploadProgress:progress asset:asset];
    } success:^(id object) {
        [selfie assetUploadDidSucceed:asset];
        [selfie removeFailAsset:asset];
    } failure:^(NSError *error) {
        [selfie assetUploadDidFail:asset error:error];
    }];
    
    return YES;
}

- (NSArray *)queuedAssets {
    return self.uploadingAssets;
}

- (NSArray *)failedAssets {
    return self.uploadFailAssets.array;
}

- (void)uploadProgress:(float)progress asset:(DLFAsset *)asset {
    [[NSNotificationCenter defaultCenter] postNotificationName:DLFAssetUploadProgressNotification object:nil userInfo:@{kAssetURLKey: [asset.asset localIdentifier], kProgressKey: @(progress)}];
}

- (void)assetUploadDidSucceed:(DLFAsset *)asset {
    [self removeAsset:asset];
    [[NSNotificationCenter defaultCenter] postNotificationName:DLFAssetUploadDidSucceedNotification object:nil userInfo:@{kAssetKey: asset}];
}

- (void)assetUploadDidFail:(DLFAsset *)asset error:(NSError *)error {
    [self addFailAsset:asset];
    [self removeAsset:asset];
    [[NSNotificationCenter defaultCenter] postNotificationName:DLFAssetUploadDidFailNotification object:nil userInfo:@{kAssetKey: asset, kErrorKey: error}];
}

- (void)addAsset:(DLFAsset *)asset {
    @synchronized(self){
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfUploading))];
        [self.uploadingAssets addObject:asset];
        _numberOfUploading = self.uploadingAssets.count;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfUploading))];
        [[NSNotificationCenter defaultCenter] postNotificationName:DLFAssetUploadDidChangeNumberOfUploadsNotification object:nil userInfo:@{kNumberOfUploadsKey: @(_numberOfUploading), kNumberOfFailUploadsKey:@(_numberOfFailUpload)}];
        [[NSNotificationCenter defaultCenter] postNotificationName:DLFAssetUploadDidQueueAssetNotification object:nil userInfo:@{kAssetKey:asset}];
    }
}

- (void)removeAsset:(DLFAsset *)asset {
    @synchronized(self){
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfUploading))];
        [self.uploadingAssets removeObject:asset];
        _numberOfUploading = self.uploadingAssets.count;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfUploading))];
        [[NSNotificationCenter defaultCenter] postNotificationName:DLFAssetUploadDidChangeNumberOfUploadsNotification object:nil userInfo:@{kNumberOfUploadsKey: @(_numberOfUploading), kNumberOfFailUploadsKey:@(_numberOfFailUpload)}];
    }
}

- (void)addFailAsset:(DLFAsset *)asset {
    @synchronized(self) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfFailUpload))];
        [self.uploadFailAssets addObject:asset];
        _numberOfFailUpload = self.uploadFailAssets.count;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfFailUpload))];
        [[NSNotificationCenter defaultCenter] postNotificationName:DLFAssetUploadDidChangeNumberOfFailUploadsNotification object:nil userInfo:@{kNumberOfFailUploadsKey: @(_numberOfFailUpload)}];
    }
}

- (void)removeFailAsset:(DLFAsset *)asset {
    @synchronized(self) {
        if ([self.uploadFailAssets containsObject:asset]) {
            [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfFailUpload))];
            [self.uploadFailAssets removeObject:asset];
            _numberOfFailUpload = self.uploadFailAssets.count;
            [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfFailUpload))];
            [[NSNotificationCenter defaultCenter] postNotificationName:DLFAssetUploadDidChangeNumberOfFailUploadsNotification object:nil userInfo:@{kNumberOfFailUploadsKey: @(_numberOfFailUpload)}];
        }
    }
}

- (BOOL)isUploadingAsset:(DLFAsset *)asset {
    @synchronized(self){
        return [self.uploadingAssets containsObject:asset];
    }
}

- (void)clearFailUploads {
    @synchronized(self) {
        [self.uploadFailAssets removeAllObjects];
        [self willChangeValueForKey:NSStringFromSelector(@selector(numberOfFailUpload))];
        _numberOfFailUpload = 0;
        [self didChangeValueForKey:NSStringFromSelector(@selector(numberOfFailUpload))];
    }
}

@end
