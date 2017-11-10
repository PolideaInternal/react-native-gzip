////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCTar.m
//
//  Created by Dalton Cherry on 5/21/14.
//
//  Also created by Patrice Brend'amour of 2014-05-30
//
//  Part of the code was inspired by libarchive
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCTar.h"
#import <zlib.h>

@implementation DCTar


+(NSData*)gzipCompress:(NSData*)data
{
    return [self deflate:data isGzip:YES];
}

+(NSData*)gzipDecompress:(NSData*)data
{
    return [self inflate:data isGzip:YES];
}

+(NSData*)zlibDecompress:(NSData*)data
{
    return [self inflate:data isGzip:NO];
}

+(NSData*)zlibCompress:(NSData*)data
{
    return [self deflate:data isGzip:NO];
}

+(NSData*)deflate:(NSData*)data isGzip:(BOOL)isgzip
{
    if ([data length] == 0)
        return nil;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef*)[data bytes];
    strm.avail_in = (uInt)[data length];
    
    if(isgzip){
        if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK)
            return nil;
    } else {
        if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK)
            return nil;
    }
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chuncks for expansion
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy:16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([compressed length] - strm.total_out);
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength:strm.total_out];
    return [NSData dataWithData:compressed];
}

+(BOOL)fileDeflate:(NSFileHandle*)fileHandle isGzip:(BOOL)isgzip toPath:(NSString*)toPath
{
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    
    if(isgzip){
        if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK)
            return NO;
    } else {
        if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK)
            return NO;
    }
    
    [@"" writeToFile:toPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:toPath];
    BOOL done = NO;
    uInt chunkSize = 16384;
    do {
        NSData *chunk = [fileHandle readDataOfLength:chunkSize];
        strm.avail_in = (uInt)[chunk length];
        strm.next_in = (Bytef*)[chunk bytes];
        int flush = Z_NO_FLUSH;
        if(chunk.length == 0)
            flush = Z_FINISH;
        do {
            NSMutableData *compressed = [NSMutableData dataWithLength:chunkSize];
            strm.avail_out = chunkSize;
            strm.next_out = (Bytef*)[compressed mutableBytes];
            NSInteger status = deflate (&strm, flush);
            if (status == Z_STREAM_END)
                done = YES;
            else if(status == Z_BUF_ERROR)
                continue;
            else if (status != Z_OK) {
                done = YES;
                return NO;
            }
            NSInteger have = chunkSize - strm.avail_out;
            [compressed setLength:have];
            [writeHandle writeData:compressed];
            
        } while (strm.avail_out == 0);
        
    } while (!done);
    deflateEnd(&strm);
    return YES;
}

+(NSData*)inflate:(NSData*)data isGzip:(BOOL)isgzip
{
    if ([data length] == 0)
        return nil;
    
    uInt full_length = (uInt)[data length];
    uInt half_length = (uInt)[data length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef*)[data bytes];
    strm.avail_in = (uInt)[data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if(isgzip) {
        if(inflateInit2(&strm, (15+32)) != Z_OK)
            return nil;
    } else {
        if(inflateInit(&strm) != Z_OK)
            return nil;
    }
    
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy:half_length];
        
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END)
            done = YES;
        else if(status == Z_BUF_ERROR)
            continue;
        else if (status != Z_OK)
            break;
    }
    if (inflateEnd (&strm) != Z_OK)
        return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData:decompressed];
    }
    return nil;
}

+(BOOL)fileInflate:(NSFileHandle*)fileHandle isGzip:(BOOL)isgzip toPath:(NSString*)toPath
{
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    
    if(isgzip) {
        if(inflateInit2(&strm, (15+32)) != Z_OK)
            return NO;
    } else {
        if(inflateInit(&strm) != Z_OK)
            return NO;
    }
    [@"" writeToFile:toPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:toPath];
    BOOL done = NO;
    uInt chunkSize = 16384;
    do {
        NSData *chunk = [fileHandle readDataOfLength:chunkSize];
        strm.avail_in = (uInt)[chunk length];
        strm.next_in = (Bytef*)[chunk bytes];
        
        do {
            NSMutableData *decompressed = [NSMutableData dataWithLength:chunkSize];
            strm.avail_out = chunkSize;
            strm.next_out = (Bytef*)[decompressed mutableBytes];
            NSInteger status = inflate (&strm, Z_SYNC_FLUSH);
            if (status == Z_STREAM_END)
                done = YES;
            else if(status == Z_BUF_ERROR)
                continue;
            else if (status != Z_OK) {
                done = YES;
                return NO;
            }
            NSInteger have = chunkSize - strm.avail_out;
            [decompressed setLength:have];
            [writeHandle writeData:decompressed];
            
        } while (strm.avail_out == 0);
        
        
    } while (!done);
    
    [writeHandle closeFile];
    if (inflateEnd (&strm) != Z_OK)
        return NO;
    
    return YES;
}

@end
