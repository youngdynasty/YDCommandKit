#  YDCommandKit

A versatile, modular library for building command-line apps.

## Background / Features

While developing the [command-line interface](https://github.com/youngdynasty/emporter-cli) to [Emporter.app](https://emporter.app), I really wanted a simple library to build a high quality, easy-to-use tool with modest styling requirements. I needed to be able to:

1. Parse command-line arguments in a type-safe way
2. Compose multiple small, easy-to-understand commands
3. Output colored text
4. Output tables of dynamic data with consistent widths
5. Ship a fully self-contained binary (not an app bundle)
6. Testable

Using Swift wasn't a viable option because of its lack of support for static libraries and ABI instability. Again, the goal here was to ship a single executable.

To my dismay, there weren't simply any options. After crying a little on the inside, I decided that I wouldn't let this happen to anyone, ever again. And here we are.

## Documentation

The main header [YDCommandKit.h](/YDCommandKit/YDCommandKit.h) integrates with Xcode's Quick Help. After importing `YDCommandKit` into your project, you should be able navigate through the documentation when referencing the `YD` namespace.

The headers are really helpful, too. The main ones to pay attention to are:

- [YDCommand.h](/YDCommandKit/YDCommand.h) / [YDCommand-Subclass.h](/YDCommandKit/YDCommand-Subclass.h) 
- [YDCommandOutput.h](/YDCommandKit/YDCommandOutput.h) and [YDCommandOutputStyle.h](/YDCommandKit/YDCommandOutputStyle.h)
- [YDCommandVariable.h](/YDCommandKit/YDCommandVariable.h)

You can check out the source to [emporter-cli](https://github.com/youngdynasty/emporter-cli) to see every feature within `YDCommandKit` used extensively. Each command is implemented in its own file and should be pretty easy to follow. It even has a custom class for drawing terminal windows using the APIs from this package. A great deal of effort went into making a minimal API without too many assumptions with how it should be used.

### Examples

#### Argument parsing

```objc

int main(int argc, const char * argv[]) {
   int result = 0;
   @autoreleasepool {
      result = [[MainCommand new] run];
   }
   return result;
}

@interface MainCommand : YDCommand @end

@implementation MainCommand : NSObject {
   NSString *_foo;
}

- (instancetype)init {
   self = [super init];
   if (self == nil) return nil;

   self.usage = @"[OPTIONS] [ARGS...]";
   self.variables = @[[YDCommandVariable string:&_foo name:@"--foo" usage:@"Wow, type safety!"]];
   self.allowsMultipleArguments = YES;

   return self;
}

- (YDCommandReturnCode)executeWithArguments:(NSArray<NSString*>*)args {
   [YDStandardOut appendFormat:@"Foo = %@; args = %@\n", _foo, args];
   return YDCommandReturnCodeOK;
}

```

`app --foo bar a b c` would output `Foo = bar; args = (a,b,c)`

It's worth noting that `--foo=bar` is perfectly acceptable, and you can define aliases for variables so that `-f bar` would work, too. It'd look something like this:

```objc
[[YDCommandVariable string:&_foo name:@"--foo" usage:@"Wow, type safety!"] variableWithAlias:@"-f"]
```

#### Colored output

```objc
YDCommandOutputStyle redForeground = YDCommandOutputStyleWithForegroundColor(YDCommandOutputStyleRedColor);
YDCommandOutputStyle blueBackground = YDCommandOutputStyleWithBackgroundColor(YDCommandOutputStyleBlueColor);

[YDStandardOut applyStyle:redForeground withinBlock:^(id<YDCommandOutputWriter> output) { 
   [output appendString:@"I'm red "];

   // Style blocks are nestable and support inheritance
   [output applyStyle:blueBackground withinBlock:^(id<YDCommandOutputWriter> output) {
      [output appendString:@"and blue"];
   }];
}];
```

You don't have to nest blocks whenever you have "complex" styles. `YDCommandOutputStyleMake` lets you define a foreground/background color, with text attributes, which can be applied in one block.

## Installation

### The "right" way
1. Add `YDCommandKit.xcodeproj` to your Xcode project or workspace
2. Add a dependency to your target (Build Phases > Target Dependencies) to `libYDCommandKit.a`
3. Link `libEmporterKit.a` to your target (Build Phases > Link Binary With Libraries)
4. Update your project build settings
   1. Add `YDCommandKit/**` to _Header Search Paths_
   2. Add `-lstdc++` to _Other Linker Flags_
5. `#import "YDCommandKit.h"` and make something awesome!

### The "ain't nobody got time for that" way

Add all files from `YDCommandKit/` to your target.

### CocoaPods / Carthage

I'm not a CocoaPods / Carthage user, but feel free to make a pull request to add support for either.

## License

BSD 3 Clause. See [LICENSE](https://github.com/youngdynasty/YDCommandKit/blob/master/LICENSE).

---

(c) 2019 [Young Dynasty](https://youngdynasty.net)
