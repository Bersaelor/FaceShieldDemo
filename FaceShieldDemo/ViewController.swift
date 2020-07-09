//
//  ViewController.swift
//  FaceShieldDemo
//
//  Created by Konrad Feiler on 25.06.20.
//  Copyright © 2020 Konrad Feiler. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var opacitySlider: UISlider!
    @IBOutlet weak var materialPicker: UIPickerView!
    @IBOutlet weak var graphView: GraphView!
    
    let nodeManager = NodeManager()
    
    let maxStatisticsAge: TimeInterval = 10
    var lightDataPoints: [(CGFloat, CGFloat, Date)] = []
    var animationTimer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        nodeManager.connect(to: sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        graphView.yRange = 0 ..< 2.5
        
        nodeManager.handleLightIntensityChange = { [weak self] estimateIntensity, dampenedIntensity in
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            self?.debugLabel.text = "\(formatter.string(for: estimateIntensity) ?? "?") : \(formatter.string(for: dampenedIntensity) ?? "?")"
            self?.addLight(estimate: estimateIntensity, dampenedIntensity: dampenedIntensity)
        }
        
        opacitySlider.value = Float(nodeManager.chosenOpacity)
        materialPicker.selectRow(Material.allCases.firstIndex(of: nodeManager.chosenMaterial)!, inComponent: 0, animated: false)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        sceneView.automaticallyUpdatesLighting = false
        // Run the view's session
        sceneView.session.run(configuration)
        
        print("creating timer")
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (_) in
            self?.updateGraphView()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        animationTimer = nil
    }
    
    private func updateGraphView() {
        guard !lightDataPoints.isEmpty else { return }
        var estimatedLightPoints = [CGPoint]()
        var dampenedLightPoints = [CGPoint]()

        let now = Date()
        for dataP in lightDataPoints {
            let x = CGFloat(1 - (now.timeIntervalSince(dataP.2) / maxStatisticsAge))
            estimatedLightPoints.append(CGPoint(x: x, y: dataP.0))
            dampenedLightPoints.append(CGPoint(x: x, y: dataP.1))
        }
                
        graphView.lines = [
            (UIColor.systemYellow, estimatedLightPoints),
            (UIColor.systemTeal, dampenedLightPoints),
        ]
    }
    
    private func addLight(estimate: CGFloat, dampenedIntensity: CGFloat) {
        let now = Date()
        lightDataPoints = lightDataPoints.filter { now.timeIntervalSince($0.2) < maxStatisticsAge } + [(estimate, dampenedIntensity, now)]
    }

    @IBAction func sliderChangedValue(_ sender: UISlider) {
        nodeManager.chosenOpacity = CGFloat(sender.value)
    }
    
    var session: ARSession? { return sceneView?.session }
}

extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Material.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
}

extension ViewController: UIPickerViewDelegate {
    func pickerView(
        _ pickerView: UIPickerView,
        didSelectRow row: Int,
        inComponent component: Int
    ) {
        nodeManager.chosenMaterial = Material.allCases[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Material.allCases[row].rawValue
    }
}
