//
//  ViewController.swift
//  SlidePuzzle
//
//  Created by Tran Le Phu on 10/15/15.
//  Copyright © 2015 LePhuTran. All rights reserved.
//

import CoreData
import UIKit
import AVFoundation
import iAd

class ViewController: UIViewController, ADBannerViewDelegate, UIPopoverPresentationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var hudView:UIView!
    var playView:UIView!
    var settingsView:UIView!
    var imageFrame:UIView!
    
    // Set scale variable for multiple resolutions
    var scaleWidth:CGFloat!
    var scaleHeight:CGFloat!
    
    // NSData to save image in Core Data
    var imageData:NSData!
    
    var rows:Int!
    var columns:Int!
    var numOfCells:Int!
    var newNumOfCells:Int!
    
    // Variables to calculate cell's length and position
    var cellLength:CGFloat!
    let gapBetweenSubImgs:CGFloat = 1
    
    //Variable to retrieve cell touched number
    var numCellTouched = -1
    
    // ImageViews to contain image loaded and to split into small tiles
    var subImages:[UIImage]!
    var subImgViews:[UIImageView]!
    var shuffledCells:[PuzzleCell]!
    var imageView:UIImageView!
    
    // Labels for move and count
    var moveCountLabel:UILabel!
    var timerCountLabel:UILabel!
    
    var hasImgLoaded:Bool!
    var isPreview:Bool! = false
    var isStarted:Bool! = false
    var isShowNumber:Bool!
    var isTurnOnSound:Bool!
    var isChangeNumOfCells:Bool! = false
    
    var move:Int! = 0
    var minute:Int! = 0
    var second:Int! = 0
    var counter:NSTimer!
    
    // iAd banner
    var bannerView:ADBannerView!
    
    let settingsButton = UIButton(type: .System)
    
    let showNumSwitch = UISwitch()
    let soundSwitch = UISwitch()
    var segmentControl:UISegmentedControl!
    
    // Sound Player
    var slidingSoundPlayer:AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print(self.view.frame)
        scaleWidth = self.view.frame.width / 375.0
        scaleHeight = self.view.frame.height / 667.0

        self.view.backgroundColor = UIColor.whiteColor()
        
        getCoreData()
        prepareAudios()

        setupBanner()
        setupPlayView()
        setupHUD()
        
        //Function to check when the appication entering background
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("myObserverMethod:"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
    }
    
    // Create audio player
    func prepareAudios() {
        
        slidingSoundPlayer = AVAudioPlayer()
        let path = NSString(string: NSBundle.mainBundle().pathForResource("SlidingSound", ofType: "mp3")!)
        do {
            slidingSoundPlayer = try AVAudioPlayer(contentsOfURL: NSURL(string: path as String)!, fileTypeHint: nil)
            slidingSoundPlayer.prepareToPlay()
        } catch {
            
        }
    }
    
    // Function to create and retrieve Core Data properties
    func getCoreData() {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext
        
        let request = NSFetchRequest(entityName: "Data")
        request.returnsObjectsAsFaults = false
    
        do {
            let results = try context.executeFetchRequest(request) as NSArray
            
            if results.count == 0 {
                let newUser = NSEntityDescription.insertNewObjectForEntityForName("Data", inManagedObjectContext: context) as NSManagedObject
                
                newUser.setValue(9, forKey: "numOfCells")
                numOfCells = 9
                newNumOfCells = numOfCells
                rows = Int(sqrt(Double(numOfCells)))
                columns = rows
                
                newUser.setValue(true, forKey: "isShowNumber")
                isShowNumber = true
                
                newUser.setValue(true, forKey: "isTurnOnSound")
                isTurnOnSound = true
                
                let img = UIImage(named: "angry_birds_cake.jpg")!
                imageData = UIImageJPEGRepresentation(img, 1)
                newUser.setValue(imageData, forKey: "savedImg")
                
                do {
                    try context.save()
                } catch {
                    
                }
                
            } else {
                let result = results[0] as! NSManagedObject
                numOfCells = result.valueForKey("numOfCells") as! Int
                newNumOfCells = numOfCells
                rows = Int(sqrt(Double(numOfCells)))
                columns = rows
                
                isShowNumber = result.valueForKey("isShowNumber") as! Bool
                isTurnOnSound = result.valueForKey("isTurnOnSound") as! Bool
                
                imageData = result.valueForKey("savedImg") as! NSData
                
            }
        } catch {
            
        }
    }
    
    
    // Functions for iAd
    func setupBanner() {
        bannerView = ADBannerView(adType: .Banner)
        bannerView.frame = CGRectMake(0, self.view.frame.maxY - 50 * scaleHeight, self.view.frame.width, 50 * scaleHeight)
        bannerView.delegate = self
        bannerView.hidden = true
        self.view.addSubview(bannerView)
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        bannerView.hidden = false
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        bannerView.hidden = true
    }
    
    
    // Setup menu buttons
    func setupHUD() {
        
        hudView = UIView(frame: CGRectMake(0, self.bannerView.frame.minY - 50 * scaleHeight, self.view.frame.width, 50 * scaleHeight))
        hudView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(hudView)
        
        
        let photoButton = UIButton(type: .System)
        photoButton.setTitle("New Puzzle", forState: .Normal)
        photoButton.backgroundColor = UIColor.redColor()
        photoButton.titleLabel?.font = UIFont(name: "Edit Undo Line BRK", size: 14 * scaleWidth)
        photoButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        photoButton.addTarget(self, action: "newPuzzle", forControlEvents: .TouchUpInside)
        photoButton.frame = CGRectMake(0, 0, self.view.frame.width / 4, 50 * scaleHeight)
        photoButton.imageView?.contentMode = .ScaleAspectFill
        hudView.addSubview(photoButton)
        
        let boardButton = UIButton(type: .System)
        boardButton.backgroundColor = UIColor.orangeColor()
        boardButton.setTitle("Pictures", forState: .Normal)
        boardButton.titleLabel?.font = UIFont(name: "Edit Undo Line BRK", size: 14 * scaleWidth)
        boardButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        boardButton.addTarget(self, action: "openPhotoSelect", forControlEvents: .TouchUpInside)
        boardButton.frame = CGRectMake(photoButton.frame.maxX, 0, self.view.frame.width / 4, 50 * scaleHeight)
        boardButton.imageView?.contentMode = .ScaleAspectFill
        hudView.addSubview(boardButton)
        
        let previewButton = UIButton(type: .System)
        previewButton.backgroundColor = UIColor.blueColor()
        previewButton.setTitle("Preview", forState: .Normal)
        previewButton.titleLabel?.font = UIFont(name: "Edit Undo Line BRK", size: 14 * scaleWidth)
        previewButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        previewButton.addTarget(self, action: "preview", forControlEvents: .TouchUpInside)
        previewButton.frame = CGRectMake(boardButton.frame.maxX, 0, self.view.frame.width / 4, 50 * scaleHeight)
        previewButton.imageView?.contentMode = .ScaleAspectFill
        hudView.addSubview(previewButton)
        
        settingsButton.backgroundColor = UIColor.purpleColor()
        settingsButton.setTitle("Settings", forState: .Normal)
        settingsButton.titleLabel?.font = UIFont(name: "Edit Undo Line BRK", size: 14 * scaleWidth)
        settingsButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        settingsButton.addTarget(self, action: "openSettings", forControlEvents: .TouchUpInside)
        settingsButton.frame = CGRectMake(previewButton.frame.maxX, 0, self.view.frame.width / 4, 50 * scaleHeight)
        settingsButton.imageView?.contentMode = .ScaleAspectFill
        hudView.addSubview(settingsButton)
    }
    
    // Setup Play View
    func setupPlayView() {
        
        // Create a View to put slide puzzle
        playView = UIView(frame: CGRectMake(0, 20, self.view.frame.width, self.view.frame.height - 90 * scaleHeight - 35 * scaleHeight))
        playView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(playView)
        
        
        let label = UILabel(frame: CGRectMake(0, 20 * scaleHeight, self.view.frame.width, 60 * scaleHeight))
        label.font = UIFont(name: "Edit Undo Line BRK", size: 55 * scaleWidth)
        label.textColor = UIColor.yellowColor()
        label.text = "Slide Puzzle"
        label.textAlignment = .Center
        playView.addSubview(label)
        
        
        imageFrame = UIView(frame: CGRectMake(0, label.frame.maxY + 10 * scaleHeight, self.view.frame.width, self.view.frame.width + 80 * scaleHeight))
        imageFrame.backgroundColor = UIColor.whiteColor()
        playView.addSubview(imageFrame)
        
        let moveLabel:UILabel = UILabel(frame: CGRectMake(playView.frame.minX + 10 * scaleWidth, playView.frame.maxY - 85 * scaleHeight, 120 * scaleWidth, 50 * scaleHeight))
        moveLabel.text = "Move:"
        moveLabel.textAlignment = .Center
        moveLabel.font = UIFont(name: "Edit Undo Line BRK", size: 40 * scaleWidth)
        moveLabel.textColor = UIColor.blackColor()
        playView.addSubview(moveLabel)
        
        moveCountLabel = UILabel(frame: CGRectMake(moveLabel.frame.maxX + 10 * scaleWidth, playView.frame.maxY - 85 * scaleHeight, 50 * scaleWidth, 50 * scaleHeight))
        moveCountLabel.text = "00"
        moveCountLabel.textAlignment = .Left
        moveCountLabel.font = UIFont(name: "Edit Undo Line BRK", size: 40 * scaleWidth)
        moveCountLabel.textColor = UIColor.redColor()
        playView.addSubview(moveCountLabel)
        
        
        timerCountLabel = UILabel(frame: CGRectMake(playView.frame.maxX - 130 * scaleWidth, playView.frame.maxY - 85 * scaleHeight, 120 * scaleWidth, 50 * scaleHeight))
        timerCountLabel.text = "00:00"
        timerCountLabel.textAlignment = .Left
        timerCountLabel.font = UIFont(name: "Edit Undo Line BRK", size: 40 * scaleWidth)
        timerCountLabel.textColor = UIColor.blackColor()
        playView.addSubview(timerCountLabel)

        
        // Set up cell's width for iphone 4s and other devices' resolution
        if self.view.frame.height <= 480 {
            
            let imageViewMinX:CGFloat = 30 * scaleWidth
            let imageViewWidth = (self.view.frame.width / 2 - imageViewMinX) * 2 + gapBetweenSubImgs * CGFloat(columns)
            let imageViewMinY:CGFloat = self.imageFrame.frame.minY + 10 * scaleWidth
            
            imageView = UIImageView(frame: CGRectMake(imageViewMinX - gapBetweenSubImgs * CGFloat(columns), imageViewMinY, imageViewWidth, imageViewWidth))
        } else {
            
            let imageViewMinX:CGFloat = 20 * scaleWidth
            let imageViewWidth = (self.view.frame.width / 2 - imageViewMinX) * 2 + gapBetweenSubImgs * CGFloat(columns)
            let imageViewMinY:CGFloat = self.imageFrame.frame.minY + imageViewMinX
            
            imageView = UIImageView(frame: CGRectMake(imageViewMinX - gapBetweenSubImgs * CGFloat(columns), imageViewMinY, imageViewWidth, imageViewWidth))
        }
        
        playView.addSubview(imageView)
        
        loadPhoto()
        
    }
    
    // Load Photo to ImageView and then split into small tiles
    func loadPhoto() {
        
        let img = UIImage(data: imageData)!
        imageView.clipsToBounds = true
        imageView.contentMode = .ScaleAspectFit
        imageView.image = img
        hasImgLoaded = true
        
        if counter != nil {
            counter.invalidate()
            counter = nil
        }
        
        if hasImgLoaded == true {
            splitPhoto()
        }
    }
    
    //Function to resize photo using Core Image to fit into ImageView
    func resizeLoadedPhoto(image img:UIImage) -> UIImage {
        
        let image = img.CGImage
        
        let width = CGImageGetWidth(image) * Int(imageView.frame.width) / CGImageGetWidth(image)
        let height = CGImageGetHeight(image) * Int(imageView.frame.height) / CGImageGetHeight(image)
        
        let bitsPerComponent = CGImageGetBitsPerComponent(image)
        let bytesPerRow = CGImageGetBytesPerRow(image)
        let colorSpace = CGImageGetColorSpace(image)
        let bitmapInfo = CGImageGetBitmapInfo(image).rawValue
        
        let context = CGBitmapContextCreate(nil, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
        CGContextSetInterpolationQuality(context, .High)
        CGContextDrawImage(context, CGRect(origin: CGPointZero, size: CGSize(width: CGFloat(width), height: CGFloat(height))), image)
        
        let scaledImage = UIImage(CGImage: CGBitmapContextCreateImage(context)!)
        
        return scaledImage
    }
    
    // Functions to create puzzled cells
    func splitPhoto() {
        subImages = splitImagesIntoSubImagesWithNumberOfRows(image: imageView.image!, rows: rows, numberOfColumns: columns)
        
        imageView.removeFromSuperview()
        
        setCorrectPosForCells()
        createPuzzledCells()
        createBlankCell()
    }
    
    func splitImagesIntoSubImagesWithNumberOfRows(image img: UIImage, rows: Int, numberOfColumns clms: Int) -> [UIImage] {
        
        var subImagesTemp:[UIImage] = [UIImage](count: numOfCells, repeatedValue: UIImage())
        
        let imageSize = imageView.frame.size
        var xPos:CGFloat = 0.0, yPos:CGFloat = 0.0
        let width:CGFloat = imageSize.width / CGFloat(clms)
        let height:CGFloat = imageSize.height / CGFloat(rows)
        
        var i = -1
        for _ in 0...rows-1 {
            xPos = 0.0
            for _ in 0...clms-1 {
                i += 1
                let rect:CGRect = CGRectMake(xPos, yPos, width, height)
                let cImage = CGImageCreateWithImageInRect(img.CGImage, rect)
                let dImage = UIImage(CGImage: cImage!)
                subImagesTemp.insert(dImage, atIndex: i)
                xPos += width
            }
            yPos += height
        }
        return subImagesTemp
    }
    
    func setCorrectPosForCells() {
        
        subImgViews = [UIImageView](count: numOfCells, repeatedValue: UIImageView())

        shuffledCells = [PuzzleCell](count: numOfCells, repeatedValue: PuzzleCell())
        
        cellLength = imageView.frame.size.width / CGFloat(columns)

        var i = -1
        for y in 0...rows-1 {
            for x in 0...columns-1 {
                i += 1
                let imgView = UIImageView(image: subImages[i])
                subImgViews.insert(imgView, atIndex: i)
                let subImgViewX = imageView.frame.origin.x + (cellLength + gapBetweenSubImgs) * CGFloat(x)
                let subImgViewY = imageView.frame.origin.y + (cellLength + gapBetweenSubImgs) * CGFloat(y)
                subImgViews[i].contentMode = .ScaleAspectFill
                subImgViews[i].frame = CGRectMake(subImgViewX, subImgViewY, cellLength, cellLength)
                
//                playView.addSubview(subImgViews[i])
            }
        }
    }
    
    func createPuzzledCells() {

        var mang = [Int](count: numOfCells, repeatedValue: 1)
        for i in 0...mang.count-1 {
            mang[i] = i
        }

        var r = -1
        repeat {

            let y = Int(arc4random_uniform(UInt32(mang.count)))
            r += 1
            
            shuffledCells[r] = PuzzleCell(imageView: subImgViews[mang[y]])
                
            shuffledCells[r].correctNum = mang[y]
        
            shuffledCells[r].currentNum = r
            
            if isShowNumber == true {
                shuffledCells[r].posLabel.text = String(shuffledCells[r].correctNum + 1)
            } else {
                shuffledCells[r].posLabel.text = ""
            }
        
            mang.removeAtIndex(y)
        } while mang.count > 0
        
        // To check winning condition
//        for i in 0...mang.count-1 {
//            shuffledCells[i] = PuzzleCell(imageView: subImgViews[i])
//            shuffledCells[i].correctNum = i
//            
//            shuffledCells[i].currentNum = i
//            
//            if isShowNumber == true {
//                shuffledCells[i].posLabel.text = String(shuffledCells[i].correctNum + 1)
//            } else {
//                shuffledCells[i].posLabel.text = ""
//            }
//
//        }

        r = -1
        for y in 0...rows-1 {
            for x in 0...columns-1 {
                
                r += 1
                
                let shuffledCellX = imageView.frame.origin.x + (cellLength + gapBetweenSubImgs) * CGFloat(x)
                
                let shuffledCellY = imageView.frame.origin.y + (cellLength + gapBetweenSubImgs) * CGFloat(y)
                
                shuffledCells[r].frame = CGRectMake(shuffledCellX, shuffledCellY, cellLength, cellLength)
                shuffledCells[r].isBlankCell = false
                self.playView.addSubview(shuffledCells[r])
                
                shuffledCells[r].layer.borderColor = UIColor.blueColor().CGColor
                shuffledCells[r].layer.borderWidth = gapBetweenSubImgs
                shuffledCells[r].layer.cornerRadius = 5.0
                shuffledCells[r].clipsToBounds = true
            }
        }
    }
    
    func createBlankCell() {
        
        let x = Int(arc4random_uniform(UInt32(numOfCells)))
        shuffledCells[x].removeFromSuperview()
        shuffledCells[x].isBlankCell = true
    }
    
    
    // Functions to move cells on touch
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if hasImgLoaded == true {
            for touch in touches {
                let currentPoint = touch.locationInView(self.view)
                
                for i in 0...numOfCells-1 {
                    if shuffledCells[i].frame.contains(currentPoint) {
                        numCellTouched = i
                        if shuffledCells[numCellTouched].isBlankCell != true {
                            updateMoveCounter()
                        }
                        checkNearbyCells(shuffledCells[numCellTouched], cellTouched: numCellTouched)
                        if isStarted == false {
                            checkTimerStatus()
                        }
                        break
                    }
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        numCellTouched = -1
    }
    
    func checkNearbyCells(chosenCell : PuzzleCell, cellTouched currentNum: Int) {

        let cellLengthMove = cellLength + gapBetweenSubImgs
        
        var tempNum:Int

        if currentNum == numOfCells - self.columns { // numOfCells - columns = 6 [2,0]
            
            if self.shuffledCells[currentNum + 1].isBlankCell == true { // currentNum + 1 = 7 [2,1]
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, cellLengthMove, 0)
                    self.shuffledCells[currentNum + 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + 1].transform, -cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + 1]
                self.shuffledCells[currentNum + 1] = chosenCell
                
                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
                
            } else if self.shuffledCells[currentNum - self.columns].isBlankCell == true { // currentNum - columns = 3 [1,0]
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, -cellLengthMove)
                    self.shuffledCells[currentNum - self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - self.columns].transform, 0, cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - self.columns]
                self.shuffledCells[currentNum - self.columns] = chosenCell
                
                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            }
            
        } else if currentNum == numOfCells - 1 { //numOfCells = 8 [2,2]
            
            if self.shuffledCells[currentNum - 1].isBlankCell == true { //currentNum - 1 = 7 [2,1]
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, -cellLengthMove, 0)
                    self.shuffledCells[currentNum - 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - 1].transform, cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - 1]
                self.shuffledCells[currentNum - 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum - self.columns].isBlankCell == true { // currentNum - columns = 5 [1,2]
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, -cellLengthMove)
                    self.shuffledCells[currentNum - self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - self.columns].transform, 0, cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - self.columns]
                self.shuffledCells[currentNum - self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            }
            
        } else if currentNum == 0 { // [0,0] 0
            
            if self.shuffledCells[currentNum + 1].isBlankCell == true { //[0,1] 1
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, cellLengthMove, 0)
                    self.shuffledCells[currentNum + 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + 1].transform, -cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + 1]
                self.shuffledCells[currentNum + 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum + self.columns].isBlankCell == true { //[1,0] 3
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, cellLengthMove)
                    self.shuffledCells[currentNum + self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + self.columns].transform, 0, -cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + self.columns]
                self.shuffledCells[currentNum + self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            }
            
        } else if currentNum == self.columns - 1 { // [0,3] 2
            
            if self.shuffledCells[currentNum - 1].isBlankCell == true { //currentNum - 1 = 1 [0,1]
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, -cellLengthMove, 0)
                    self.shuffledCells[currentNum - 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - 1].transform, cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - 1]
                self.shuffledCells[currentNum - 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum + self.columns].isBlankCell == true { //[1,2] 5
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, cellLengthMove)
                    self.shuffledCells[currentNum + self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + self.columns].transform, 0, -cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + self.columns]
                self.shuffledCells[currentNum + self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            }
            
        } else if currentNum > 0 && currentNum < self.columns { // [0,1] 1
            
            if self.shuffledCells[currentNum - 1].isBlankCell == true { //[0,0] 0
            
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, -cellLengthMove, 0)
                    self.shuffledCells[currentNum - 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - 1].transform, cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - 1]
                self.shuffledCells[currentNum - 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum + 1].isBlankCell == true { // [0,2] 2
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, cellLengthMove, 0)
                    self.shuffledCells[currentNum + 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + 1].transform, -cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + 1]
                self.shuffledCells[currentNum + 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum + self.columns].isBlankCell == true { // [1,1] 4
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, cellLengthMove)
                    self.shuffledCells[currentNum + self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + self.columns].transform, 0, -cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + self.columns]
                self.shuffledCells[currentNum + self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            }
            
        } else if currentNum < numOfCells - 1 && currentNum > numOfCells - self.columns { // [2,1] 7
            
            if self.shuffledCells[currentNum - 1].isBlankCell == true { //[2,0] 6
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, -cellLengthMove, 0)
                    self.shuffledCells[currentNum - 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - 1].transform, cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - 1]
                self.shuffledCells[currentNum - 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum + 1].isBlankCell == true { // [2,2] 8
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, cellLengthMove, 0)
                    self.shuffledCells[currentNum + 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + 1].transform, -cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + 1]
                self.shuffledCells[currentNum + 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum - self.columns].isBlankCell == true { // [1,1] 4
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, -cellLengthMove)
                    self.shuffledCells[currentNum - self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - self.columns].transform, 0, cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - self.columns]
                self.shuffledCells[currentNum - self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }            }
            
        } else if currentNum % self.columns == 0 { // [1,0] 3
            
            if self.shuffledCells[currentNum + self.columns].isBlankCell == true { // [0,0] 0
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, cellLengthMove)
                    self.shuffledCells[currentNum + self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + self.columns].transform, 0, -cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + self.columns]
                self.shuffledCells[currentNum + self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum + 1].isBlankCell == true { // [1,1] 4
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, cellLengthMove, 0)
                    self.shuffledCells[currentNum + 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + 1].transform, -cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + 1]
                self.shuffledCells[currentNum + 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum - self.columns].isBlankCell == true { // [1,2] 6
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, -cellLengthMove)
                    self.shuffledCells[currentNum - self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - self.columns].transform, 0, cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - self.columns]
                self.shuffledCells[currentNum - self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }            }

        } else if currentNum % self.columns == 2 { // [1,2] 5
            
            if self.shuffledCells[currentNum + self.columns].isBlankCell == true { // [0,2] 2
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, cellLengthMove)
                    self.shuffledCells[currentNum + self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + self.columns].transform, 0, -cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + self.columns]
                self.shuffledCells[currentNum + self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum - 1].isBlankCell == true { //[1,1] 4
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, -cellLengthMove, 0)
                    self.shuffledCells[currentNum - 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - 1].transform, cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - 1]
                self.shuffledCells[currentNum - 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum - self.columns].isBlankCell == true { // [2,2] 8
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, -cellLengthMove)
                    self.shuffledCells[currentNum - self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - self.columns].transform, 0, cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - self.columns]
                self.shuffledCells[currentNum - self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum + 1].isBlankCell == true { // [1,1] 4
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, cellLengthMove, 0)
                    self.shuffledCells[currentNum + 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + 1].transform, -cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + 1]
                self.shuffledCells[currentNum + 1] = chosenCell
                
                tempNum = shuffledCells[currentNum].currentNum
                
                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }            }
            
        } else { // [1,1] 4
            
            if self.shuffledCells[currentNum + self.columns].isBlankCell == true { // [0,1] 1
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, cellLengthMove)
                    self.shuffledCells[currentNum + self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + self.columns].transform, 0, -cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + self.columns]
                self.shuffledCells[currentNum + self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + self.columns].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum - 1].isBlankCell == true { //[1,0] 3
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, -cellLengthMove, 0)
                    self.shuffledCells[currentNum - 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - 1].transform, cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - 1]
                self.shuffledCells[currentNum - 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum - self.columns].isBlankCell == true { // [2,1] 7
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, 0, -cellLengthMove)
                    self.shuffledCells[currentNum - self.columns].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum - self.columns].transform, 0, cellLengthMove)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum - self.columns]
                self.shuffledCells[currentNum - self.columns] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum - self.columns].currentNum = tempNum

                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }
            } else if self.shuffledCells[currentNum + 1].isBlankCell == true { // [1,2] 5
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    chosenCell.transform = CGAffineTransformTranslate(chosenCell.transform, cellLengthMove, 0)
                    self.shuffledCells[currentNum + 1].transform = CGAffineTransformTranslate(self.shuffledCells[currentNum + 1].transform, -cellLengthMove, 0)
                })
                self.shuffledCells[currentNum] = shuffledCells[currentNum + 1]
                self.shuffledCells[currentNum + 1] = chosenCell

                tempNum = shuffledCells[currentNum].currentNum

                self.shuffledCells[currentNum].currentNum = currentNum
                self.shuffledCells[currentNum + 1].currentNum = tempNum
                
                if isTurnOnSound == true {
                    self.slidingSoundPlayer.play()
                }            }
        }

        checkCorrectPos()
    }
    
    // Check the winning condition
    func checkCorrectPos() {
 
        for i in 0...numOfCells-1 {
            
            if shuffledCells[i].currentNum == shuffledCells[i].correctNum {
                shuffledCells[i].isCorrectNum = true
            } else {
                shuffledCells[i].isCorrectNum = false
            }
        }
        
        var checkPoint:Bool = false
        for i in 0...numOfCells-1 {
            if shuffledCells[i].isCorrectNum == false {
                checkPoint = false
                break
            }
            checkPoint = true
        }
        
        if checkPoint == true {
            print("You have won")
            finishGame()
        } else {
            print("You have not completed yet")
        }
    }
    
    func finishGame() {
        
        counter.invalidate()
        
        let stringKetQua = "Congratulation, You have finished the puzzle with " + self.moveCountLabel.text! + " moves and in " + self.timerCountLabel.text!
        
        let alertController = UIAlertController(title: "Slize Puzzle", message: stringKetQua, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addAction(UIAlertAction(title: "Start new game", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            let newView = ViewController()
            self.presentViewController(newView, animated: false, completion: nil)
        }))
        
        self.presentViewController(alertController, animated:true, completion:nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Functions for Preview Button
    func preview() {
        if isPreview == false {
            moveToCorrectNum(shuffledCells)
        }
    }
    
    func moveToCorrectNum(cells : [PuzzleCell]) {
        
        isPreview = true
        
        var currentCellX:[CGFloat] = [CGFloat](count: numOfCells, repeatedValue: 0)
        var currentCellY:[CGFloat] = [CGFloat](count: numOfCells, repeatedValue: 0)
        
        UIView.animateWithDuration(0.5) { () -> Void in
            for i in 0...self.numOfCells-1 {
                
                currentCellX[i] = cells[i].frame.origin.x
                currentCellY[i] = cells[i].frame.origin.y
                
                let cellCorectNum = cells[i].correctNum
                let cellX:CGFloat = self.subImgViews[cellCorectNum].frame.origin.x - currentCellX[i]
                
                let cellY = self.subImgViews[cellCorectNum].frame.origin.y - currentCellY[i]
                
                cells[i].transform = CGAffineTransformTranslate(cells[i].transform, cellX, cellY)
                
                if cells[i].isBlankCell == true {
                    self.playView.addSubview(self.shuffledCells[i])
                }
                
            }
        }
        
        UIView.animateWithDuration(0.5, delay: 3, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            for i in 0...self.numOfCells-1 {
                
                let cellX:CGFloat =  currentCellX[i] - cells[i].frame.origin.x
                
                let cellY = currentCellY[i] - cells[i].frame.origin.y
                
                cells[i].transform = CGAffineTransformTranslate(cells[i].transform, cellX, cellY)
                
            }
            }) { (finished) -> Void in
                for i in 0...self.numOfCells-1 {
                    if cells[i].isBlankCell == true {
                        self.shuffledCells[i].removeFromSuperview()
                    }
                }
                self.isPreview = false
        }
    }
    
    // Functions for Pictures Button
    func openPhotoSelect() {
        
        let alertController = UIAlertController(title: "Slize Puzzle", message: "Please choose source to load pictures", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.openCamera()
        }))
        
        alertController.addAction(UIAlertAction(title: "Library", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            self.openLibrary()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated:true, completion:nil)
    }
    
    func openLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.allowsEditing = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.allowsEditing = true
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        var imgData = UIImageJPEGRepresentation(image, 1)
        
        let img = UIImage(data: imgData!)!
        let scaledImage = resizeLoadedPhoto(image: img)
        
        imgData = UIImageJPEGRepresentation(scaledImage, 1)
        
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext
        
        let request = NSFetchRequest(entityName: "Data")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.executeFetchRequest(request)
            let result = results[0] as! NSManagedObject
            result.setValue(imgData, forKey: "savedImg")
            try context.save()
        } catch {
            
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        let view = ViewController()
        self.presentViewController(view, animated: false, completion: nil)
        
    }
    
    
    //Function for New Puzzle Button
    func newPuzzle() {
        
        let alertController = UIAlertController(title: "Slize Puzzle", message: "Are you sure to create new puzzle?", preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "Create", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            let newView = ViewController()
            self.presentViewController(newView, animated: false, completion: nil)
        }))
        
        self.presentViewController(alertController, animated:true, completion:nil)
    }
    
    
    // Functions for Settings Button
    func openSettings() {
        
        if counter != nil {
            counter.invalidate()
        }
        
        settingsView = UIView()
        settingsView.backgroundColor = UIColor.blackColor()
        settingsView.frame = CGRectMake(0, 20, self.view.frame.width, self.view.frame.height - self.bannerView.frame.height - 20)
        self.view.addSubview(settingsView)
        
        
        let hudSettingsView = UIView(frame: CGRectMake(0, settingsView.frame.maxY - 50 * scaleHeight - settingsView.frame.origin.y, self.view.frame.width, 50 * scaleHeight))
        hudSettingsView.backgroundColor = UIColor.blueColor()
        settingsView.addSubview(hudSettingsView)
        
        
        let cancelButton = UIButton(type: .System)
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.backgroundColor = UIColor.redColor()
        cancelButton.titleLabel?.font = UIFont(name: "Edit Undo Line BRK", size: 14 * scaleWidth)
        cancelButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        cancelButton.addTarget(self, action: "cancelSettings", forControlEvents: .TouchUpInside)
        cancelButton.frame = CGRectMake(0, settingsView.frame.maxY - 50 * scaleHeight - settingsView.frame.origin.y, self.view.frame.width / 2, 50 * scaleHeight)
        cancelButton.imageView?.contentMode = .ScaleAspectFill
        settingsView.addSubview(cancelButton)
        
        let saveButton = UIButton(type: .System)
        saveButton.backgroundColor = UIColor.orangeColor()
        saveButton.setTitle("Save", forState: .Normal)
        saveButton.titleLabel?.font = UIFont(name: "Edit Undo Line BRK", size: 14 * scaleWidth)
        saveButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        saveButton.addTarget(self, action: "saveSettings", forControlEvents: .TouchUpInside)
        saveButton.frame = CGRectMake(cancelButton.frame.maxX, settingsView.frame.maxY - 50 * scaleHeight - settingsView.frame.origin.y, self.view.frame.width / 2, 50 * scaleHeight)
        saveButton.imageView?.contentMode = .ScaleAspectFill
        settingsView.addSubview(saveButton)
    
        
        segmentControl = UISegmentedControl(items: ["3x3", "4x4", "5x5"])
        if newNumOfCells == 9 {
            segmentControl.selectedSegmentIndex = 0
        } else if newNumOfCells == 16 {
            segmentControl.selectedSegmentIndex = 1
        } else if newNumOfCells == 25 {
            segmentControl.selectedSegmentIndex = 2
        }
        segmentControl.frame = CGRectMake(settingsView.frame.maxX - 210 * scaleWidth, settingsView.frame.minY + 50 * scaleHeight, 200 * scaleWidth, 50 * scaleHeight)
        segmentControl.layer.cornerRadius = 5.0
        segmentControl.backgroundColor = UIColor.greenColor()
        segmentControl.tintColor = UIColor.redColor()
        segmentControl.addTarget(self, action: "setNumOfRowsAndColumns:", forControlEvents: UIControlEvents.ValueChanged)
        settingsView.addSubview(segmentControl)
        
        
        let chooseNumOfCellsLabel = UILabel();
        chooseNumOfCellsLabel.frame = CGRectMake(settingsView.frame.minX + 10 * scaleWidth, segmentControl.frame.midY - 15 * scaleHeight, 300 * scaleWidth, 30 * scaleHeight)
        chooseNumOfCellsLabel.text = "Puzzle Size"
        chooseNumOfCellsLabel.font = UIFont(name: "Edit Undo Line BRK", size: 18 * scaleWidth)
        chooseNumOfCellsLabel.textColor = UIColor.whiteColor()
        settingsView.addSubview(chooseNumOfCellsLabel)
        
        showNumSwitch.frame = CGRectMake(segmentControl.frame.maxX - 50 * scaleWidth, segmentControl.frame.maxY + 10, 0, 0)
        if isShowNumber == true {
            showNumSwitch.on = true
            showNumSwitch.setOn(true, animated: false)
        } else {
            showNumSwitch.on = false
            showNumSwitch.setOn(false, animated: false)
        }
        showNumSwitch.addTarget(self, action: "showNumSwitchValueDidChange:", forControlEvents: .ValueChanged)
        settingsView.addSubview(showNumSwitch)
        
        let showNumLabel = UILabel();
        showNumLabel.frame = CGRectMake(chooseNumOfCellsLabel.frame.minX, showNumSwitch.frame.midY - 15 * scaleHeight, 300 * scaleWidth, 30 * scaleHeight)
        showNumLabel.text = "Display cell numbers"
        showNumLabel.font = UIFont(name: "Edit Undo Line BRK", size: 18 * scaleWidth)
        showNumLabel.textColor = UIColor.whiteColor()
        settingsView.addSubview(showNumLabel)
        
        
        soundSwitch.frame = CGRectMake(segmentControl.frame.maxX - 50 * scaleWidth, showNumSwitch.frame.maxY + 10, 0, 0)
        if isTurnOnSound == true {
            soundSwitch.on = true
            soundSwitch.setOn(true, animated: false)
        } else {
            soundSwitch.on = false
            soundSwitch.setOn(false, animated: false)
        }
        soundSwitch.addTarget(self, action: "soundSwitchValueDidChange:", forControlEvents: .ValueChanged)
        settingsView.addSubview(soundSwitch)
        
        let soundLabel = UILabel();
        soundLabel.frame = CGRectMake(showNumLabel.frame.minX, soundSwitch.frame.midY - 15 * scaleHeight, 150 * scaleWidth, 30 * scaleHeight)
        soundLabel.text = "Play sound"
        soundLabel.font = UIFont(name: "Edit Undo Line BRK", size: 18 * scaleWidth)
        soundLabel.textColor = UIColor.whiteColor()
        settingsView.addSubview(soundLabel)
        
    }
    
    func cancelSettings() {
        settingsView.removeFromSuperview()
        checkTimerStatus()
    }
    
    func saveSettings() {
        
        for i in 0...self.shuffledCells.count-1 {
            if (isShowNumber == false) {
                self.shuffledCells[i].posLabel.text = ""
            } else {
                self.shuffledCells[i].posLabel.text = String(shuffledCells[i].correctNum + 1)
            }
        }
        
        settingsView.removeFromSuperview()
        checkTimerStatus()
        
        if isChangeNumOfCells == true {
            let newView = ViewController()
            self.presentViewController(newView, animated: false, completion: nil)
        }
        
        
    }
    
    func showNumSwitchValueDidChange(sender: UISwitch) {

        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext
        
        let request = NSFetchRequest(entityName: "Data")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.executeFetchRequest(request) as NSArray
            let result = results[0] as! NSManagedObject
            
            if sender.on == true {
                isShowNumber = true
            } else {
                isShowNumber = false
            }
            result.setValue(isShowNumber, forKey: "isShowNumber")
        
            try context.save()
        } catch {
            
        }
        
    }
    
    func soundSwitchValueDidChange(sender: UISwitch) {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext
        
        let request = NSFetchRequest(entityName: "Data")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.executeFetchRequest(request) as NSArray
            let result = results[0] as! NSManagedObject
            
            if sender.on == true {
                isTurnOnSound = true
            } else {
                isTurnOnSound = false
            }
            result.setValue(isTurnOnSound, forKey: "isTurnOnSound")
            try context.save()
        } catch {
            
        }
    }
    
    func setNumOfRowsAndColumns(sender: UISegmentedControl) {
        
        let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context:NSManagedObjectContext = appDel.managedObjectContext

        let request = NSFetchRequest(entityName: "Data")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.executeFetchRequest(request) as NSArray
            let result = results[0] as! NSManagedObject
            
            switch sender.selectedSegmentIndex {
                
            case 0:
                result.setValue(9, forKey: "numOfCells")
                newNumOfCells = 9
                if newNumOfCells != numOfCells {
                    isChangeNumOfCells = true
                } else {
                    isChangeNumOfCells = false
                }
                
                
                break
                
            case 1:
                result.setValue(16, forKey: "numOfCells")
                newNumOfCells = 16
                if newNumOfCells != numOfCells {
                    isChangeNumOfCells = true
                } else {
                    isChangeNumOfCells = false
                }
                break
                
            case 2:
                result.setValue(25, forKey: "numOfCells")
                newNumOfCells = 25
                if newNumOfCells != numOfCells {
                    isChangeNumOfCells = true
                } else {
                    isChangeNumOfCells = false
                }
                break
                
            default:
                
                break
            }
            
            try context.save()

        } catch {
            
        }
    }
    
    //Functin to implement Segment Control
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // Function to start, pause and resume counter
    func checkTimerStatus() {
        isStarted = true
        counter = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("startCounter"), userInfo: nil, repeats: true)
    }
    
    func startCounter() {
        if second == 60 {
            second = 0
            minute = minute + 1
        }
        second = second + 1
        
        if minute < 10 {
            if second < 10 {
                timerCountLabel.text = "0" + String(minute) + ":" + "0" + String(second)
            } else {
                timerCountLabel.text = "0" + String(minute) + ":" + String(second)
            }
        } else if minute >= 10 {
            if second < 10 {
                timerCountLabel.text = String(minute) + ":" + "0" + String(second)
            } else {
                timerCountLabel.text = String(minute) + ":" + String(second)
            }
        }
    }
    
    func updateMoveCounter() {
        move = move + 1
        if move < 10 {
            moveCountLabel.text = "0" + String(move)
        } else {
            moveCountLabel.text = String(move)
        }
    }
    
    // Function to check whether app is running background
    func myObserverMethod(notification: NSNotification) {
        print("Observer method called")
        isStarted = false
        self.pauseTimer()
    }
    
    func pauseTimer() {
        counter.invalidate()
    }
}

