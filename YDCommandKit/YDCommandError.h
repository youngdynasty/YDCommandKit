//
//  YDCommandError.h
//  emporter-cli
//
//  Created by Mikey on 22/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* YDCommandErrorDomain defines an error domain used when command arguments cannot be parsed */
extern NSString *const YDCommandErrorDomain;

/* Error codes within YDCommandErrorDomain */
typedef NS_ENUM(NSUInteger, YDCommandErrorCode) {
    /* Arguments could not be parsed, likely due to an invalid type */
    YDCommandErrorCodeParseError,
    
    /* An unknown variable found */
    YDCommandErrorCodeUnknownVariable
};

/* The variable name which caused YDCommandErrorDomain error */
extern NSString *const YDCommandVariableNameKey;

/* The variable value which caused the YDCommandErrorDomain error (if any) */
extern NSString *const YDCommandVariableValueKey;

NS_ASSUME_NONNULL_END
