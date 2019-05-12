//
//  YDCommandVariable.h
//  emporter-cli
//
//  Created by Mikey on 21/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YDCommandError.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^YDCommandVariableBlock)(NSString *);


/*!
 YDCommandVariable defines an immutable, type-safe way to define options for commands.
 
 \code
 // Define a variable which will be "bar" when "--foo bar" or "--foo=bar" is passed as an option (argument) to a command
 NSString *foo = nil;
 [YDCommandVariable string:&foo withName:@"--foo" usage:@"Set me!"]
 \endcode
 */
@interface YDCommandVariable : NSObject <NSCopying>

/*! Define a boolean variable with the given name and usage */
+ (instancetype)boolean:(BOOL *)outBool withName:(NSString *)name usage:(NSString *)usage;

/*! Define a boolean (represented as a nullable NSNumber) with the given name and usage */
+ (instancetype)booleanNumber:(NSNumber *_Nullable __strong *_Nonnull)outBool withName:(NSString *)name usage:(NSString *)usage;

/*! Define an integer with the given name and usage */
+ (instancetype)integer:(NSInteger *)outInteger withName:(NSString *)name usage:(NSString *)usage;

/*! Define an string with the given name and usage */
+ (instancetype)string:(NSString *_Nullable __strong *_Nonnull)outString withName:(NSString *)name usage:(NSString *)usage;

/*! Define a block to be invoked when an argument with the given name is found. */
+ (instancetype)block:(YDCommandVariableBlock)block withName:(NSString *)name usage:(NSString *)usage;

/*! Create an alias for the variable (i.e. --help is an alias for -h) */
- (instancetype)variableWithAlias:(NSString *)alias;

/*! The names for the variable */
@property (nonatomic, copy, readonly) NSArray *names;

/*! The usage for the variable (used for command usage) */
@property (nonatomic, copy, readonly) NSString *usage;
@end


/*! YDCommandVariableScanner scans variables from arguments */
@interface YDCommandVariableScanner : NSObject

/*!
 Scan variables from arguments.
 
 \param variables           The variables used to parse arguments
 \param arguments           The arguments used to set variable values
 \param outExtraArguments   The arguments remaining after the scan succeeded. Can be NULL.
 \param outError            An error describing the problem encountered when scanning the variables (see \c YDCommandErrorDomain). Can be NULL.
 
 \returns YES if the variables were scanned without errors.
 */
+ (BOOL)scanVariables:(NSArray<YDCommandVariable*>*)variables arguments:(NSArray<NSString*>*)arguments extraArguments:(NSArray *_Nonnull*__nullable)outExtraArguments error:(NSError **__nullable)outError;

@end

NS_ASSUME_NONNULL_END
