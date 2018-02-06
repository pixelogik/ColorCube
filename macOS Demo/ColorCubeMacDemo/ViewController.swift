//
//  ViewController.swift
//  ColorCubeMacDemo
//
//  Created by Guilherme Rambo on 01/01/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import Cocoa
import ColorCube

class ViewController: NSViewController {

    @IBOutlet weak var themeLabel: NSTextField!
    @IBOutlet weak var themePopUp: NSPopUpButton!
    @IBOutlet weak var labelsContainerView: NSView!
    
    var isDarkTheme = true
    
    private var currentImageUrl: URL? {
        didSet {
            if let url = currentImageUrl {
                updateUI(with: url, darkBackground: isDarkTheme)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        updateForTheme(named: "Dark")
        
        if currentImageUrl == nil {
            openImage(nil)
        }
    }
    
    @IBAction func openImage(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png","jpg","jpeg","tif","tiff","psd","pdf"]
        panel.runModal()
        
        if let url = panel.url {
            self.currentImageUrl = url
        }
    }
    
    @IBAction func themePopUpAction(_ sender: Any) {
        guard let selectedTitle = themePopUp.selectedItem?.title else { return }
        
        updateForTheme(named: selectedTitle)
    }
    
    func updateForTheme(named name: String) {
        isDarkTheme = (name == "Dark")
        
        if isDarkTheme {
            view.window?.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        } else {
            view.window?.appearance = NSAppearance(named: NSAppearanceNameAqua)
        }
        
        if let currentImageUrl = currentImageUrl {
            updateUI(with: currentImageUrl, darkBackground: isDarkTheme)
        }
    }
    
    func updateUI(with url: URL, darkBackground: Bool = true) {
        DispatchQueue.global(qos: .userInteractive).async {
            let backgroundFlags = darkBackground ? CCOnlyDarkColors : CCOnlyBrightColors
            let textFlags = darkBackground ? CCOnlyBrightColors : CCOnlyDarkColors
            
            let image = NSImage(contentsOfFile: url.path)
            let cube = CCColorCube()
            
            guard let backgroundColors = cube.extractColors(from: image!, flags: backgroundFlags) else {
                return
            }
            
            let bgColor = backgroundColors.first ?? (darkBackground ? NSColor.black : NSColor.white)
            
            DispatchQueue.main.async {
                self.view.layer?.backgroundColor = bgColor.cgColor
            }
            
            var textColors = cube.extractColors(from: image!, flags: textFlags, avoid: bgColor)
            
            if textColors == nil {
                textColors = cube.extractColors(from: image!, flags: CCOnlyDistinctColors, avoid: bgColor)
            } else if textColors!.count < 2 {
                textColors = cube.extractColors(from: image!, flags: CCOnlyDistinctColors, avoid: bgColor)
            }
            
            DispatchQueue.main.async {
                self.createLabels(with: textColors)
            }
        }
    }
    
    func createLabels(with colors: [NSColor]?) {
        guard let colors = colors else { return }
        
        self.labelsContainerView.subviews.forEach({ $0.removeFromSuperview() })
        
        var previousLabel: NSTextField? = nil
        
        colors.enumerated().forEach { index, color in
            let label = NSTextField(labelWithString: "Color \(index + 1)")
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = color
            label.font = NSFont.systemFont(ofSize: 17.0, weight: NSFontWeightLight)
            
            self.labelsContainerView.addSubview(label)
            
            if let previousLabel = previousLabel {
                label.topAnchor.constraint(equalTo: previousLabel.bottomAnchor, constant: 8).isActive = true
            } else {
                label.topAnchor.constraint(equalTo: self.labelsContainerView.topAnchor, constant: 22.0).isActive = true
            }
            
            label.leadingAnchor.constraint(equalTo: self.labelsContainerView.leadingAnchor, constant: 22.0).isActive = true
            
            previousLabel = label
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

