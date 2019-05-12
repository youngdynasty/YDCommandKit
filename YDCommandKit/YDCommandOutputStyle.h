//
//  YDCommandOutputStyle.h
//  emporter-cli
//
//  Created by Mikey on 25/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! Attributes used to style output for YDCommandOutput. */
typedef NSUInteger YDCommandOutputStyle;

/*!
 A shared variable which can be used to disable colors, rendering all style output to be unaffected. Use this to disable styles/colors.
 */
extern BOOL YDCommandOutputStyleDisabled;

/*! Colors used to define foreground/background colors */
typedef NS_ENUM(uint8, YDCommandOutputStyleColor) {
    YDCommandOutputStyleColorInherit,
    
    YDCommandOutputStyleColorBlack,
    YDCommandOutputStyleColorRed,
    YDCommandOutputStyleColorGreen,
    YDCommandOutputStyleColorYellow,
    YDCommandOutputStyleColorBlue,
    YDCommandOutputStyleColorMagenta,
    YDCommandOutputStyleColorCyan,
    YDCommandOutputStyleColorWhite
};

/*! Text attributes */
typedef NS_ENUM(uint8, YDCommandOutputStyleAttribute) {
    YDCommandOutputStyleAttributeInherit,
    
    YDCommandOutputStyleAttributeNormal,
    YDCommandOutputStyleAttributeBold,
    YDCommandOutputStyleAttributeUnderline = 5,
    YDCommandOutputStyleAttributeInvert = 8
};

/*! Define a style with the given foreground color (background/text attributes will be inherited) */
static inline YDCommandOutputStyle YDCommandOutputStyleWithForegroundColor(YDCommandOutputStyleColor c) { return (c << 24); }

/*! Define a style with the given background color (foreground/text attributes will be inherited)*/
static inline YDCommandOutputStyle YDCommandOutputStyleWithBackgroundColor(YDCommandOutputStyleColor c) { return (c << 16); }

/*! Define a style with the given text attribute (background/foreground colors will be inherited)*/
static inline YDCommandOutputStyle YDCommandOutputStyleWithAttribute(YDCommandOutputStyleAttribute c) { return (c << 8); }

/* Define a style with the given foreground, background and text attributes. */
static inline YDCommandOutputStyle YDCommandOutputStyleMake(YDCommandOutputStyleColor foreground, YDCommandOutputStyleColor background, YDCommandOutputStyleAttribute attrs) {
    return (foreground << 24) + (background << 16) + (attrs << 8);
}

/*! Get the foreground color for a style */
static inline YDCommandOutputStyleColor YDCommandOutputStyleGetForegroundColor(YDCommandOutputStyle style) { return (style & 0xFF000000) >> 24; }

/*! Get the background color for a style */
static inline YDCommandOutputStyleColor YDCommandOutputStyleGetBackgroundColor(YDCommandOutputStyle style) { return (style & 0xFF0000) >> 16; }

/*! Get the text attribute for a style */
static inline YDCommandOutputStyleAttribute YDCommandOutputStyleGetAttribute(YDCommandOutputStyle style) { return (style & 0xFF00) >> 8; }


#pragma mark -

/* Blend two styles together such that inherited attributes are derived from a parent */
static inline YDCommandOutputStyle YDCommandStyleBlend(YDCommandOutputStyle style, YDCommandOutputStyle parent) {
    return YDCommandOutputStyleMake(YDCommandOutputStyleGetForegroundColor(style) ?: YDCommandOutputStyleGetForegroundColor(parent),
                                    YDCommandOutputStyleGetBackgroundColor(style) ?: YDCommandOutputStyleGetBackgroundColor(parent),
                                    YDCommandOutputStyleGetAttribute(style) ?: YDCommandOutputStyleGetAttribute(parent));
}

/*! Return the ANSI escaped string for style. For non-lossy results, styles should be blended if there is a parent style being applied. */
extern NSString* YDCommandOutputStyleString(YDCommandOutputStyle style);

/*! Return the output style for the ANSI-escaped string. */
extern YDCommandOutputStyle YDCommandOutputStyleFromString(NSString *string);

/*!
 Enumerate through a string to find plaintext / style attributes.
 
 The block's style parameter will be nil if the substring is not an ANSI-escaped string which represents a style.
 */
void YDCommandOutputStyleStringEnumerateUsingBlock(NSString *string, void(^block)(NSString *substring, YDCommandOutputStyle *__nullable style, BOOL *stop));

NS_ASSUME_NONNULL_END
