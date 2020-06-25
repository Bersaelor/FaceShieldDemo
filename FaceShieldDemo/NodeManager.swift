//
//  NodeManager.swift
//  FaceShieldDemo
//
//  Created by Konrad Feiler on 25.06.20.
//  Copyright © 2020 Konrad Feiler. All rights reserved.
//

import ARKit
import SceneKit

class NodeManager: NSObject {
    
    let scene = SCNScene(named: "art.scnassets/shield.scn")!

    override init() {
        let device: MTLDevice! = MTLCreateSystemDefaultDevice()
        let geometry = ARSCNFaceGeometry(device: device, fillMesh: true)
        geometry?.firstMaterial?.colorBufferWriteMask = []
        faceOcclusionNode = SCNNode(geometry: geometry)
        faceOcclusionNode.renderingOrder = -1
        super.init()
        mainNode?.addChildNode(faceOcclusionNode)
    }
    
    func connect(to sceneView: ARSCNView) {
        sceneView.scene = scene
        
        sceneView.delegate = self
    }

    // private
    
    private var faceNode: SCNNode? {
        didSet {
            guard let mainNode = mainNode else { return }
            faceNode?.addChildNode(mainNode)
        }
    }
    private lazy var mainNode: SCNNode? = {
       return scene.rootNode.childNode(withName: "FaceShield", recursively: true)
    }()
    private lazy var shield: SCNNode? = {
       return scene.rootNode.childNode(withName: "SHIELD", recursively: true)
    }()
    private let faceOcclusionNode: SCNNode
    
}

extension NodeManager: ARSCNViewDelegate {
    // MARK: - ARSCNViewDelegate
        
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        self.faceNode = node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        let faceGeometry = faceOcclusionNode.geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: faceAnchor.geometry)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("Removed \(node.name ?? "?") for anchor \(type(of: anchor))")
    }
}
