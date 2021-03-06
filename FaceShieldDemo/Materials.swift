//
//  Materials.swift
//  FaceShieldDemo
//
//  Created by Konrad Feiler on 25.06.20.
//  Copyright © 2020 Konrad Feiler. All rights reserved.
//

import SceneKit

enum Material: String, CaseIterable {
    case steel
    case blinnPlexi
    case blendAddPlexi
    case shadedPlain
    case reflectivePBR
}

extension Material {
    var blendMode: SCNBlendMode {
        switch self {
        case .blendAddPlexi: return .add
        default: return .alpha
        }
    }
    
    var reflectiveContent: String {
        switch self {
        case .blendAddPlexi, .blinnPlexi: return "art.scnassets/lightmap.jpeg"
        default: return ""
        }
    }
}

extension SCNMaterial {
    
    func set(material: Material, opacity: CGFloat) {
        blendMode = material.blendMode
        reflective.contents = material.reflectiveContent
        transparencyMode = .dualLayer
        switch material {
        case .steel:
            makeSteel()
        case .blinnPlexi:
            makeBlinnPlexi()
        case .blendAddPlexi:
            makeBlendAddPlexi()
        case .shadedPlain:
            makeShadedPlain()
        case .reflectivePBR:
            makeReflectivePBR(opacity: opacity)
        }
    }
    
    private func makeSteel() {
        removeShaderModifiers()
        lightingModel = .physicallyBased
        metalness.contents = 1.0
        roughness.contents = 0.1
        diffuse.contents = UIColor(hex: "f1f1f9")
    }

    private func makeBlinnPlexi() {
        removeShaderModifiers()
        lightingModel = .blinn
        shininess = 99
        specular.contents = UIColor(hex: "eeeeee")
        fresnelExponent = 1.1
        diffuse.contents = UIColor(hex: "f1f1f9")
    }

    private func makeBlendAddPlexi() {
        removeShaderModifiers()
        lightingModel = .physicallyBased
        metalness.contents = 1.0
        roughness.contents = 0.2
        diffuse.contents = UIColor(hex: "f1f1f9")
    }
    
    private func makeShadedPlain() {
        removeShaderModifiers()
        lightingModel = .physicallyBased
        metalness.contents = 1.0
        roughness.contents = 0.2
        diffuse.contents = UIColor(hex: "f1f1f9")
    }
    
    private func makeReflectivePBR(opacity: CGFloat) {
        setReflectiveClearShader(minAlpha: 0.1)
        lightingModel = .physicallyBased
        metalness.contents = 1.0
        roughness.contents = 0.2
        diffuse.contents = UIColor(hex: "f1f1f9")
    }

    private func removeShaderModifiers() {
        self.shaderModifiers = [SCNShaderModifierEntryPoint: String]()
    }
    
    private func setReflectiveClearShader(minAlpha: CGFloat = 0.0) {
        let reflection: Float = 0.8
        let shaderModifier = """
#pragma transparent
#pragma body

vec3 light = _lightingContribution.specular;
float alpha = max(\(minAlpha), \(reflection) * min(1.0, 0.33 * light.r + 0.33 * light.g + 0.33 * light.b));
_output.color.rgb = dot(_output.color.rgb, float3(0.212671, 0.715160, 0.072169) * min(1.0, (1.5 + 2 * \(minAlpha)) * alpha));
_output.color.a = alpha;
"""
        self.shaderModifiers = [.fragment: shaderModifier]
    }
}
