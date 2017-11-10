#import "RNGZipManager.h"

@interface RNGZipManager ()

@end

@implementation RNGZipManager

RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(gunzip,
                 filePath: (NSString *) source
                 destFilePath: (NSString *) dest
                 force: (BOOL) force
                 resolver: (RCTPromiseResolveBlock)resolve
                 rejecter: (RCTPromiseRejectBlock)reject)
{
    NSFileManager *manager = [NSFileManager defaultManager];

    if (![manager fileExistsAtPath:source]) {
        reject(@"-2", @"file not found", nil);
        return;
    }

    if ([manager fileExistsAtPath:dest]) {
        if (!force) {
            reject(@"-2", @"folder exists", nil);
            return;
        }
        NSError *unlinkError;
        if (![manager removeItemAtPath:dest error:&unlinkError]) {
            reject([@(unlinkError.code) stringValue], unlinkError.localizedDescription, unlinkError);
            return;
        }
    }
    //Write the file on filesystem
    if (![[NSFileManager defaultManager] createFileAtPath:dest contents:[DCTar decompressData:[manager contentsAtPath:source] attributes:nil]) {
        reject(@"-3", @"error while decompressing", nil);
        return;
    }

    // TODO Passing an error here results in EXC_BAD_ACCESS because the error is released
//    if (![DCTar decompressData:[manager contentsAtPath:source] toPath:folder error:nil]) {
//        reject(@"-3", @"error while decompressing", nil);
//        return;
//    }

    resolve(@{@"path": folder});
}

@end
