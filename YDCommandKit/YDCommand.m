//
//  YDCommandLineInterface.m
//  emporter
//
//  Created by Mikey on 21/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import "YDCommand.h"
#import "YDCommand-Subclass.h"

#import "YDCommandOutput.h"

static const NSUInteger YDCommandTabWidth = 10;

@interface YDCommand()
@property (nonatomic, weak, setter=_setParent:) YDCommandTree *parent;
@property (nonatomic) NSString *usage;
@property (nonatomic, copy) NSArray<YDCommandVariable*> *variables;

@property (nonatomic) BOOL allowsMultipleArguments;
@property (nonatomic) NSUInteger numberOfRequiredArguments;
@property (nonatomic) NSUInteger maximumNumberOfArguments;

@property (nonatomic,readonly) NSString *_commandPath;
@end


@implementation YDCommand

- (instancetype)init {
    self = [super init];
    if (self == nil)
        return nil;
    
    _variables = @[];
    _maximumNumberOfArguments = NSUIntegerMax;
    
    return self;
}

- (NSString *)_commandPath {
    NSMutableString *commandPath = [NSMutableString string];
    [commandPath appendString:[[NSProcessInfo processInfo] processName]];
    
    NSString *parentPath = self.parent ? [self.parent pathForCommand:self] : nil;
    if (parentPath != nil) {
        [commandPath appendString:@" "];
        [commandPath appendString:parentPath];
    }
    
    return [commandPath copy];
}

- (void)appendUsageToOutput:(YDCommandOutput *)output withVariables:(BOOL)includeVariables {
    [output appendFormat:@"\nUsage: %@", self._commandPath];
    
    if (_usage != nil) {
        [output appendFormat:@" %@", _usage];
    }
    
    [output appendString:@"\n"];

    if (includeVariables && _variables.count > 0) {
        [output appendString:@"\nOptions:\n"];
        
        [output applyTabWidth:YDCommandTabWidth withinBlock:^(id<YDCommandOutputWriter> tabbedOutput) {
            NSCharacterSet *hypenSet = [NSCharacterSet characterSetWithCharactersInString:@"-"];
            
            [[self.variables sortedArrayUsingComparator:^NSComparisonResult(YDCommandVariable *var1, YDCommandVariable *var2) {
                NSString *n1 = [[var1.names componentsJoinedByString:@", "] stringByTrimmingCharactersInSet:hypenSet];
                NSString *n2 = [[var2.names componentsJoinedByString:@", "] stringByTrimmingCharactersInSet:hypenSet];
                return [n1 localizedCaseInsensitiveCompare:n2];
            }] enumerateObjectsUsingBlock:^(YDCommandVariable *var, NSUInteger idx, BOOL * _Nonnull stop) {
                [tabbedOutput appendFormat:@"  %@\t%@\n", [var.names componentsJoinedByString:@", "], var.usage];
            }];
        }];
        
        [output appendString:@"\n"];
    }
}

- (NSString *)_descriptionOfArgumentCount:(NSUInteger)count {
    return count == 1 ? @"1 argument" : [NSString stringWithFormat:@"%ld arguments", _numberOfRequiredArguments];
}

- (NSString *)_describeIssueWithArgumentCount:(NSUInteger)count {
    if (_allowsMultipleArguments) {
        if (_numberOfRequiredArguments > count) {
            return [NSString stringWithFormat:@"\"%@\" expects at least %@.", self._commandPath, [self _descriptionOfArgumentCount:_numberOfRequiredArguments]];
        } else if (count > _maximumNumberOfArguments) {
            return [NSString stringWithFormat:@"\"%@\" expects at most %@.", self._commandPath, [self _descriptionOfArgumentCount:_maximumNumberOfArguments]];
        }
    } else if (_numberOfRequiredArguments != count) {
        if (_numberOfRequiredArguments == 0) {
            return [NSString stringWithFormat:@"\"%@\" doesn't expect any arguments.", self._commandPath];
        } else {
            NSString *numberVerb = (NSInteger)(_numberOfRequiredArguments - count) > 0 ? @"expects" : @"requires";
            return [NSString stringWithFormat:@"\"%@\" %@ %@.", self._commandPath, numberVerb, [self _descriptionOfArgumentCount:_numberOfRequiredArguments]];
        }
    }
    
    return nil;
}

- (YDCommandReturnCode)run {
    NSArray<NSString*> *args = [[NSProcessInfo processInfo] arguments];
    args = [args subarrayWithRange:NSMakeRange(1, args.count-1)];
    
    return [self runWithArguments:args];
}

