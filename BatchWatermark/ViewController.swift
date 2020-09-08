//
//  ViewController.swift
//  BatchWatermark
//
//  Created by Ashutosh Dave on 08/09/20.
//  Copyright © 2020 Ashutosh Dave. All rights reserved.
//

import UIKit
import Photos
import AssetsPickerViewController

class ViewController: UIViewController {
	
	var arrayImages = [UIImage]()
	var processedImages = [UIImage]()
	
	let logoImage = UIImage(named: "logo")
	
	var assets = [PHAsset]()
	lazy var imageManager = {
		return PHCachingImageManager()
	}()
	let requestOptions = PHImageRequestOptions()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		requestOptions.resizeMode = .exact
		requestOptions.deliveryMode = .highQualityFormat
		requestOptions.isSynchronous = true
	}
	
	
	@IBAction func saveClicked(_ sender: UIButton) {
		
		
		
		DispatchQueue(label: "imageQueue", qos: .userInitiated, autoreleaseFrequency: .workItem).async {
			autoreleasepool {
				for image in self.arrayImages {
					self.applyWatermark(actualImage: image) { (image) in
						self.processedImages.append(image)
					}
				}
			}
		}
		print("processed count: \(self.processedImages.count)")
	}
	
	@IBAction func openGallery(_ sender: Any) {
		let picker = AssetsPickerViewController()
		picker.pickerDelegate = self
		
		let pickerConfig = AssetsPickerConfig()
		pickerConfig.albumIsShowEmptyAlbum = false
		pickerConfig.albumIsShowHiddenAlbum = true
		
		
		let options = PHFetchOptions()
		options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
		
		
		pickerConfig.assetFetchOptions = [
			.smartAlbum: options,
			.album: options
		]
		
		picker.pickerConfig = pickerConfig
		present(picker, animated: true, completion: nil)
	}
	
	func applyWatermark(actualImage: UIImage, completionHandler: @escaping (_ images: UIImage) -> ()) {
		
		let logoSize = logoImage!.size
		
		let bounds = CGRect(x: 0, y: 0, width: actualImage.size.width, height: actualImage.size.height)
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
		
		var context = CGContext(
			data: nil,
			width: Int(bounds.width),
			height: Int(bounds.height),
			bitsPerComponent: 8,
			bytesPerRow: 0,
			space: colorSpace,
			bitmapInfo: bitmapInfo
		)
		
		context!.draw(actualImage.cgImage!, in: bounds)
		
		// Invert Y axis
		context!.translateBy(x: bounds.midX, y: bounds.midY)
		context!.scaleBy(x: 1, y: -1)
		context!.translateBy(x: -bounds.midX, y: -bounds.midY)
		
		UIGraphicsPushContext(context!)
		
		logoImage?.draw(in: CGRect(origin: CGPoint(x: 100, y: 100), size: CGSize(width: 600, height: 200)))
		
		UIGraphicsPopContext()
		
		let cgImage = context!.makeImage()!
		let newImage = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
		
		context = nil
		
		UIImageWriteToSavedPhotosAlbum(newImage, self, #selector(ViewController.image(_:withPotentialError:contextInfo:)), nil)
		completionHandler(newImage)
	}
	
	@objc func image(_ image: UIImage, withPotentialError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
		
		print("image save successfully")
	}
}

extension ViewController: AssetsPickerViewControllerDelegate {
	func assetsPicker(controller: AssetsPickerViewController, selected assets: [PHAsset]) {
		
		
		self.assets = assets
		for asset in self.assets {
			imageManager.requestImageData(for: asset, options: self.requestOptions) { (data, _, orientation, info) in
				guard let data = data else {
					
					return
				}
				self.arrayImages.append(UIImage(data: data)!)
			}
			
		}
	}
	
	func assetsPicker(controller: AssetsPickerViewController, shouldSelect asset: PHAsset, at indexPath: IndexPath) -> Bool {
		
		
		return true
	}
	
	func assetsPickerDidCancel(controller: AssetsPickerViewController) {
		
	}
	
}
