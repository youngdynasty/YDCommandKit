//
//  YDCommandOutput.m
//  emporter
//
//  Created by Mikey on 23/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import "YDCommandOutput.h"
#import "YDCommandElasticTabstop.h"


@interface YDCommandOutput()
@property(nonatomic, setter=_setFileHandle:) NSFileHandle *_fileHandle;
@property(nonatomic, setter=_setStyle:) YDCommandOutputStyle _style;
@end


@implementation YDCommandOutput
@synthesize _style = _style;
@synthesize _fileHandle = _fileHandle;

- (instancetype)init {
    [NSException raise:NSInternalInconsistencyException format:@"*** %@ cannot be initialized directly", self.className];
    return nil;
}

+ (instancetype)standardOut {
    static YDCommandOutput *standardOut = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        standardOut = [[self alloc] _initWithFileHandle:[NSFileHandle fileHandleWithStandardOutput]];
    });
    return standardOut;
}

+ (instancetype)standardError {
    static YDCommandOutput *standardError = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        standardError = [[self alloc] _initWithFileHandle:[NSFileHandle fileHandleWithStandardError]];
    });
    return standardError;
}

+ (NSData *)UTF8DataCapturedByBlock:(YDCommandOutputWriterBlock)block {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *pr = pipe.fileHandleForReading;
    NSFileHandle *pw = pipe.fileHandleForWriting;
    
    block([[self alloc] _initWithFileHandle:pw]);
    
    [pw closeFile];
    
    return [pr readDataToEndOfFile];
}

- (instancetype)_initWithFileHandle:(NSFileHandle *)handle {
    self = [super init];
    if (self == nil)
        return nil;
    
    _fileHandle = handle;
    
    return self;
}

- (void)_appendData:(NSData *)data {
    if (data != nil) {
        [_fileHandle writeData:data];
    }
}

- (void)appendString:(NSString *)string {
    [self _appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self appendString:[[NSString alloc] initWithFormat:format arguments:args]];
    va_end(args);
}

- (void)appendJSONObject:(id)obj {
    NSJSONWritingOptions opts = 0;
    
    if (@available(macOS 10.13, *)) {
        opts |= NSJSONWritingSortedKeys;
    }
    
    [_fileHandle writeData:[NSJSONSerialization dataWithJSONObject:obj options:opts error:NULL] ?: [NSData data]];
    [self appendString:@"\n"];
}

- (void)_setStyle:(YDCommandOutputStyle)style {
    if (style != _style) {
        _style = style;
        [self appendString:YDCommandOutputStyleString(style)];
    }
}

- (void)applyStyle:(YDCommandOutputStyle)style withinBlock:(YDCommandOutputWriterBlock)block {
    [_fileHandle writeData:[YDCommandOutput UTF8DataCapturedByBlock:^(id<YDCommandOutputWriter> pipe) {
        [(YDCommandOutput*)pipe _setStyle:YDCommandStyleBlend(style, self._style)];
        block(pipe);
        [(YDCommandOutput*)pipe _setStyle:self._style];
    }]];
}

- (void)applyTabWidth:(NSUInteger)width withinBlock:(YDCommandOutputWriterBlock)block {
    NSData *data = [YDCommandOutput UTF8DataCapturedByBlock:^(id<YDCommandOutputWriter> pipe) {
        [(YDCommandOutput*)pipe _setStyle:self._style];
        block(pipe);
    }];
    
    [self _appendData:YDCommandElasticTabstopUTF8Data(data, width)];
}

@end