- (YDCommandReturnCode)runWithArguments:(NSArray<NSString*> *)arguments {
    @autoreleasepool {
        NSError *parseError = nil;
        NSString *issue = nil;
        
        // Scan variables
        if (![YDCommandVariableScanner scanVariables:_variables arguments:arguments extraArguments:&arguments error:&parseError]) {
            if ([parseError.domain isEqualToString:YDCommandErrorDomain] && parseError.code == YDCommandErrorCodeUnknownVariable) {
                // Print usage and return if the unrecognized variable is a help flag
                if ([parseError.userInfo[YDCommandVariableNameKey] ?: @"" isEqualToString:@"--help"]) {
                    [self appendUsageToOutput:YDStandardOut withVariables:YES];
                    return YDCommandReturnCodeOK;
                }
            }
            
            issue = parseError.localizedDescription;
        }
        
        // Assert argument count
        issue = issue ?: [self _describeIssueWithArgumentCount:arguments.count];
        
        if (issue != nil) {
            [YDStandardError appendFormat:@"%@\n\n", issue];
            [self appendUsageToOutput:YDStandardError withVariables:(parseError != nil)];
            
            return YDCommandReturnCodeInvalidArgs;
        }
    }
    
    return [self executeWithArguments:arguments];
}

@end

@implementation YDCommand(Subclass)

- (YDCommandTree *)root {
    YDCommandTree *parent = self.parent;
    return parent ? (parent.root ?: parent) : nil;
}

- (YDCommandReturnCode)executeWithArguments:(NSArray<NSString *> *)arguments {
    [NSException raise:NSInternalInconsistencyException format:@"*** -[%@ %@] must be implemented", self.className, NSStringFromSelector(_cmd)];
    return -1;
}

@end


@implementation YDCommandTree {
    NSMutableArray<YDCommand*> *_children;
    NSMutableDictionary<NSString*,YDCommand*> *_childrenDict;
    NSMutableDictionary<NSString*,NSString*> *_descriptions;
}

- (instancetype)init {
    self = [super init];
    if (self == nil)
        return nil;
    
    _children = [NSMutableArray array];
    _childrenDict = [NSMutableDictionary dictionary];
    _descriptions = [NSMutableDictionary dictionary];
    
    self.allowsMultipleArguments = YES;

    return self;
}

- (void)addCommand:(YDCommand *)child withName:(NSString *)name description:(NSString *)description {
    NSAssert(child.parent == nil, @"*** Command already belongs in tree");
    NSAssert(_childrenDict[name] == nil, @"*** Command with name %@ already exists", name);
    NSAssert(![name containsString:@" "], @"*** Command name cannot contain spaces.");
    
    _childrenDict[name] = child;
    _descriptions[name] = description;
    [_children addObject:child];
    
    [child _setParent:self];
}

- (NSArray<YDCommand *> *)commands {
    return [_children copy];
}

- (YDCommand *)commandWithPath:(NSString *)path {
    NSArray<NSString *> *components = [path ?: @"" componentsSeparatedByString:@" "];
    if (components.count == 0) {
        return nil;
    }
    
    NSString *name = [components firstObject];
    components = [components subarrayWithRange:NSMakeRange(1, components.count - 1)];
    
    YDCommand *command = _childrenDict[name];
    if (command == nil) {
        return nil;
    } else if ([command isKindOfClass:[YDCommandTree class]] && components.count > 0) {
        return [(YDCommandTree *)command commandWithPath:[components componentsJoinedByString:@" "]];
    } else {
        return command;
    }
}

- (NSString *)pathForCommand:(YDCommand *)command {
    for (NSString *key in _childrenDict) {
        if ([_childrenDict[key] isEqual:command]) {
            NSString *myPath = self.parent ? [self.parent pathForCommand:self] : nil;
            return myPath ? [myPath stringByAppendingFormat:@" %@", key] : key;
        }
    }
    
    return nil;
}

- (void)appendCommandsToOutput:(YDCommandOutput *)output {
    NSDictionary *descriptions = _descriptions;
    
    [output applyTabWidth:YDCommandTabWidth withinBlock:^(id<YDCommandOutputWriter> tabbedOutput) {
        for (NSString *commandName in [descriptions.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
            [tabbedOutput appendFormat:@"  %@\t%@\n", commandName, descriptions[commandName]];
        }
    }];
    
    [output appendString:@"\n"];
}

- (void)appendUsageToOutput:(YDCommandOutput *)output withVariables:(BOOL)includeVariables {
    [super appendUsageToOutput:output withVariables:includeVariables];
    
    [output appendString:@"\nCommands:\n"];
    [self appendCommandsToOutput:output];
}

- (YDCommandReturnCode)executeWithArguments:(NSArray<NSString *> *)arguments {
    NSString *commandName = [arguments firstObject];
    YDCommand *command = commandName ? [self commandWithPath:commandName] : nil;
    
    if (command == nil) {
        if (commandName != nil) {
            [YDStandardError appendFormat:@"Unrecognized command: %@\n", commandName];
            [YDStandardError appendString:@"\nAvailable commands:\n"];
            [self appendCommandsToOutput:YDStandardError];
            
            return YDCommandReturnCodeInvalidArgs;
        }
        
        [self appendUsageToOutput:YDStandardOut withVariables:YES];
        return YDCommandReturnCodeOK;
    }
    
    NSArray *commandArguments = [arguments subarrayWithRange:NSMakeRange(1, arguments.count-1)];
    return [command runWithArguments:commandArguments];
}

@end
