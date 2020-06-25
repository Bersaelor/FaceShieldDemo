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

    @IBOutlet var sceneView: ARSCNView!
    
    let nodeManager = NodeManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        nodeManager.connect(to: sceneView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    var session: ARSession? { return sceneView?.session }
}
