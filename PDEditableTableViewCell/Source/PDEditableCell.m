//
//  PDEditableCell.m
//  PDEditableCell
//
//  Created by liang on 2020/1/19.
//  Copyright © 2020 liang. All rights reserved.
//

#import "PDEditableCell.h"
#import <Masonry/Masonry.h>
#import "UIControl+Block.h"

CGFloat const PDEditableCellItemFillHeight = CGFLOAT_MAX;

@implementation PDEditableCellItemAction {
    @public
    PDEditableCellItemCreator *_creator;
    PDEditableCellItemLayouter *_layouter;
    void (^_handler)(void);
}

+ (instancetype)actionWithCreator:(PDEditableCellItemCreator *)creator
                         layouter:(PDEditableCellItemLayouter *)layouter
                          handler:(void (^)(void))handler {
    PDEditableCellItemAction *action = [[PDEditableCellItemAction alloc] init];
    action->_creator = creator;
    action->_layouter = layouter;
    action->_handler = handler;
    return action;
}

@end

@implementation PDEditableCellItemCreator {
    @public
    __kindof PDEditableCellItem * (^_createEditableCellItemBlock)(NSUInteger);
}

- (void)createEditableCellItemWithBlock:(__kindof PDEditableCellItem * _Nonnull (^)(NSUInteger))block {
    if (block) {
        _createEditableCellItemBlock = [block copy];
    }
}

@end

@implementation PDEditableCellItemLayouter

@end

@interface PDEditableCell () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *itemsContainerView;
@property (nonatomic, strong) NSMutableArray<PDEditableCellItemAction *> *holder;
@property (nonatomic, assign) BOOL inEditing; // If YES, become edit, else resign edit.
@property (nonatomic, strong) NSMutableArray<PDEditableCellItem *> *items;
@property (nonatomic, assign) CGFloat itemsWidth;
@property (nonatomic, strong) UIPanGestureRecognizer *pan;

@end

@implementation PDEditableCell

@synthesize containerView = _containerView;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self _commitInit];
        [self _createViewHierarchy];
        [self _layoutContentViews];
    }
    return self;
}

- (void)_commitInit {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _edgeInsets = UIEdgeInsetsZero;
    self.editEnabled = YES;
}

- (void)_createViewHierarchy {
    [self.contentView addSubview:self.itemsContainerView];
    [self.contentView addSubview:self.containerView];
}

- (void)_layoutContentViews {
    [self.itemsContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.edgeInsets.top);
        make.left.mas_equalTo(self.edgeInsets.left);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-self.edgeInsets.bottom);
        make.right.equalTo(self.contentView.mas_right).offset(-self.edgeInsets.right);
    }];
    
    [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.edgeInsets.top);
        make.left.mas_equalTo(self.edgeInsets.left);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-self.edgeInsets.bottom);
        make.right.equalTo(self.contentView.mas_right).offset(-self.edgeInsets.right);
    }];
}

#pragma mark - Public Methods
- (void)addActions:(NSArray<PDEditableCellItemAction *> *)actions {
    NSAssert(!self.inEditing, @"Can not add action when become editing state!");
    if (!actions.count) { return; }
    
    [self.holder addObjectsFromArray:actions];
    [self _updateItemsLayoutConstraints];
}

- (void)becomeEditingWithAnimated:(BOOL)animated {
    if (!self.editEnabled) { return; }
    _inEditing = YES;

    void (^frameBlock)(void) = ^{
        [self _setLeft:(self.edgeInsets.left - self.itemsWidth) forView:self.containerView];
    };
    
    void (^layoutBlock)(void) = ^{
        [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.edgeInsets.top);
            make.left.mas_equalTo((self.edgeInsets.left - self.itemsWidth));
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-self.edgeInsets.bottom);
            make.right.equalTo(self.contentView.mas_right).offset(-self.edgeInsets.right - self.itemsWidth);
        }];
    };
    
    if ([self.delegate respondsToSelector:@selector(willBecomeEditingInCell:)]) {
        [self.delegate willBecomeEditingInCell:self];
    }
    
    if (animated) {
        NSTimeInterval duration = (self.itemsWidth / 200.f) * 0.3f;
        [UIView animateWithDuration:duration animations:frameBlock completion:^(BOOL finished) {
            layoutBlock();
        }];
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        frameBlock();
        [CATransaction commit];
                
        layoutBlock();
    }
    
    if ([self.delegate respondsToSelector:@selector(didBecomeEditingInCell:)]) {
        [self.delegate didBecomeEditingInCell:self];
    }
}

