//
//  ViewController.swift
//  GraphViewIB
//

import UIKit

class ViewController: UIViewController, ScrollableGraphViewDataSource {
    // MARK: Properties
    
    @IBOutlet var graphView: ScrollableGraphView!
    @IBOutlet var reloadButton: UIButton!
    
    var numberOfItems = 1
    lazy var plotOneData: [Double] = self.generateRandomData(self.numberOfItems, max: 100, shouldIncludeOutliers: true)
    lazy var plotTwoData: [Double] = self.generateRandomData(self.numberOfItems, max: 80, shouldIncludeOutliers: false)
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: Init    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.orange
        
        graphView.dataSource = self
        setupGraph(graphView: graphView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        graphView.frame = CGRect(x: 0, y: 150, width: self.view.frame.width, height: 300)
    }
    
    // MARK: Button Clicks
    
    @IBAction func reloadDidClick(_ sender: Any) {
        self.numberOfItems = 90
        plotOneData = self.generateRandomData(self.numberOfItems, max: 100, shouldIncludeOutliers: true)
        plotTwoData = self.generateRandomData(self.numberOfItems, max: 80, shouldIncludeOutliers: false)
        graphView.reload()
    }

    // MARK: ScrollableGraphViewDataSource
    
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        switch(plot.identifier) {
        case "one":
            return plotOneData[pointIndex]
        case "two":
            return plotTwoData[pointIndex]
        default:
            return 0
        }
    }
    
    func label(atIndex pointIndex: Int) -> String {
        if pointIndex % 8 == 0 {
            return "FEB \(pointIndex+1)"
        }
        return ""
    }
    
    func numberOfPoints() -> Int {
        return numberOfItems
    }
    
    // MARK: Helper Functions
    
    // When using Interface Builder, only add the plots and reference lines in code.
    func setupGraph(graphView: ScrollableGraphView) {
        
        // Setup the first line plot.
        let blueLinePlot = LinePlot(identifier: "one")
        
        blueLinePlot.lineWidth = 2
        blueLinePlot.lineColor = UIColor.colorFromHex(hexString: "#999999").withAlphaComponent(0.5)
        blueLinePlot.lineStyle = ScrollableGraphViewLineStyle.smooth
        
        blueLinePlot.shouldFill = false
        blueLinePlot.fillType = ScrollableGraphViewFillType.solid
        blueLinePlot.fillColor = UIColor.colorFromHex(hexString: "#cccccc").withAlphaComponent(0.5)
        
        blueLinePlot.adaptAnimationType = ScrollableGraphViewAnimationType.easeOut
        blueLinePlot.animationDuration = 0.5
        
        // Setup the second line plot.
        let orangeLinePlot = LinePlot(identifier: "two")
        
        orangeLinePlot.lineWidth = 2
        orangeLinePlot.lineColor = UIColor.colorFromHex(hexString: "#FE9F0B")
        orangeLinePlot.lineStyle = ScrollableGraphViewLineStyle.smooth
        
        orangeLinePlot.shouldFill = false
        orangeLinePlot.fillType = ScrollableGraphViewFillType.solid
        orangeLinePlot.fillColor = UIColor.colorFromHex(hexString: "#FE9F0B").withAlphaComponent(0.5)
        
        orangeLinePlot.adaptAnimationType = ScrollableGraphViewAnimationType.easeOut
        orangeLinePlot.animationDuration = 0.5
        
        // Customise the reference lines.
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
        referenceLines.referenceLineColor = UIColor.black.withAlphaComponent(0.2)
        referenceLines.referenceLineLabelColor = UIColor.black
        referenceLines.positionType = .relative
        referenceLines.relativePositions = [0.2, 0.4, 0.6, 0.8]
        referenceLines.dataPointLabelColor = UIColor.black.withAlphaComponent(1)
        referenceLines.dataPointLabelFont = UIFont.systemFont(ofSize: 8)
        referenceLines.referenceLineUnits = "times"
        referenceLines.unitLabelPostionType = .none
        
        
        // All other graph customisation is done in Interface Builder, 
        // e.g, the background colour would be set in interface builder rather than in code.
        // graphView.backgroundFillColor = UIColor.colorFromHex(hexString: "#333333")
        
        // Add everything to the graph.
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.shouldAnimateOnStartup = true
        graphView.shouldAnimateOnAdapt = true
        graphView.shouldRangeAlwaysStartAtZero = true
        graphView.shouldAdaptRange = false
        graphView.pointAnimStaggerTime = 0
        graphView.rangeMax = 300
        graphView.rangeMin = 0
        graphView.dataPointSpacing = 10
        graphView.addPlot(plot: blueLinePlot)
        graphView.addPlot(plot: orangeLinePlot)
    }
    
    private func generateRandomData(_ numberOfItems: Int, max: Double, shouldIncludeOutliers: Bool = true) -> [Double] {
        var data = [Double]()
        for _ in 0 ..< numberOfItems {
            var randomNumber = Double(arc4random()).truncatingRemainder(dividingBy: max)
            
            if(shouldIncludeOutliers) {
                if(arc4random() % 100 < 10) {
                    randomNumber *= 3
                }
            }
            
            data.append(randomNumber)
        }
        return data
    }
}
