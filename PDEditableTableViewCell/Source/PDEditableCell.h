//
//  PDEditableCell.h
//  PDEditableCell
//
//  Created by liang on 2020/1/19.
//  Copyright © 2020 liang. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PDEditableCell, PDEditableCellItemAction, PDEditableCellItemCreator, PDEditableCellItemLayouter;

typedef UIControl PDEditableCellItem;

UIKIT_EXTERN CGFloat const PDEditableCellItemFillHeight; // If you want the height of the item to be the same as the cell, use `PDEditableCellItemFillHeight`.

@protocol PDEditableCellDelegate <NSObject>

@optional
- (void)panGestureRecognizerStateBeginInEditableCell:(__kindof PDEditableCell *)editableCell;
- (void)panGestureRecognizerStateChangedInEditableCell:(__kindof PDEditableCell *)editableCell;
- (void)panGestureRecognizerStateEndedInEditableCell:(__kindof PDEditableCell *)editableCell;

- (void)willBecomeEditingInCell:(__kindof PDEditableCell *)editableCell;
- (void)didBecomeEditingInCell:(__kindof PDEditableCell *)editableCell;

- (void)willResignEditingInCell:(__kindof PDEditableCell *)editableCell;
- (void)didResignEditingInCell:(__kindof PDEditableCell *)editableCell;

@end

@interface PDEditableCell : UITableViewCell

@property (nonatomic, weak) id<PDEditableCellDelegate> delegate;

@property (nonatomic, readonly) UIView *itemsContainerView;
@property (nonatomic, readonly) UIView *containerView;
@property (nonatomic, readonly) NSArray<PDEditableCellItemAction *> *actions;

@property (nonatomic, assign) UIEdgeInsets edgeInsets;
@property (nonatomic, assign) BOOL editEnabled;

- (void)addActions:(NSArray<PDEditableCellItemAction *> *)actions;

- (void)becomeEditingWithAnimated:(BOOL)animated;
- (void)resignEditingWithAnimated:(BOOL)animated;

@end

@interface PDEditableCellItemAction : NSObject

+ (instancetype)actionWithCreator:(PDEditableCellItemCreator *)creator
                         layouter:(PDEditableCellItemLayouter *)layouter
                          handler:(void (^)(void))handler;

@end

@interface PDEditableCellItemCreator : NSObject

- (void)createEditableCellItemWithBlock:(__kindof PDEditableCellItem * (^)(NSUInteger index))block;

@end

@interface PDEditableCellItemLayouter : NSObject

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) UIEdgeInsets edgeInsets;

@end

NS_ASSUME_NONNULL_END
