//
//  CustomKeyboard.h
//  CustomKeyboard
//
//  Created by liaopeikai on 2016/11/30.
//  Copyright © 2016年 beichende. All rights reserved.
//

#import <UIKit/UIKit.h>

// 为block重新起一个名字PasswordBlock,它有一个id类型的参数password
typedef void (^PasswordBlock) (id password);

@interface CustomKeyboard : UITextView

/**
 单例模式

 @return CustomKeyboard单例
 */
+ (instancetype)shareInstance ;


/**
 获取单个密码
 
 @param block 回传单个密码
 */
- (void)returnPasswordBlock:(PasswordBlock)block;


/**
 获取密码

 @return 一串密码
 */
- (NSString *)getPassword;


@end
