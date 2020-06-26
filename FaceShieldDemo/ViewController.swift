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
    
    let nodeManager = NodeManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        nodeManager.connect(to: sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nodeManager.handleLightIntensityChange = { [weak self] rawIntensity, newIntensity in
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            self?.debugLabel.text = "Light-Intensity: \(formatter.string(for: newIntensity) ?? "?") (\(formatter.string(for: rawIntensity) ?? "?"))"
        }
        
        opacitySlider.value = Float(nodeManager.chosenOpacity)
        materialPicker.selectRow(Material.allCases.firstIndex(of: nodeManager.chosenMaterial)!, inComponent: 0, animated: false)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        sceneView.automaticallyUpdatesLighting = false
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
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