- (void)resignEditingWithAnimated:(BOOL)animated {
    if (!self.editEnabled) { return; }
    _inEditing = NO;
    
    void (^frameBlock)(void) = ^{
        [self _setLeft:self.edgeInsets.left forView:self.containerView];
    };
    
    void (^layoutBlock)(void) = ^{
        [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.edgeInsets.top);
            make.left.mas_equalTo(self.edgeInsets.left);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-self.edgeInsets.bottom);
            make.right.equalTo(self.contentView.mas_right).offset(-self.edgeInsets.right);
        }];
    };
    
    if ([self.delegate respondsToSelector:@selector(willResignEditingInCell:)]) {
        [self.delegate willResignEditingInCell:self];
    }
    
    if (animated) {
        NSTimeInterval duration = (self.itemsWidth / 200.f) * 0.3f;
        [UIView animateWithDuration:duration animations:frameBlock completion:^(BOOL finished) {
            layoutBlock();
        }];
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        frameBlock();
        [CATransaction commit];
        
        layoutBlock();
    }
    
    if ([self.delegate respondsToSelector:@selector(didResignEditingInCell:)]) {
        [self.delegate didResignEditingInCell:self];
    }
}

#pragma mark - Tool Methods
- (void)_updateItemsLayoutConstraints {
    if (!self.holder.count) { return; }
    
    PDEditableCellItemAction    *previousAction,    *currentAction;
    PDEditableCellItemLayouter  *previousLayouter,  *currentLayouter;
    PDEditableCellItem          *previousItem,      *currentItem; // Be created by creator.
    
    for (NSUInteger i = 0; i < self.holder.count; i++) {
        currentAction   = self.holder[i];
        currentLayouter = currentAction->_layouter;
        currentItem     = currentAction->_creator->_createEditableCellItemBlock(i);

        [currentItem removeActionsForControlEvents:UIControlEventTouchUpInside];
        [currentItem addActionForControlEvents:UIControlEventTouchUpInside usingBlock:^(__kindof UIControl * _Nonnull control) {
            !currentAction->_handler ?: currentAction->_handler();
        }];

        self.itemsWidth += (currentLayouter.edgeInsets.left +
                            currentLayouter.size.width +
                            currentLayouter.edgeInsets.right);
        [self.itemsContainerView addSubview:currentItem];
        
        [currentItem mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(currentLayouter.size.width);

            if (currentLayouter.size.height == PDEditableCellItemFillHeight) {
                make.height.equalTo(self.itemsContainerView.mas_height);
            } else {
                make.height.mas_equalTo(currentLayouter.size.height);
            }

            make.top.mas_equalTo(currentLayouter.edgeInsets.top);
            
            if (previousItem) {
                CGFloat itemSpacing = currentLayouter.edgeInsets.right + previousLayouter.edgeInsets.left;
                make.right.equalTo(previousItem.mas_left).offset(-itemSpacing);
            } else {
                make.right.equalTo(self.itemsContainerView.mas_right).offset(-currentLayouter.edgeInsets.right);
            }
        }];

        previousAction   = currentAction;
        previousLayouter = currentLayouter;
        previousItem     = currentItem;
    }
}

- (BOOL)_shouldRespondPanGestureWithOffset:(CGPoint)offset {
    CGFloat x = fabs(offset.x);
    return (x >= 10.f) && (fabs(offset.x) > 3 * fabs(offset.y));
}

