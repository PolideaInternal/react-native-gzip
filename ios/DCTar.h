////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTar.h
//
//  Created by Dalton Cherry on 5/21/14.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 Discussion.
 It is important to know that all the file system based tar commands used chunked/buffer methods to save memory.
 Due to the fact that tars are normally used to compress lots of content, It is strongly recommend to use those method
 versus the in memory data options.
 */
#import <Foundation/Foundation.h>

@interface DCTar : NSObject

/**
 gzipped some data.
 @param: The data to gzip.
 @return The newly gzipped data.
 */
+(NSData*)gzipCompress:(NSData*)data;

/**
 decompress a gzipped data blob.
 @param: The data to ungzip.
 @return The newly unzipped data.
 */
+(NSData*)gzipDecompress:(NSData*)data;

/**
 decompress a zlib data blob.
 @param: The data to decompress.
 @return The newly decompressed data.
 */
+(NSData*)zlibDecompress:(NSData*)data;

/**
 compress a zlib data blob.
 @param: The data to compress.
 @return The newly compressed data.
 */
+(NSData*)zlibCompress:(NSData*)data;

@end
