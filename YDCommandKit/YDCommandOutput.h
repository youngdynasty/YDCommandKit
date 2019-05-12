//
//  YDCommandOutput.h
//  emporter
//
//  Created by Mikey on 23/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YDCommandOutputStyle.h"


#define YDStandardOut    [YDCommandOutput standardOut]
#define YDStandardError  [YDCommandOutput standardError]


NS_ASSUME_NONNULL_BEGIN

@protocol YDCommandOutputWriter;
typedef void(^YDCommandOutputWriterBlock)(id <YDCommandOutputWriter> output);


/*! An abstract protocol used to write recursively to output styled, well-formated text */
@protocol YDCommandOutputWriter

/*! Append a string to the output */
- (void)appendString:(NSString *)string;

/*! Append a formatted string to the output */
- (void)appendFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

/* Apply a style to the output within a block. */
- (void)applyStyle:(YDCommandOutputStyle)style withinBlock:(YDCommandOutputWriterBlock)block;

/* Apply fixed tab width within a block */
- (void)applyTabWidth:(NSUInteger)width withinBlock:(YDCommandOutputWriterBlock)block;

@end


@interface YDCommandOutput : NSObject <YDCommandOutputWriter>

/*! A shared instance which outputs to stdout */
+ (instancetype)standardOut;

/*! A shared instance which outputs to stderr */
+ (instancetype)standardError;

/*! Capture output within a block to an instance of NSData. */
+ (NSData *)UTF8DataCapturedByBlock:(YDCommandOutputWriterBlock)block;

/*! A convenience method to append a JSON object to the receiver using NSJSONSerialization */
- (void)appendJSONObject:(id)obj;

@end

NS_ASSUME_NONNULL_END
