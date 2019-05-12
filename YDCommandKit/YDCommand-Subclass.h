//
//  YDCommand-Subclass.h
//  emporter
//
//  Created by Mikey on 24/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import "YDCommand.h"
#import "YDCommandVariable.h"

NS_ASSUME_NONNULL_BEGIN

@interface YDCommand(Subclass)

/*! The parent of the command (nil unless the receiver is in a \c YDCommandTree) */
@property (nonatomic, weak, readonly) YDCommandTree *__nullable parent;

/*! The root of the command (nil unless the receiver is in a \c YDCommandTree) */
@property (nonatomic, weak, readonly) YDCommandTree *__nullable root;

/*! The usage string used to when outputting usage to the output. Can be nil. */
@property (nonatomic) NSString *__nullable usage;

/*! Variables are used to parse arguments and must be set before the command runs. */
@property (nonatomic, copy) NSArray<YDCommandVariable*> *variables;

/*! If the command allows multiple arguments, this property must be YES before the command (or its parent) runs. */
@property (nonatomic) BOOL allowsMultipleArguments;

/*! numberOfRequiredArguments is used to determine if arguments are valid when the command runs. */
@property (nonatomic) NSUInteger numberOfRequiredArguments;

/*! maximumNumberOfArguments is used to determine if arguments are valid when the command runs. */
@property (nonatomic) NSUInteger maximumNumberOfArguments;

/*!
 Subclasses should override this method as its "main" method. This method is only invoked once all variables and arguments have been parsed.
 
 \param arguments The remaining arguments after parsing variables
 
 \returns The return code for the command.
 */
- (YDCommandReturnCode)executeWithArguments:(NSArray<NSString *> *)arguments;
@end

NS_ASSUME_NONNULL_END
