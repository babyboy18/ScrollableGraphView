
import UIKit

open class Plot {
    
    // The id for this plot. Used when determining which data to give it in the dataSource
    open var identifier: String!
    
    weak var graphViewDrawingDelegate: ScrollableGraphViewDrawingDelegate! = nil
    
    // Animation Settings
    // ##################
    
    /// How long the animation should take. Affects both the startup animation and the animation when the range of the y-axis adapts to onscreen points.
    open var animationDuration: Double = 1.5
    
    open var adaptAnimationType_: Int {
        get { return adaptAnimationType.rawValue }
        set {
            if let enumValue = ScrollableGraphViewAnimationType(rawValue: newValue) {
                adaptAnimationType = enumValue
            }
        }
    }
    /// The animation style.
    open var adaptAnimationType = ScrollableGraphViewAnimationType.easeOut
    /// If adaptAnimationType is set to .Custom, then this is the easing function you would like applied for the animation.
    open var customAnimationEasingFunction: ((_ t: Double) -> Double)?
    
    // Private Animation State
    // #######################
    
    private var currentAnimations = [GraphPointAnimation]()
    private var displayLink: CADisplayLink!
    private var previousTimestamp: CFTimeInterval = 0
    private var currentTimestamp: CFTimeInterval = 0
    
    private var graphPoints = [Int: GraphPoint]()
    
    deinit {
        displayLink?.invalidate()
    }
    
    // MARK: Different plot types should implement:
    // ############################################
    
    func layers(forViewport viewport: CGRect) -> [ScrollableGraphViewDrawingLayer?] {
        return []
    }
    
    // MARK: Plot Animation
    // ####################
    
    // Animation update loop for co-domain changes.
    @objc private func animationUpdate() {
        let dt = timeSinceLastFrame()
        
        for animation in currentAnimations {
            
            animation.update(withTimestamp: dt)
            
            if animation.finished {
                dequeue(animation: animation)
            }
        }
        
        graphViewDrawingDelegate.updatePaths()
    }
    
    private func animate(point: GraphPoint, to position: CGPoint, withDelay delay: Double = 0) {
        let currentPoint = CGPoint(x: point.x, y: point.y)
        let animation = GraphPointAnimation(fromPoint: currentPoint, toPoint: position, forGraphPoint: point)
        animation.animationEasing = getAnimationEasing()
        animation.duration = animationDuration
        animation.delay = delay
        enqueue(animation: animation)
    }
    
    private func getAnimationEasing() -> (Double) -> Double {
        switch(self.adaptAnimationType) {
        case .elastic:
            return Easings.easeOutElastic
        case .easeOut:
            return Easings.easeOutQuad
        case .custom:
            if let customEasing = customAnimationEasingFunction {
                return customEasing
            }
            else {
                fallthrough
            }
        default:
            return Easings.easeOutQuad
        }
    }
    
    private func enqueue(animation: GraphPointAnimation) {
        if (currentAnimations.count == 0) {
            // Need to kick off the loop.
            displayLink.isPaused = false
        }
        currentAnimations.append(animation)
    }
    
    private func dequeue(animation: GraphPointAnimation) {
        if let index = currentAnimations.firstIndex(of: animation) {
            currentAnimations.remove(at: index)
        }
        
        if(currentAnimations.count == 0) {
            // Stop animation loop.
            displayLink.isPaused = true
        }
    }
    
    internal func dequeueAllAnimations() {
        
        for animation in currentAnimations {
            animation.animationDidFinish()
        }
        
        currentAnimations.removeAll()
        displayLink.isPaused = true
    }
    
    private func timeSinceLastFrame() -> Double {
        if previousTimestamp == 0 {
            previousTimestamp = displayLink.timestamp
        } else {
            previousTimestamp = currentTimestamp
        }
        
        currentTimestamp = displayLink.timestamp
        
        var dt = currentTimestamp - previousTimestamp
        
        if dt > 0.032 {
            dt = 0.032
        }
        
        return dt
    }
    
