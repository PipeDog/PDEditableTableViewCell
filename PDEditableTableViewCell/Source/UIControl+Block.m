//
//  UIControl+Block.m
//  PDControlBlock
//
//  Created by liang on 2018/10/8.
//  Copyright © 2018 PipeDog. All rights reserved.
//

#import "UIControl+Block.h"
#import <objc/runtime.h>

@interface PDActionWrapper : NSObject

@property (nonatomic, copy) void (^block)(__kindof UIControl *);
@property (nonatomic, assign) UIControlEvents controlEvents;

- (void)triggerAction:(id)sender;

@end

@implementation PDActionWrapper

- (void)triggerAction:(id)sender {
    !self.block ?: self.block(sender);
}

@end

@interface UIControl ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<PDActionWrapper *> *> *allWrappers;

@end

@implementation UIControl (Block)

- (void)addActionForControlEvents:(UIControlEvents)controlEvents usingBlock:(void (^)(__kindof UIControl * _Nonnull))block {
    
    NSAssert(block, @"Param block can not be nil!");
    
    NSMutableArray<PDActionWrapper *> *wrappersForControlEvents = self.allWrappers[@(controlEvents)];
    if (!wrappersForControlEvents) {
        wrappersForControlEvents = [NSMutableArray array];
    }
    
    PDActionWrapper *wrapper = [[PDActionWrapper alloc] init];
    wrapper.block = block;
    wrapper.controlEvents = controlEvents;
    [self addTarget:wrapper action:@selector(triggerAction:) forControlEvents:controlEvents];
    
    [wrappersForControlEvents addObject:wrapper];
    self.allWrappers[@(controlEvents)] = wrappersForControlEvents;
}

- (void)removeActionsForControlEvents:(UIControlEvents)controlEvents {
    
    NSMutableArray<PDActionWrapper *> *wrappersForControlEvents = self.allWrappers[@(controlEvents)];
    if (!wrappersForControlEvents.count) { return; }

    for (PDActionWrapper *wrapper in wrappersForControlEvents) {
        [self removeTarget:wrapper action:@selector(triggerAction:) forControlEvents:wrapper.controlEvents];
    }
    
    [wrappersForControlEvents removeAllObjects];
}

- (void)removeAllActions {
    NSArray<NSNumber *> *allKeys = [self.allWrappers.allKeys copy];
    
    for (NSNumber *controlEvents in allKeys) {
        NSArray<PDActionWrapper *> *wrappers = [self.allWrappers[controlEvents] copy];
        
        for (PDActionWrapper *wrapper in wrappers) {
            [self removeTarget:wrapper action:@selector(triggerAction:) forControlEvents:[controlEvents unsignedIntegerValue]];
        }
    }
    
    [self.allWrappers removeAllObjects];
}

#pragma mark - Getter Methods
- (NSMutableDictionary<NSNumber *,NSMutableArray<PDActionWrapper *> *> *)allWrappers {
    NSMutableDictionary *_allWrappers = objc_getAssociatedObject(self, _cmd);
    if (!_allWrappers) {
        _allWrappers = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, _allWrappers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return _allWrappers;
}

@end
