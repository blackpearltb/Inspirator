//
//  SBGestureTableViewCell.swift
//  SBGestureTableView-Swift
//
//  Created by Ben Nichols on 10/3/14 and modified by Tarang Khanna
//  Copyright (c) 2014 Stickbuilt. All rights reserved.
//

import UIKit


class SBGestureTableViewCell: MKTableViewCell, UITextViewDelegate {

    var actionIconsFollowSliding = true
    var actionIconsMargin: CGFloat = 20.0
    var actionNormalColor = UIColor(white: 0.85, alpha: 1)

    
    var leftSideView = SBGestureTableViewCellSideView()
    var rightSideView = SBGestureTableViewCellSideView()
    
    var firstLeftAction: SBGestureTableViewCellAction? {
        didSet {
            if (firstLeftAction?.fraction == 0) {
                firstLeftAction?.fraction = 0.3
            }
        }
    }
    var secondLeftAction: SBGestureTableViewCellAction? {
        didSet {
            if (secondLeftAction?.fraction == 0) {
                secondLeftAction?.fraction = 0.7
            }
        }
    }
    var firstRightAction: SBGestureTableViewCellAction? {
        didSet {
            if (firstRightAction?.fraction == 0) {
                firstRightAction?.fraction = 0.3
            }
        }
    }
    var secondRightAction: SBGestureTableViewCellAction? {
        didSet {
            if (secondRightAction?.fraction == 0) {
                secondRightAction?.fraction = 0.7
            }
        }
    }
    var currentAction: SBGestureTableViewCellAction?
    override var center: CGPoint {
        get {
            return super.center
        }
        set {
            super.center = newValue
            updateSideViews()
        }
    }
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue
            updateSideViews()
        }
    }
    private var gestureTableView: SBGestureTableView!
    private let panGestureRecognizer = UIPanGestureRecognizer()
    
    func setup() {
        panGestureRecognizer.addTarget(self, action: "slideCell:")
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    override func didMoveToSuperview() {
        gestureTableView = superview?.superview as? SBGestureTableView
    }
    
    func percentageOffsetFromCenter() -> (Double) {
        let diff = fabs(frame.size.width/2 - center.x);
        return Double(diff / frame.size.width);
    }
    
    func percentageOffsetFromEnd() -> (Double) {
        let diff = fabs(frame.size.width/2 - center.x);
        return Double((frame.size.width - diff) / frame.size.width);
    }
    
    override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKindOfClass(UIPanGestureRecognizer) {
            let panGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            let velocity = panGestureRecognizer.velocityInView(self)
            let horizontalLocation = panGestureRecognizer.locationInView(self).x
            if fabs(velocity.x) > fabs(velocity.y)
                && horizontalLocation > CGFloat(gestureTableView.edgeSlidingMargin)
                && horizontalLocation < frame.size.width - CGFloat(gestureTableView.edgeSlidingMargin)
                && gestureTableView.isEnabled {
                    return true;
            }
        } else if gestureRecognizer.isKindOfClass(UILongPressGestureRecognizer) {
            if gestureTableView.didMoveCellFromIndexPathToIndexPathBlock == nil {
                return true;
            }
        }
        return false;
    }
    
    func actionForCurrentPosition() -> SBGestureTableViewCellAction? {
        let fraction = fabs(frame.origin.x/frame.size.width)
        if frame.origin.x > 0 {
            if secondLeftAction != nil && fraction > secondLeftAction!.fraction {
                return secondLeftAction!
            } else if firstLeftAction != nil && fraction > firstLeftAction!.fraction {
                return firstLeftAction!
            }
        } else if frame.origin.x < 0 {
            if secondRightAction != nil && fraction > secondRightAction!.fraction {
                return secondRightAction!
            } else if firstRightAction != nil && fraction > firstRightAction!.fraction {
                return firstRightAction!
            }
        }
        return nil
    }
    
    func performChanges() {
        let action = actionForCurrentPosition()
        if let action = action {
            if frame.origin.x > 0 {
                leftSideView.backgroundColor = action.color
                leftSideView.iconImageView.image = action.icon
            } else if frame.origin.x < 0 {
                rightSideView.backgroundColor = action.color
                rightSideView.iconImageView.image = action.icon
            }
        } else {
            if frame.origin.x > 0 {
                leftSideView.backgroundColor = actionNormalColor
                leftSideView.iconImageView.image = firstLeftAction!.icon
            } else if frame.origin.x < 0 {
                rightSideView.backgroundColor = actionNormalColor
                rightSideView.iconImageView.image = firstRightAction!.icon
            }
        }
        if let image = leftSideView.iconImageView.image {
            leftSideView.iconImageView.alpha = frame.origin.x / (actionIconsMargin*2 + image.size.width)
        }
        if let image = rightSideView.iconImageView.image {
            rightSideView.iconImageView.alpha = -(frame.origin.x / (actionIconsMargin*2 + image.size.width))
        }
        if currentAction != action {
            action?.didHighlightBlock?(gestureTableView, self)
            currentAction?.didUnhighlightBlock?(gestureTableView, self)
            currentAction = action
        }
    }
    
    func hasAnyLeftAction() -> Bool {
        return firstLeftAction != nil || secondLeftAction != nil
    }

    func hasAnyRightAction() -> Bool {
        return firstRightAction != nil || secondRightAction != nil
    }

    func setupSideViews() {
        leftSideView.iconImageView.contentMode = actionIconsFollowSliding ? UIViewContentMode.Right : UIViewContentMode.Left
        rightSideView.iconImageView.contentMode = actionIconsFollowSliding ? UIViewContentMode.Left : UIViewContentMode.Right
        superview?.insertSubview(leftSideView, atIndex: 0)
        superview?.insertSubview(rightSideView, atIndex: 0)
    }

    func slideCell(panGestureRecognizer: UIPanGestureRecognizer) {
        if !hasAnyLeftAction() || !hasAnyRightAction() {
            return
        }
        var horizontalTranslation = panGestureRecognizer.translationInView(self).x
        if panGestureRecognizer.state == UIGestureRecognizerState.Began {
            setupSideViews()
        } else if panGestureRecognizer.state == UIGestureRecognizerState.Changed {
            if (!hasAnyLeftAction() && frame.size.width/2 + horizontalTranslation > frame.size.width/2)
                || (!hasAnyRightAction() && frame.size.width/2 + horizontalTranslation < frame.size.width/2) {
                    horizontalTranslation = 0
            }
            performChanges()
            center = CGPointMake(frame.size.width/2 + horizontalTranslation, center.y)
        } else if panGestureRecognizer.state == UIGestureRecognizerState.Ended {
            if (currentAction == nil && frame.origin.x != 0) || !gestureTableView.isEnabled {
                gestureTableView.cellReplacingBlock?(gestureTableView, self)
            } else {
                currentAction?.didTriggerBlock(gestureTableView, self)
            }
            currentAction = nil
        }
    }
    
    func updateSideViews() {
        leftSideView.frame = CGRectMake(0, frame.origin.y, frame.origin.x, frame.size.height)
        if let image = leftSideView.iconImageView.image {
            leftSideView.iconImageView.frame = CGRectMake(actionIconsMargin, 0, max(image.size.width, leftSideView.frame.size.width - actionIconsMargin*2), leftSideView.frame.size.height)
        }
        rightSideView.frame = CGRectMake(frame.origin.x + frame.size.width, frame.origin.y, frame.size.width - (frame.origin.x + frame.size.width), frame.size.height)
        if let image = rightSideView.iconImageView.image {
            rightSideView.iconImageView.frame = CGRectMake(rightSideView.frame.size.width - actionIconsMargin, 0, min(-image.size.width, actionIconsMargin*2 - rightSideView.frame.size.width), rightSideView.frame.size.height)
        }
    }
    
    
    @IBOutlet var typeImageView : UIImageView!
    @IBOutlet var profileImageView : UIImageView!
    @IBOutlet var dateImageView : UIImageView!
    @IBOutlet var photoImageView : UIImageView?
    
    @IBOutlet var nameLabel : UILabel!
    
    @IBOutlet var postLabel: UITextView!
    @IBOutlet var dateLabel : UILabel!
    
    @IBOutlet var scoreLabel: UILabel!

    
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var upvoteButton: SpringButton!
    @IBOutlet weak var downVoteButton: SpringButton!
    
    @IBOutlet weak var commentButton: SpringButton!
    weak var delegate: SBGestureTableViewCellDelegate?
    
    @IBAction func upvoteButtonDidTouch(sender: AnyObject) {
        upvoteButton.animation = "pop"
        upvoteButton.force = 3
        upvoteButton.animate()
        delegate?.storyTableViewCellDidTouchUpvote(self, sender: sender)
    }
    
    @IBAction func downvoteButtonDidTouch(sender: AnyObject) {
        downVoteButton.animation = "pop"
        downVoteButton.force = 3
        downVoteButton.animate()
        delegate?.storyTableViewCellDidTouchUpvote(self, sender: sender)
    }
    
    override func awakeFromNib() {
        
        //dateImageView.image = UIImage(named: "clock")
        profileImageView.layer.cornerRadius = 30
        
        nameLabel.font = UIFont(name: "Avenir-Book", size: 16)
        nameLabel.textColor = UIColor.blackColor()
        
        postLabel?.font = UIFont(name: "Avenir-Book", size: 14)
        postLabel?.textColor = UIColor(white: 0.6, alpha: 1.0)
        
        dateLabel.font = UIFont(name: "Avenir-Book", size: 14)
        dateLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
        
        scoreLabel.font = UIFont(name: "Avenir-Book", size: 14)
        scoreLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
    }
    
    
    func textViewDidChange(textView: UITextView) { //Handle the text changes here
        print(textView.text); //the textView parameter is the textView where text was changed
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if postLabel != nil {
            //let label = postLabel!
            
            //label.preferredMaxLayoutWidth = CGRectGetWidth(label.frame)
        }
        
        if scoreLabel != nil {
            let label = scoreLabel!
            label.preferredMaxLayoutWidth = CGRectGetWidth(label.frame)
        }
    }
    
}

func textView(textView: UITextView!, shouldInteractWithURL URL: NSURL!, inRange characterRange: NSRange) -> Bool {
    
    return true
    
}

protocol SBGestureTableViewCellDelegate: class {
    func storyTableViewCellDidTouchUpvote(cell: SBGestureTableViewCell, sender: AnyObject)
    func storyTableViewCellDidTouchComment(cell: SBGestureTableViewCell, sender: AnyObject)
}