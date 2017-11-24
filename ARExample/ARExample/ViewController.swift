//
//  ViewController.swift
//  ARExample
//
//  Created by Jay Lees on 21/11/2017.
//  Copyright © 2017 Jay Lees. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var swipeRecogniser: UIPanGestureRecognizer!
    var currentBall: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = SCNScene()
        sceneView.scene = scene
        swipeRecogniser = UIPanGestureRecognizer(target: self, action: #selector(userDidSwipe))
        sceneView.addGestureRecognizer(swipeRecogniser)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        let footballField = createFootballField()
        sceneView.scene.rootNode.addChildNode(footballField)
    }

    private func createFootballField() -> SCNNode {
        let pitch = SCNPlane(width: 1.5, height: 0.7)
        
        pitch.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "pitch")
        pitch.firstMaterial?.isDoubleSided = true
        let pitchNode = SCNNode(geometry: pitch)
        
        let xRotation = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        let yRotation = SCNMatrix4MakeRotation(-Float.pi/2, 0, 0, 1)
        pitchNode.transform = SCNMatrix4Mult(SCNMatrix4Mult(yRotation, xRotation), pitchNode.transform)
        pitchNode.position = SCNVector3Make(0, -0.2, 0)
        
        if let goal = createGoal() {
            pitchNode.addChildNode(goal.rootNode)
        }
       
        return pitchNode
    }
    
    private func createGoal() -> SCNScene? {
        guard let goal = SCNScene(named: "art.scnassets/goal.dae") else {
            print("Error creating goal")
            return nil
        }

        goal.rootNode.scale = SCNVector3Make(0.0005, 0.0005, 0.0005)
        goal.rootNode.eulerAngles.x = Float.pi/2
        goal.rootNode.position = SCNVector3Make(-1.5/2 + 0.05, -0.075, 0)
        return goal
    }
    
    @objc func userDidSwipe(){
        let translation = swipeRecogniser.translation(in: sceneView)
        if swipeRecogniser.state == .began {
            let ball = SCNSphere(radius: 0.005)
            ball.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "football")
            
            let newBallNode = SCNNode(geometry: ball)
            newBallNode.position = SCNVector3Make(0, -0.195, 0)
            
            currentBall = newBallNode
            sceneView.scene.rootNode.addChildNode(newBallNode)
        } else if swipeRecogniser.state == .ended {
            currentBall?.runAction(generateBallAction(translation: translation))
        }
    }
    
    private func generateBallAction(translation: CGPoint) -> SCNAction {
        let speedForward = Float(translation.y / (sceneView.frame.height/4))
        let horizontal = Float(translation.x / (sceneView.frame.width))
        let vector = SCNVector3Make(horizontal, 0, speedForward)
        
        let translation = SCNAction.move(by: vector, duration: 2)
        
        let rolls = Int(vector.length / 0.01 / Float.pi)
        let rotation = SCNAction.rotateBy(x: -CGFloat.pi, y: 0 , z: 0, duration: 1/Double(rolls))
        let repeatRotation = SCNAction.repeat(rotation, count: Int(2*rolls))

        return SCNAction.group([translation, repeatRotation])
    }
}

extension SCNVector3 {
    var length: Float {
        return sqrt((x * x) + (y * y) + (z * z))
    }
}