    internal func startAnimations(forPoints pointsToAnimate: CountableRange<Int>, withData data: [Double], withStaggerValue stagger: Double) {
        
        animatePlotPointPositions(forPoints: pointsToAnimate, withData: data, withDelay: stagger)
    }
    
    internal func createPlotPoints(numberOfPoints: Int, range: (min: Double, max: Double)) {
        graphPoints.removeAll()
        for i in 0 ..< numberOfPoints {
            
            let value = range.min
            
            let position = graphViewDrawingDelegate.calculatePosition(atIndex: i, value: value)
            let point = GraphPoint(position: position)
            graphPoints.updateValue(point, forKey: i)
        }
    }
    
    // When active interval changes, need to set the position for any NEWLY ACTIVATED points, otherwise
    // they will come on screen at the incorrect position.
    // Needs to be called when the active interval has changed and during initial setup.
    internal func setPlotPointPositions(forNewlyActivatedPoints newPoints: CountableRange<Int>, withData data: [Double]) {
        
        for i in newPoints.startIndex ..< newPoints.endIndex {
            // e.g.
            // indices: 10...20
            // data positions: 0...10 = // 0 to (end - start)
            let dataPosition = i - newPoints.startIndex
            
            let value = data[dataPosition]
            
            let newPosition = graphViewDrawingDelegate.calculatePosition(atIndex: i, value: value)
            if graphPoints.keys.contains(i), let point = graphPoints[i] {
                point.x = newPosition.x
                point.y = newPosition.y
                graphPoints.updateValue(point, forKey: i)
            } else {
                let point = GraphPoint(x: newPosition.x, y: newPosition.y)
                graphPoints.updateValue(point, forKey: i)
            }
        }
    }
    
    // Same as a above, but can take an array with the indicies of the activated points rather than a range.
    internal func setPlotPointPositions(forNewlyActivatedPoints activatedPoints: [Int], withData data: [Double]) {
        
        for (i, activatedPointIndex) in activatedPoints.enumerated() {
            
            let value = data[i]
            
            let newPosition = graphViewDrawingDelegate.calculatePosition(atIndex: activatedPointIndex, value: value)
            if graphPoints.keys.contains(activatedPointIndex), let point = graphPoints[activatedPointIndex] {
                point.x = newPosition.x
                point.y = newPosition.y
                graphPoints.updateValue(point, forKey: activatedPointIndex)
            } else {
                let point = GraphPoint(x: newPosition.x, y: newPosition.y)
                graphPoints.updateValue(point, forKey: activatedPointIndex)
            }
        }
    }
    
    // When the range changes, we need to set the position for any VISIBLE points, either animating or setting directly
    // depending on the settings.
    // Needs to be called when the range has changed.
    internal func animatePlotPointPositions(forPoints pointsToAnimate: CountableRange<Int>, withData data: [Double], withDelay delay: Double) {
        // For any visible points, kickoff the animation to their new position after the axis' min/max has changed.
        for (i, pointIndex) in pointsToAnimate.enumerated() {
            let newPosition = graphViewDrawingDelegate.calculatePosition(atIndex: pointIndex, value: data[i])
            let point = graphPoints[pointIndex]
            animate(point: point!, to: newPosition, withDelay: Double(i) * delay)
        }
    }
    
    internal func setup() {
        displayLink = CADisplayLink(target: self, selector: #selector(animationUpdate))
        displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        displayLink.isPaused = true
    }
    
    internal func reset() {
        currentAnimations.removeAll()
        graphPoints.removeAll()
        displayLink?.invalidate()
        previousTimestamp = 0
        currentTimestamp = 0
    }
    
    internal func invalidate() {
        currentAnimations.removeAll()
        graphPoints.removeAll()
        displayLink?.invalidate()
    }
    
    internal func graphPoint(forIndex index: Int) -> GraphPoint {
        return graphPoints[index]!
    }
}

@objc public enum ScrollableGraphViewAnimationType : Int {
    case easeOut
    case elastic
    case custom
}