- (void)_setLeft:(CGFloat)left forView:(UIView *)aView {
    aView.frame = CGRectMake(left, CGRectGetMinY(aView.frame), CGRectGetWidth(aView.frame), CGRectGetHeight(aView.frame));
}

#pragma mark - Gesture Methods
- (void)_receivePanGesture:(UIPanGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            [self _panGestureRecognizerBegan:sender];
        } break;
        case UIGestureRecognizerStateChanged: {
            [self _panGestureRecognizerChanged:sender];
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            [self _panGestureRecognizerEnded:sender];
        } break;
        default: break;
    }
}

- (void)_panGestureRecognizerBegan:(UIPanGestureRecognizer *)sender {
    if ([self.delegate respondsToSelector:@selector(panGestureRecognizerStateBeginInEditableCell:)]) {
        [self.delegate panGestureRecognizerStateBeginInEditableCell:self];
    }
}

- (void)_panGestureRecognizerChanged:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender translationInView:self.contentView];
    if (![self _shouldRespondPanGestureWithOffset:point]) {
        return;
    }

    CGFloat originLeft = self.inEditing ? (self.edgeInsets.left - self.itemsWidth) : self.edgeInsets.left;
    CGFloat currentLeft = originLeft + point.x;
    
    if (currentLeft > self.edgeInsets.left) {
        [self _setLeft:self.edgeInsets.left forView:self.containerView];
    } else if (currentLeft < self.edgeInsets.left - self.itemsWidth) {
        [self _setLeft:(self.edgeInsets.left - self.itemsWidth) forView:self.containerView];
    } else {
        [self _setLeft:currentLeft forView:self.containerView];
    }
    
    if ([self.delegate respondsToSelector:@selector(panGestureRecognizerStateChangedInEditableCell:)]) {
        [self.delegate panGestureRecognizerStateChangedInEditableCell:self];
    }
}

- (void)_panGestureRecognizerEnded:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender translationInView:self];
    
    if (self.inEditing && point.x > 0) {
        [self _shouldRespondPanGestureWithOffset:point] ? [self resignEditingWithAnimated:YES] : [self becomeEditingWithAnimated:YES];
    } else if (!self.inEditing && point.x < 0) {
        [self _shouldRespondPanGestureWithOffset:point] ? [self becomeEditingWithAnimated:YES] : [self resignEditingWithAnimated:YES];
    }
    
    if ([self.delegate respondsToSelector:@selector(panGestureRecognizerStateEndedInEditableCell:)]) {
        [self.delegate panGestureRecognizerStateEndedInEditableCell:self];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isEqual:self.pan]) {
        CGPoint point = [self.pan translationInView:self];
        if ([self _shouldRespondPanGestureWithOffset:point]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - Setter Methods
- (void)setEditEnabled:(BOOL)editEnabled {
    _editEnabled = editEnabled;
    
    if (_editEnabled) {
        [self.contentView addGestureRecognizer:self.pan];
        self.itemsContainerView.hidden = NO;
    } else {
        [self.contentView removeGestureRecognizer:self.pan];
        self.itemsContainerView.hidden = YES;
    }
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets {
    _edgeInsets = edgeInsets;
    [self _layoutContentViews];
}

#pragma mark - Getter Methods
- (NSMutableArray<PDEditableCellItemAction *> *)holder {
    if (!_holder) {
        _holder = [NSMutableArray array];
    }
    return _holder;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor whiteColor];
    }
    return _containerView;
}

- (UIView *)itemsContainerView {
    if (!_itemsContainerView) {
        _itemsContainerView = [[UIView alloc] init];
        _itemsContainerView.backgroundColor = [UIColor whiteColor];
        _itemsContainerView.clipsToBounds = YES;
    }
    return _itemsContainerView;
}

- (NSMutableArray<PDEditableCellItem *> *)items {
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}

- (UIPanGestureRecognizer *)pan {
    if (!_pan) {
        _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_receivePanGesture:)];
        _pan.delegate = self;
    }
    return _pan;
}

@end
