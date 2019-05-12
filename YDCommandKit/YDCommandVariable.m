//
//  YDCommandVariable.m
//  emporter-cli
//
//  Created by Mikey on 21/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import "YDCommandVariable.h"
#import "YDCommandError.h"


@interface YDCommandVariable()
@property(nonatomic,setter=_setIsFlag:) BOOL _isFlag;
@property(nonatomic,copy,setter=_setNames:) NSArray *names;
@property(nonatomic,copy,setter=_setUsage:) NSString *usage;
@property(nonatomic,copy,setter=_setHandler:) BOOL(^_handler)(NSString *stringValue);
@end


@implementation YDCommandVariable
@synthesize _handler = _handler;
@synthesize _isFlag = _isFlag;

+ (instancetype)boolean:(BOOL *)outBool withName:(NSString *)name usage:(NSString *)usage {
    
    YDCommandVariable *opt = [[[self class] alloc] init];
    opt.names = @[name];
    opt.usage = usage;
    opt._isFlag = YES;
    opt._handler = ^BOOL(NSString *stringValue) {
        (*outBool) = [stringValue boolValue];
        return YES;
    };
    
    return opt;
}

+ (instancetype)booleanNumber:(NSNumber *__strong *)outBool withName:(NSString *)name usage:(NSString *)usage {
    YDCommandVariable *opt = [[[self class] alloc] init];
    opt.names = @[name];
    opt.usage = usage;
    opt._isFlag = YES;
    opt._handler = ^BOOL(NSString *stringValue) {
        (*outBool) = [NSNumber numberWithBool:[stringValue boolValue]];
        return YES;
    };
    
    return opt;
}

+ (instancetype)integer:(NSInteger *)outInteger withName:(NSString *)name usage:(NSString *)usage {
    YDCommandVariable *opt = [[[self class] alloc] init];
    opt.names = @[name];
    opt.usage = usage;
    opt._handler = ^BOOL(NSString *stringValue) {
        return [[NSScanner scannerWithString:stringValue] scanInteger:outInteger];
    };
    
    return opt;
}

+ (instancetype)string:(NSString *__strong *)outString withName:(NSString *)name usage:(NSString *)usage {
    YDCommandVariable *opt = [[[self class] alloc] init];
    opt.names = @[name];
    opt.usage = usage;
    opt._handler = ^BOOL(NSString *stringValue) {
        (*outString) = [stringValue copy];
        return YES;
    };
    return opt;
}

+ (instancetype)block:(BOOL(^)(NSString *))block withName:(NSString *)name usage:(NSString *)usage {
    YDCommandVariable *opt = [[[self class] alloc] init];
    opt.names = @[name];
    opt.usage = usage;
    opt._handler = block;
    
    return opt;
}

- (instancetype)variableWithAlias:(NSString *)alias {
    YDCommandVariable *copy = [self copy];
    copy.names = [_names arrayByAddingObject:alias];
    return copy;
}

- (nonnull id)copyWithZone:(NSZone *)zone {
    YDCommandVariable *copy = [[[self class] allocWithZone:zone] init];
    copy->_names = [_names copy];
    copy->_handler = [_handler copy];
    copy->_usage = [_usage copy];
    copy->_isFlag = _isFlag;
    
    return copy;
}

@end


@implementation YDCommandVariableScanner

+ (YDCommandVariable *)_variableWithName:(NSString *)name inArray:(NSArray<YDCommandVariable *> *)variables {
    for (YDCommandVariable *variable in variables) {
        if ([variable.names containsObject:name]) {
            return variable;
        }
    }
    
    return nil;
}

+ (BOOL)scanVariables:(NSArray<YDCommandVariable*>*)variables arguments:(NSArray<NSString*>*)arguments extraArguments:(NSArray **)extraArguments error:(NSError **)outError {
    __block YDCommandVariable *currentVar = nil;
    __block NSString *currentVarName = nil;
    __block NSError *error = nil;
    __block BOOL parseVariables = YES;
    
    NSMutableArray *parsedArguments = [NSMutableArray array];
    
    [arguments enumerateObjectsUsingBlock:^(NSString *argString, NSUInteger idx, BOOL *stop) {
        // Parse next variable
        if (parseVariables && currentVar == nil && [argString hasPrefix:@"-"]) {
            // ... unless we have our first non-flag argument
            parseVariables = !([@"-" isEqualToString:argString] || parsedArguments.count > 0);
            
            // ... or our delimiter -- (which we'll ignore)
            if ([argString isEqualToString:@"--"]) {
                parseVariables = NO;
                return;
            }
            
            if (parseVariables) {
                // Parse var=val values
                NSRange equalRange = [argString rangeOfString:@"="];
                
                if (equalRange.location != NSNotFound) {
                    currentVarName = [argString substringToIndex:equalRange.location];
                    argString = [argString substringFromIndex:equalRange.location+1];
                } else {
                    currentVarName = argString;
                }
                
                currentVar = [self _variableWithName:currentVarName inArray:variables];
                
                if (currentVar == nil) {
                    error = [NSError errorWithDomain:YDCommandErrorDomain
                                                code:YDCommandErrorCodeUnknownVariable
                                            userInfo:@{
                                                       YDCommandVariableNameKey: currentVarName,
                                                       NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unrecognized flag: %@", currentVarName],
                                                       }];
                    
                    (*stop) = YES;
                    return;
                }
                
                if (equalRange.location == NSNotFound) {
                    if (currentVar._isFlag) {
                        // Flags are implicitly var=1
                        argString = @"1";
                    } else {
                        // ... and other variables will receive their value with the next iteration
                        return;
                    }
                }
            }
        }
        
        // Parse current variable value or add to arguments
        if (currentVar == nil) {
            [parsedArguments addObject:argString];
        } else if (currentVar._handler(argString)) {
            currentVar = nil;
            currentVarName = nil;
        } else {
            error = [NSError errorWithDomain:YDCommandErrorDomain
                                        code:YDCommandErrorCodeParseError
                                    userInfo:@{
                                               YDCommandVariableNameKey: currentVarName,
                                               YDCommandVariableValueKey: argString,
                                               NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid %@ value: '%@'", currentVarName, argString],
                                               }];
            
            (*stop) = YES;
        }
    }];
    
    // Make sure variable/values are balanced
    if (error == nil && currentVarName != nil) {
        error = [NSError errorWithDomain:YDCommandErrorDomain
                                    code:YDCommandErrorCodeParseError
                                userInfo:@{
                                           YDCommandVariableNameKey: currentVarName,
                                           NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Missing value: %@", currentVarName],
                                           }];
    }
    
    if (error == nil && extraArguments != NULL) {
        (*extraArguments) = parsedArguments;
    }
    
    if (outError != NULL) {
        (*outError) = error;
    }
    
    return (error == nil);
}

@end
