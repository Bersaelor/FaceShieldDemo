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
    
    var chosenMaterial = Material.reflectivePBR {
        didSet { updateShieldMaterial() }
    }
    var chosenOpacity: CGFloat = 0.85 {
        didSet { updateShieldMaterial() }
    }

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
        
        sceneView.session.delegate = self
        
        metalClips.forEach { (node) in
            node.geometry?.firstMaterial?.set(material: .steel, opacity: 1.0)
        }
        
        updateShieldMaterial()

        let lightingEnvironment = sceneView.scene.lightingEnvironment
        lightingEnvironment.contents = "art.scnassets/cloudy.jpg"
    }

    // private
    
    private func updateShieldMaterial() {
        guard let material = shield?.geometry?.firstMaterial else { return }
        material.set(material: chosenMaterial, opacity: chosenOpacity)
        material.transparent.contents = chosenOpacity
    }
    
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
    private lazy var metalClips: [SCNNode] = {
        return [
            scene.rootNode.childNode(withName: "METAL_RIGHT", recursively: true),
            scene.rootNode.childNode(withName: "METAL_LEFT", recursively: true)
            ].compactMap { $0 }
    }()
    private let faceOcclusionNode: SCNNode
    
    private func updateLight(lightEstimate: ARLightEstimate) {
        scene.lightingEnvironment.intensity = 2 * lightEstimate.ambientIntensity / 1000.0
    }
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

extension NodeManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let lightEstimate = session.currentFrame?.lightEstimate  else {
            print("Failed to get lightEstimate")
            return
        }
                
        updateLight(lightEstimate: lightEstimate)
    }
}
