//
//  UIControl+Block.h
//  PDControlBlock
//
//  Created by liang on 2018/10/8.
//  Copyright © 2018 PipeDog. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIControl (Block)

- (void)addActionForControlEvents:(UIControlEvents)controlEvents usingBlock:(void (^)(__kindof UIControl *control))block;

- (void)removeActionsForControlEvents:(UIControlEvents)controlEvents;

- (void)removeAllActions;

@end

NS_ASSUME_NONNULL_END
