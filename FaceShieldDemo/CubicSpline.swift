//
//  CubicSpline.swift
//  FaceShieldDemo
//
//  Created by Konrad Feiler on 26.06.20.
//  Copyright © 2020 Konrad Feiler. All rights reserved.
//

import Foundation
import Accelerate.vecLib.LinearAlgebra

public typealias Value = Double

//public struct CubicSpline<Value: FloatingPoint> {
public struct CubicSpline {
    // y(x) = x, y'(x) = d
    public struct ControlPoint {
        let x: Value
        let y: Value
        let d: Value
    }

    public struct Point {
        let x: Value
        let y: Value
    }
    
    public let controlPoints: [ControlPoint]
    
    private let coefficients: [CubicPoly]
    
    public init(points: [Point], tangentAtStart: Value, tangentAtEnd: Value) {
        let matrix = Self.tridiagonalMatrix(size: points.count)
        
        let rightHand = Self.rhs(values: points.map({ $0.y }), tangentAtStart: tangentAtStart, tangentAtEnd: tangentAtEnd)
        let solution = la_solve(matrix, rightHand)
        var derivatives = [Value](repeating: 0, count: points.count)
        la_matrix_to_double_buffer(&derivatives, 1, solution)
        print("derivatives: \(derivatives)")
        let controlPoints = points.enumerated().map { (value) in
            return ControlPoint(x: value.element.x, y: value.element.y, d: derivatives[value.offset])
        }
        print("controlPoints: \(controlPoints)")
        self.init(points: controlPoints)
    }
    
    /// In cases where y(x_n) and the derivative y'(x_n) is known for all points
    /// use this initializer
    /// - Parameter points: the control points with the derivative
    public init(points: [ControlPoint]) {
        if points.count < 2 { fatalError("Can't create piece wise spline with less then 2 control points") }
        self.controlPoints = points.sorted { $0.x < $1.x }
        self.coefficients = Self.computeCoefficients(from: self.controlPoints)
    }
    
    public func f(x: Value) -> Value {
        guard x > controlPoints[0].x else {
            // extend constant function to the left
            return controlPoints[0].y
        }
        guard x < controlPoints.last!.x else {
            // extend constant function to the right
            return controlPoints.last!.y
        }
        let index = controlPoints.firstIndex(where: { $0.x < x })!
        let t = (x - controlPoints[index].x)/(controlPoints[index.advanced(by: 1)].x - controlPoints[index].x)
        return coefficients[index].f(t: t)
    }
    
    // MARK: - Private implementation details
    
    /// https://mathworld.wolfram.com/CubicSpline.html
    /// cubic spline matrix with fixed derivatives at start and end
    /// 1 0   ... 0
    /// 1 4 1 ... 0
    /// 0 1 4 1.. 0
    /// ...     ...
    /// 0 ... 1 4 1
    /// 0 ...   0 1
    private static func tridiagonalMatrix(size: Int) -> la_object_t {
        var elements = [Double]()
        for row in 0..<size {
            for column in 0..<size {
                if row == 0 {
                    elements.append(column == 0 ? 1 : 0)
                } else if row == size - 1 {
                    elements.append(column == size - 1 ? 1 : 0)
                } else {
                    if row == column {
                        elements.append(4)
                    } else if row == column + 1 || row == column - 1 {
                        elements.append(1)
                    } else {
                        elements.append(0)
                    }
                }
            }
        }
        print("elements: \(elements)")
        let matrix = la_matrix_from_double_buffer(
            &elements,
            la_count_t(size),
            la_count_t(size),
            la_count_t(size),
            la_hint_t(LA_FEATURE_DIAGONALLY_DOMINANT), la_attribute_t(LA_DEFAULT_ATTRIBUTES)
        )
        
        var matrixV = [Value](repeating: 0, count: size * size)
        let status = la_matrix_to_double_buffer(&matrixV, 1, matrix)
        print("matrixV: \(matrixV), status: \(LAStatus(status))")

        
        return matrix
    }
    
    private static func rhs(values: [Value], tangentAtStart: Value, tangentAtEnd: Value) -> la_object_t {
        var elements = [Double]()
        elements.append(tangentAtStart)
        for row in 1..<(values.count-2) {
            elements.append(3 * (values[row+1] - values[row-1]))
        }
        elements.append(tangentAtEnd)
        return la_matrix_from_double_buffer(
            &elements,
            UInt(elements.count),
            1, 1,
            la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES)
        )
    }
    
    struct CubicPoly {
        let a, b, c, d: Value
    }
    
    private static func computeCoefficients(from points: [ControlPoint]) -> [CubicPoly] {
        return points.indices.dropLast().map { (index) -> CubicPoly in
            let y = points[index].y
            let yN1 = points[index.advanced(by: 1)].y
            let d = points[index].d
            let dN1 = points[index.advanced(by: 1)].d
            return CubicPoly(
                a: y,
                b: points[index].d,
                c: 3*(yN1 - y) - 2*d - dN1,
                d: 2*(y - yN1) + d + dN1
            )
        }
    }
}

private extension CubicSpline.CubicPoly {
    
    /// Piecewise function
    /// - Parameter t: input value between 0 and 1
    func f(t: Value) -> Value {
        let t2 = t * t
        return a + b * t + c * t2 + d * t2 * t
    }
}

public enum LAStatus {
    case Success;
    case PoorlyConditionedWarning;
    case InternalError;
    case InvalidParameterError;
    case DimensionMismatchError;
    case PrecisionMismatchError;
    case SingularError;
    case SliceOutOfBoundsError;

    fileprivate var _rawValue: la_hint_t {
        var value: Int32 {
            switch self {
            case .Success:                  return LA_SUCCESS
            case .PoorlyConditionedWarning: return LA_WARNING_POORLY_CONDITIONED
            case .InternalError:            return LA_INTERNAL_ERROR
            case .InvalidParameterError:    return LA_INVALID_PARAMETER_ERROR
            case .DimensionMismatchError:   return LA_DIMENSION_MISMATCH_ERROR
            case .PrecisionMismatchError:   return LA_PRECISION_MISMATCH_ERROR
            case .SingularError:            return LA_SINGULAR_ERROR
            case .SliceOutOfBoundsError:    return LA_SLICE_OUT_OF_BOUNDS_ERROR
            }
        }
        return la_attribute_t(value)
    }

    fileprivate init (_ value: la_status_t) {
        var value: LAStatus {
            switch value {
            case Int(LA_SUCCESS):                    return .Success
            case Int(LA_WARNING_POORLY_CONDITIONED): return .PoorlyConditionedWarning
            case Int(LA_INTERNAL_ERROR):             return .InternalError
            case Int(LA_INVALID_PARAMETER_ERROR):    return .InvalidParameterError
            case Int(LA_DIMENSION_MISMATCH_ERROR):   return .DimensionMismatchError
            case Int(LA_PRECISION_MISMATCH_ERROR):   return .PrecisionMismatchError
            case Int(LA_SINGULAR_ERROR):             return .SingularError
            case Int(LA_SLICE_OUT_OF_BOUNDS_ERROR):  return .SliceOutOfBoundsError
            default:                                 return .InternalError
            }
        }
        self = value
    }
}
