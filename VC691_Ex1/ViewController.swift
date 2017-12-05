//
//  ViewController.swift
//  VC691_Ex1
//
//  Created by kcmmac on 2017-11-14.
//  Copyright © 2017 kcmmac. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum BodyType : Int {
    case box = 1
    case plane = 2
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let box_width : CGFloat = 0.25
    let box_height : CGFloat = 0.05
    let box_length : CGFloat = 0.25
    
    let moveMaxLimit : Float = 1.2
    var nextPosY : Float = 0
    
    var sounds = [String: SCNAudioSource]()
    
    var planes = [OverlayPlane]()
    var arrBlockNode = [SCNNode]()
    
    var glblGameTitle : UILabel!
    var glblRecord : UILabel!
    var glblTitle : UILabel!
    var glblHeight : UILabel!
    var btnStartAgain : GameButton!
    
    var curMaxRecord : Int = 0
    var bottomIdx = 0
    
    var isFirst : Bool = true
    
    var direction = true
    var height = 0
    
    var prevSize = SCNVector3Zero
    var prevPos = SCNVector3Zero
    var curSize = SCNVector3Zero
    var curPos = SCNVector3Zero
    
    var offset = SCNVector3Zero
    var absOffset = SCNVector3Zero
    var newSize = SCNVector3Zero
    
    var perfectMaches = 0
    var prevColor : UIColor = UIColor.clear
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        prevSize = SCNVector3(box_width, box_height, box_length)
        curSize = SCNVector3(box_width, box_height, box_length)
        

        sceneView.autoenablesDefaultLighting = true
        
        setupUI()
        
        loadSound(name: "GameOver", path: "GameOver.wav")
        loadSound(name: "PerfectFit", path: "PerfectFit.wav")
        
    }
    
    func loadSound(name: String, path: String) {
        if let sound = SCNAudioSource(fileNamed: path) {
            sound.isPositional = false
            sound.volume = 1
            sound.load()
            sounds[name] = sound
        }
    }
    
    func playSound(sound: String, node: SCNNode) {
        node.runAction(SCNAction.playAudio(sounds[sound]!, waitForCompletion: false))
    }
    
    private func setupUI() {
        
        // label
        glblTitle = UILabel(frame: CGRect(x: 30, y: 200, width: 350, height: 40 ))
        glblTitle.text =  "Find a Surface and tap to start"
        glblTitle.textColor = UIColor.white
        glblTitle.font = UIFont.boldSystemFont(ofSize: 22)
        
        glblHeight = UILabel(frame: CGRect(x: self.sceneView.frame.width/2-25, y: 20, width: 150, height: 70 ))
        glblHeight.text = "0"
        glblHeight.textColor = UIColor.white
        glblHeight.font = UIFont.boldSystemFont(ofSize: 50)
        glblHeight.isHidden = true
        
        glblRecord = UILabel(frame: CGRect(x: self.sceneView.frame.width/2 + 110, y: 20, width: 60, height: 30 ))
        glblRecord.textColor = UIColor.white
        glblRecord.font = UIFont.boldSystemFont(ofSize: 18)
        glblRecord.isHidden = true
        
        glblGameTitle = UILabel(frame: CGRect(x: self.sceneView.frame.width/2-120, y: 50, width: 240, height: 30 ))
        glblGameTitle.textColor = UIColor(red:0.22, green:0.47, blue:0.90, alpha:0.8)
        glblGameTitle.font = UIFont.boldSystemFont(ofSize: 40)
        glblGameTitle.text = "ARStack691"
        
        let defaults = UserDefaults.standard
        if let record_high = defaults.string(forKey: "p_record") {
            glblRecord.text = "♦︎\(record_high)"
            curMaxRecord = Int(record_high)!
        } else {
            glblRecord.text = "♦︎0"
            curMaxRecord = 0
        }
        
        // Restart Button
        btnStartAgain = GameButton(frame: CGRect( x:self.sceneView.frame.width/2-120,
                                                 y:self.sceneView.frame.height/2+80, width: 240, height: 160)
        ) {
            // ===== game restart =====
            // remove all blocks
            for idx in 0...self.height {
                if let node = self.sceneView.scene.rootNode.childNode(withName: "Block\(idx)", recursively: false){
                    node.removeFromParentNode()
                }
                if let node = self.sceneView.scene.rootNode.childNode(withName: "Broken\(idx)", recursively: false){
                    node.removeFromParentNode()
                }
            }
            self.height = 0
            
            self.glblRecord.text = "♦︎\(self.curMaxRecord)"
            self.glblTitle.isHidden = false
            self.glblHeight.isHidden = true
            self.glblRecord.isHidden = true
            self.glblGameTitle.isHidden = false
            self.glblHeight.text = "\(self.height)"
            
            
            self.isFirst = true
            
            self.btnStartAgain.isHidden = true
            
        }
        btnStartAgain.setTitle("Start Again", for: .normal)
        btnStartAgain.titleLabel?.font = UIFont.boldSystemFont(ofSize: 45)
        btnStartAgain.isHidden = true
        
        self.sceneView.addSubview(glblGameTitle)
        self.sceneView.addSubview(glblRecord)
        self.sceneView.addSubview(btnStartAgain)
        self.sceneView.addSubview(glblTitle)
        self.sceneView.addSubview(glblHeight)
        
        
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            let touchLocation = touch.location(in: sceneView)
            
            if isFirst == true {
                
                
                glblHeight.isHidden = false
                glblRecord.isHidden = false
                
                btnStartAgain.isHidden = true
                glblGameTitle.isHidden = true
                glblTitle.isHidden = true
                
                
                let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
                
                if let hitResult = results.first {
                    
                        addTheBaseBox(hitResult: hitResult)
                        glblTitle.isHidden = true
                        isFirst = false
//                        kcnt += 1
                }
                
            } else {
                handleTap();
            }
            
        }
    }
    
    private func handleTap(){
        if let curBoxNode = sceneView.scene.rootNode.childNode(withName: "Block\(height)", recursively: false) {
            
            curPos = curBoxNode.presentation.position
            let boundsMin = curBoxNode.boundingBox.min
            let boundsMax = curBoxNode.boundingBox.max
            curSize = boundsMax - boundsMin
            
            offset = prevPos - curPos
            absOffset = offset.absoluteValue()
            newSize = curSize - absOffset
            
            checkPerfectMatch(curBoxNode)
            
            curBoxNode.geometry = SCNBox(width: CGFloat(newSize.x), height: box_height, length: CGFloat(newSize.z), chamferRadius: 0)
            curBoxNode.position = SCNVector3Make(curPos.x + (offset.x/2), curPos.y, curPos.z + (offset.z/2))
            
            curBoxNode.geometry?.firstMaterial?.diffuse.contents = prevColor
            
            curBoxNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: curBoxNode.geometry!, options: nil))
            
            addBrokenBlock(curBoxNode)
            
            if height % 2 == 0 && newSize.z <= 0 {
                height += 1
                curBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: curBoxNode.geometry!, options: nil))
                
                playSound(sound: "GameOver", node: curBoxNode)
                gameOver()
                return
                
            } else if height % 2 != 0 && newSize.x <= 0 {
                height += 1
                curBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: curBoxNode.geometry!, options: nil))
                playSound(sound: "GameOver", node: curBoxNode)
                gameOver()
                return
            }
            
            
            // save to array
            if height > 12 {
                bottomIdx = height-12
                if let saveNode = sceneView.scene.rootNode.childNode(withName: "Block\(bottomIdx)", recursively: false){
                    arrBlockNode.append(saveNode)
                    saveNode.removeFromParentNode()
                    
                    //change the height
                    for idx in bottomIdx...height {
                        if let moveNode = sceneView.scene.rootNode.childNode(withName: "Block\(idx)", recursively: false){
                            moveNode.position.y -= Float(box_height)
                        }
                    }
                    
                    curPos.y -= Float(box_height)
                }
            }
            
            
            addNewBlock(curBoxNode)
            
            glblHeight.text = "\(height)"
            
            prevSize = SCNVector3Make(newSize.x, Float(box_height), newSize.z)
            prevPos = curBoxNode.position
            height += 1
            
            
        }
        
    }
    
    private func checkPerfectMatch(_ curBoxNode: SCNNode){
        // assume the offest that is less than 0.03 is a perfect match
        
        if height % 2 == 0 && absOffset.z <= 0.015 {
            playSound(sound: "PerfectFit", node: curBoxNode)
            
            curBoxNode.position.z = prevPos.z
            curPos.z = prevPos.z
            perfectMaches += 1
            
//            if perfectMaches > 7 && curSize.z < 1 {
//                newSize.z += 0.05
//            }
            offset = prevPos - curPos
            absOffset = offset.absoluteValue()
            newSize = curSize - absOffset
            print("SIZE2: \(newSize)")
        } else if height % 2 != 0 && absOffset.x <= 0.015 {
            playSound(sound: "PerfectFit", node: curBoxNode)
            curBoxNode.position.x = prevPos.x
            curPos.x = prevPos.x
            perfectMaches += 1
//            if perfectMaches > 7 && curSize.x < 1 {
//                newSize.x += 1
//            }
            offset = prevPos - curPos
            absOffset = offset.absoluteValue()
            newSize = curSize - absOffset
            print("SIZE2: \(newSize)")
        } else {
            perfectMaches = 0
        }
        
    }
    
    private func gameOver(){
        
        btnStartAgain.isHidden = false
        
        // save to array from bottomIdx to height
        if height > 13 {
            for idx in bottomIdx...height {
                if let saveNode = sceneView.scene.rootNode.childNode(withName: "Block\(idx)", recursively: false){
                    arrBlockNode.append(saveNode)
                    saveNode.removeFromParentNode()
                }
            }
        
            for node in arrBlockNode {
                node.position.y = nextPosY + Float(box_height)
                sceneView.scene.rootNode.addChildNode(node)
                nextPosY += Float(box_height)
            }
        }
        
        arrBlockNode.removeAll()
        
        
        if height-2 > curMaxRecord {
            curMaxRecord = height-2
        }
        let defaults = UserDefaults.standard
        defaults.set("\(curMaxRecord)", forKey: "p_record")
        
    }
    
    private func addNewBlock(_ curBoxNode: SCNNode){
        prevColor = UIColor.random()
        let newBox = SCNBox(width: CGFloat(newSize.x), height: box_height, length: CGFloat(newSize.z),chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = prevColor
        
        let newBoxNode = SCNNode(geometry: newBox)
        newBoxNode.position = SCNVector3Make(curBoxNode.position.x, curPos.y + Float(box_height), curBoxNode.position.z)
        newBoxNode.name = "Block\(height+1)"
        newBoxNode.geometry?.materials = [material]
//        newBoxNode.geometry?.firstMaterial?.diffuse.contents = prevColor
        let maxLimit : Float = moveMaxLimit
        
        
        if height % 2 == 0 {
            newBoxNode.position.x = prevPos.x - (maxLimit/2)
        } else {
            newBoxNode.position.z = prevPos.z - (maxLimit/2)
        }
        
        sceneView.scene.rootNode.addChildNode(newBoxNode)
        
    }
    
    private func addBrokenBlock(_ curBoxNode: SCNNode){
        let brokenBoxNode = SCNNode()
        brokenBoxNode.name = "Broken\(height)"
        
        if height % 2 == 0 && absOffset.z > 0.015 {
            brokenBoxNode.geometry = SCNBox(width: CGFloat(curSize.x), height: box_height, length: CGFloat(absOffset.z), chamferRadius: 0)
            
            if offset.z > 0 {
                brokenBoxNode.position.z = curBoxNode.position.z - (offset.z/2) - ((curSize - offset).z/2)
            } else {
                brokenBoxNode.position.z = curBoxNode.position.z - (offset.z/2) + ((curSize - offset).z/2)
            }
            
            brokenBoxNode.position.x = curBoxNode.position.x
            brokenBoxNode.position.y = curPos.y
            
            brokenBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: brokenBoxNode.geometry!, options: nil))
            brokenBoxNode.physicsBody?.categoryBitMask = BodyType.box.rawValue
            brokenBoxNode.geometry?.firstMaterial?.diffuse.contents = prevColor
            
            
        } else if height % 2 != 0 && absOffset.x > 0.015 {
            brokenBoxNode.geometry = SCNBox(width: CGFloat(absOffset.x), height: box_height, length: CGFloat(curSize.z), chamferRadius: 0)
            
            if offset.x > 0 {
                brokenBoxNode.position.x = curBoxNode.position.x - (offset.x/2) - ((curSize - offset).x/2)
            } else {
                brokenBoxNode.position.x = curBoxNode.position.x - (offset.x/2) + ((curSize - offset).x/2)
            }
            
            brokenBoxNode.position.y = curPos.y
            brokenBoxNode.position.z = curBoxNode.position.z
            
            brokenBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: brokenBoxNode.geometry!, options: nil))
            brokenBoxNode.physicsBody?.categoryBitMask = BodyType.box.rawValue
            brokenBoxNode.geometry?.firstMaterial?.diffuse.contents = prevColor
            
        }
        sceneView.scene.rootNode.addChildNode(brokenBoxNode)
    }
    
    private func addTheBaseBox(hitResult: ARHitTestResult){
        let box = SCNBox(width: box_width, height: box_height, length: box_length, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "art.scnassets/bricks.jpg")
        material.name = "Color"
        
        let node = SCNNode(geometry: box)
        node.geometry?.materials = [material]
        
//        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
//        node.physicsBody?.categoryBitMask = BodyType.box.rawValue
        node.position = SCNVector3(
            hitResult.worldTransform.columns.3.x,
            hitResult.worldTransform.columns.3.y + Float(box.height/2),
            hitResult.worldTransform.columns.3.z
        )
        
        node.eulerAngles = SCNVector3(0,0,0)
        node.name = "Block\(height)"
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: box, options: nil))
        
        nextPosY = node.position.y
        prevPos = node.position
        height += 1
        sceneView.scene.rootNode.addChildNode(node)
        
        
        // add the first moving cube
        let box2 = SCNBox(width: box_width, height: box_height, length: box_length, chamferRadius: 0)
        
        let material2 = SCNMaterial()
        prevColor = UIColor.random()
        material2.diffuse.contents = prevColor
        material2.name = "Color"
        
        let node1st = SCNNode(geometry: box2)
        node1st.geometry?.materials = [material2]
        node1st.position = prevPos
        node1st.position.y = prevPos.y + Float(box_height)
        node1st.name = "Block\(height)"
        
        prevPos = node1st.position
        
        sceneView.scene.rootNode.addChildNode(node1st)
        
    }
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !(anchor is ARPlaneAnchor) {
            return
        }
        
        
        let plane = OverlayPlane(anchor: anchor as! ARPlaneAnchor)
        self.planes.append(plane)
        node.addChildNode(plane)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        let plane = self.planes.filter { plane in
            return plane.anchor.identifier == anchor.identifier
            }.first
        
        if plane == nil {
            return
        }
        
        plane?.update(anchor: anchor as! ARPlaneAnchor)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal
        

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
}


extension ViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        let maxLimit_z : Float = prevPos.z + (moveMaxLimit/2)
        let minLimit_z : Float = prevPos.z - (moveMaxLimit/2)
        
        let maxLimit_x : Float = prevPos.x + (moveMaxLimit/2)
        let minLimit_x : Float = prevPos.x - (moveMaxLimit/2)
        
        
        for node in sceneView.scene.rootNode.childNodes {
            if node.presentation.position.y <= -20 {
                node.removeFromParentNode()
            }
        }
        
        if let currentNode = sceneView.scene.rootNode.childNode(withName: "Block\(height)", recursively: false) {
            
            if height % 2 == 0 {
                if currentNode.position.z >= maxLimit_z {
                    direction = false
                } else if currentNode.position.z <= minLimit_z {
                    direction = true
                }
                
                switch direction {
                case true:
                    currentNode.position.z += 0.015
                case false:
                    currentNode.position.z -= 0.015
                }
            } else {
                if currentNode.position.x >= maxLimit_x {
                    direction = false
                } else if currentNode.position.x <= minLimit_x {
                    direction = true
                }
                
                switch direction {
                case true:
                    currentNode.position.x += 0.015
                case false:
                    currentNode.position.x -= 0.015
                }
            }
        }
    }
}

