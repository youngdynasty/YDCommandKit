//
//  YDCommandOutputStyle.m
//  emporter-cli
//
//  Created by Mikey on 25/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import "YDCommandOutputStyle.h"

BOOL YDCommandOutputStyleDisabled = NO;

NSString* YDCommandOutputStyleString(YDCommandOutputStyle style) {
    if (YDCommandOutputStyleDisabled) {
        return @"";
    }

    // Colors and attributes are offset by 1 so that the "inherit" option is explicit
    
    NSMutableArray *components = [NSMutableArray arrayWithObject:@(MAX(0, YDCommandOutputStyleGetAttribute(style) - 1))];
    
    int v = 0;
    
    if ((v = YDCommandOutputStyleGetForegroundColor(style)) != YDCommandOutputStyleColorInherit) {
        [components addObject:@((v + 30) - 1)];
    }
    
    if ((v = YDCommandOutputStyleGetBackgroundColor(style)) != YDCommandOutputStyleColorInherit) {
        [components addObject:@((v + 40) - 1)];
    }
    
    return [NSString stringWithFormat:@"\e[%@m", [components componentsJoinedByString:@";"]];
}

YDCommandOutputStyle YDCommandOutputStyleFromString(NSString *string) {
    if (string.length < 4) {
        return 0;
    }
    
    YDCommandOutputStyleAttribute attr = YDCommandOutputStyleAttributeInherit;
    YDCommandOutputStyleColor foregroundColor = YDCommandOutputStyleColorInherit;
    YDCommandOutputStyleColor backgroundColor = YDCommandOutputStyleColorInherit;
    
    for (NSString *component in [[string substringWithRange:NSMakeRange(2, string.length-3)] componentsSeparatedByString:@";"]) {
        NSInteger v = [component integerValue];
        
        // Colors and attributes are offset by 1 so that the "inherit" option is explicit
        if (v < 30) {
            attr = v + 1;
        } else if (v >= 30 && v < 40) {
            foregroundColor = (v - 30) + 1;
        } else if (v >= 40 && v < 50) {
            backgroundColor = (v - 40) + 1;
        }
    }
    
    return YDCommandOutputStyleMake(foregroundColor, backgroundColor, attr);
}

NSArray<NSValue*>* _YDCommandOutputStyleStringRangeValues(NSString *string) {
    static NSRegularExpression *styleRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Regex originated from https://github.com/chalk/ansi-regex/blob/a079ab2d30cfb752a3f247dcf358d0a591c288c5/index.js#L8
        styleRegex = [NSRegularExpression regularExpressionWithPattern:@"[\\u001B\\u009B]\\[[\\]()#;?]*(?:(?:(?:[a-zA-Z\\d]*(?:;[-a-zA-Z\\d\\/#&.:=?%@~_]*)*)?\\u0007)|(?:(?:\\d{1,4}(?:;\\d{0,4})*)?[\\dA-PR-TZcf-ntqry=><~]))" options:0 error:NULL];
    });
    
    NSMutableArray<NSValue*> *styleRangeValues = [NSMutableArray array];
    
    [styleRegex enumerateMatchesInString:string options:0 range:NSMakeRange(0, string.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [styleRangeValues addObject:[NSValue valueWithRange:result.range]];
    }];
    
    return [styleRangeValues copy];
}

void YDCommandOutputStyleStringEnumerateUsingBlock(NSString *string, void(^block)(NSString *substring, YDCommandOutputStyle *style, BOOL *stop)) {
    NSUInteger lastIndex = 0;
    BOOL stop = NO;
    
    // Iterate through all style string ranges
    for (NSValue *v in _YDCommandOutputStyleStringRangeValues(string)) {
        NSRange rangeValue = v.rangeValue;
        NSString *chunk = [string substringWithRange:NSMakeRange(lastIndex, rangeValue.location - lastIndex)];
        
        // Invoke block for text before the current value
        if (chunk.length > 0) {
            block(chunk, nil, &stop);
        }
        
        // Invoke the block for the parsed style string
        if (!stop) {
            NSString *styleString = [string substringWithRange:rangeValue];
            YDCommandOutputStyle style = YDCommandOutputStyleFromString(styleString);
            block(styleString, &style, &stop);
        }
        
        if (stop) {
            return;
        }
        
        lastIndex = NSMaxRange(rangeValue);
    }
    
    // Invoke block for remaining text
    if (lastIndex < string.length) {
        block([string substringWithRange:NSMakeRange(lastIndex, string.length - lastIndex)], nil, &stop);
    }
}
