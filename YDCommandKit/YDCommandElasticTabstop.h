//
//  YDCommandElasticTabstop.h
//  emporter-cli
//
//  Created by Mikey on 22/04/2019.
//  Copyright © 2019 Young Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __cplusplus
extern "C" {
#endif
    
/*!
 Convert tabs to elastic tabstops for well-aligned output.
 
 See http://nickgravgaard.com/elastic-tabstops/ for some background information.
 
 \param data        UTF-8 encoded data to convert
 \param tabWidth    Convert tabs to this width
 
 \returns UTF-8 data with evenly spaced tabs
 */
NSData *__nonnull YDCommandElasticTabstopUTF8Data(NSData *__nonnull data, NSUInteger tabWidth);
    
/*!
 Convert tabs to elastic tabstops for well-aligned output.
 
 See http://nickgravgaard.com/elastic-tabstops/ for some background information.
 
 \param input       A string to convert
 \param tabWidth    Convert tabs to this width
 
 \returns A string with evenly spaced tabs
*/
NSString *__nonnull YDCommandElasticTabstopString(NSString *__nonnull input, NSUInteger tabWidth);

#if __cplusplus
}
#endif
