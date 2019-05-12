//
//  YDCommand.h
//  emporter-cli
//
//  Created by Mikey on 21/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YDCommandOutput;

NS_ASSUME_NONNULL_BEGIN

/*!
 YDCommand is an abstract class used to define command to be ran from the terminal. It is intended to be subclassed.
 
 Subclasses should import \c YDCommand-Subclass.h from their implementation file.
 */
@interface YDCommand : NSObject

/*!
 Common codes used to determine the exit status for a command.
 */
typedef NS_ENUM(int, YDCommandReturnCode) {
    
    /*! The command ran successfully */
    YDCommandReturnCodeOK = 0,
    
    /*! The command had invalid arguments */
    YDCommandReturnCodeInvalidArgs = 1,
    
    /*! The command did not finish successfully */
    YDCommandReturnCodeError = 2,
    
    /*! The command exited due to termination (SIGTERM, SIGINT) */
    YDCommandReturnCodeTerminated = 130
};

/*!
 A convenience method which calls \c runWithArguments: with the arguments used to launch the current process.

 \returns The return code which can be used for exiting.
 */
- (YDCommandReturnCode)run;

/*!
 Run the command with the given arguments.
 
 \param arguments  The arguments passed to the command for processing
 
 \returns The return code which can be used for exiting.
 */
- (YDCommandReturnCode)runWithArguments:(NSArray<NSString*> *)arguments;

/*! Print the command usage
 
 \param output          Write usage to this output.
 \param withVariables   Include variables (options) in the output.
 
 */
- (void)appendUsageToOutput:(YDCommandOutput *)output withVariables:(BOOL)withVariables;

@end

/*!
 YDCommandTree is a subclass of YDCommand which can be used to register subcommands.
 */
@interface YDCommandTree : YDCommand

/*!
 Add a command to the tree.
 
 Commands in the tree are invoked when the receiver is ran with arguments which match a command's name.
 Arguments specified after the command are passed directly to the command for processing.
 
 \param command     	The command to add to the tree
 \param name            The name of the command
 \param description     The description of the command (included in the usage)
 */
- (void)addCommand:(YDCommand *)command withName:(NSString *)name description:(NSString *)description;

/* Commands in the tree. */
@property (nonatomic, copy, readonly) NSArray<YDCommand*> *commands;

/*!
 Write all command names and descriptions to the output. This method is invoked when outputting usage for the tree.
 
 \param output  The destination
 */
- (void)appendCommandsToOutput:(YDCommandOutput *)output;

/*!
 Find a command with a space separated path. Works recursively if the tree contains other command trees.
 
 For example, if the received had a command named "tree", which was a YDCommandTree with subcommands "add" and "list",
 "tree" would return the tree, and "tree add" would return the "add" command added to "tree".
 
 Its recursive nature works really well if you have a "help" command in your app and you want to print usage for specific subcommands.
 
 \param path   A space-separated path used to traverse the tree
 
 \returns A YDCommand matching the path, or nil.
 */
- (YDCommand *__nullable)commandWithPath:(NSString *)path;

/*!
 Find the path for a command by recursively walking the tree.
 
 This method is the complementary method for \c commandWithPath:. To better understand paths, refer to its documentation.
 
 \param command A command registered within the receiver
 
 \returns A path for the command, or nil.
 */
- (NSString *__nullable)pathForCommand:(YDCommand *)command;


@end

NS_ASSUME_NONNULL_END
