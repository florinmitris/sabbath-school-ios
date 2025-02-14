/*
 * Copyright (c) 2017 Adventech <info@adventech.io>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import MenuItemKit
import UIKit
import WebKit

struct ReaderStyle {
    enum Theme: String {
        case light
        case sepia
        case dark
        case auto

        static var items: [Theme] {
            return [
                .light,
                .sepia,
                .dark,
                .auto
            ]
        }

        var backgroundColor: UIColor {
            switch self {
            case .light: return AppStyle.Reader.Color.white
            case .sepia: return AppStyle.Reader.Color.sepia
            case .dark: return AppStyle.Reader.Color.dark
            case .auto: return AppStyle.Reader.Color.auto
            }
        }

        var navBarColor: UIColor {
            switch self {
            case .light: return AppStyle.Reader.Color.white
            case .sepia: return AppStyle.Reader.Color.sepia
            case .dark: return AppStyle.Reader.Color.dark
            case .auto: return AppStyle.Reader.Color.auto
            }
        }

        var navBarTextColor: UIColor {
            switch self {
            case .light: return .black
            case .sepia: return .black
            case .dark: return .white
            case .auto:
                return Preferences.darkModeEnable() ? UIColor.white:UIColor.black
            }
        }
    }

    enum Typeface: String {
        case andada
        case lato
        case ptSerif = "pt-serif"
        case ptSans = "pt-sans"

        static var items: [Typeface] {
            return [
                .andada,
                .lato,
                .ptSerif,
                .ptSans
            ]
        }
    }

    enum Size: String, CaseIterable {
        case tiny
        case small
        case medium
        case large
        case huge

        static var items: [Size] {
            return [
                .tiny,
                .small,
                .medium,
                .large,
                .huge
            ]
        }
    }

    enum Highlight: String {
        case green
        case blue
        case orange
        case yellow

        static var items: [Highlight] {
            return [
                .green,
                .blue,
                .orange,
                .yellow
            ]
        }
    }
}

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}

protocol ReaderOutputProtocol: AnyObject {
    func ready()
    func didTapClearHighlight()
    func didTapHighlight(color: String)
    func didTapCopy()
    func didTapShare()
    func didTapLookup()
    func didLoadContent(content: String)
    func didClickVerse(verse: String)
    func didReceiveHighlights(highlights: String)
    func didReceiveComment(comment: String, elementId: String)
    func didReceiveCopy(text: String)
    func didReceiveShare(text: String)
    func didReceiveLookup(text: String)
    func didTapExternalUrl(url: URL)
}

open class Reader: WKWebView {
    weak var readerViewDelegate: ReaderOutputProtocol?
    var menuVisible = false
    var contextMenuEnabled = false

    func createContextMenu() {
        let highlightGreen = UIMenuItem(title: "Green", image: R.image.iconHighlightGreen()) { _ in }
        highlightGreen.action = #selector(didTapHighlightGreen)
        
        let highlightBlue = UIMenuItem(title: "Blue", image: R.image.iconHighlightBlue()) { _ in }
        highlightBlue.action = #selector(didTapHighlightBlue)

        let highlightYellow = UIMenuItem(title: "Yellow", image: R.image.iconHighlightYellow()) { _ in }
        highlightYellow.action = #selector(didTapHighlightYellow)

        let highlightOrange = UIMenuItem(title: "Orange", image: R.image.iconHighlightOrange()) { _ in }
        highlightOrange.action = #selector(didTapHighlightOrange)

        let clearHighlight = UIMenuItem(title: "Clear", image: R.image.iconHighlightClear()) { _ in }
        clearHighlight.action = #selector(didTapClearHighlight)

        let copy = UIMenuItem(title: "Copy".localized()) { _ in }
        copy.action = #selector(didTapCopy)

        let share = UIMenuItem(title: "Share".localized()) { _ in }
        share.action = #selector(didTapShare)
        
        let lookup = UIMenuItem(title: "Look Up".localized()) { _ in }
        lookup.action = #selector(didTapLookup)
        
        let paste = UIMenuItem(title: "Paste".localized()) { _ in }
        paste.action = #selector(paste(_:))

        UIMenuController.shared.menuItems = [highlightGreen, highlightBlue, highlightYellow, highlightOrange, clearHighlight, copy, paste, lookup, share]
    }
    
    // MARK: Context Menu Actions

    @objc func didTapHighlightGreen() {
        readerViewDelegate?.didTapHighlight(color: ReaderStyle.Highlight.green.rawValue)
    }
    
    @objc func didTapHighlightBlue() {
        readerViewDelegate?.didTapHighlight(color: ReaderStyle.Highlight.blue.rawValue)
    }
    
    @objc func didTapHighlightYellow() {
        readerViewDelegate?.didTapHighlight(color: ReaderStyle.Highlight.yellow.rawValue)
    }
    
    @objc func didTapHighlightOrange() {
        readerViewDelegate?.didTapHighlight(color: ReaderStyle.Highlight.orange.rawValue)
    }
    
    @objc func didTapClearHighlight() {
        readerViewDelegate?.didTapClearHighlight()
    }
    
    @objc func didTapCopy() {
        readerViewDelegate?.didTapCopy()
    }
    
    @objc func didTapShare() {
        readerViewDelegate?.didTapShare()
    }
    
    @objc func didTapLookup() {
        readerViewDelegate?.didTapLookup()
    }

    func setupContextMenu() {
        createContextMenu()
        showContextMenu()
    }

    func showContextMenu() {
        let rect = NSCoder.cgRect(for: "{{-1000, -1000}, {-1000, -10000}}")
        UIMenuController.shared.setTargetRect(rect, in: self)
    }

    func highlight(color: String) {
        self.evaluateJavaScript("ssReader.highlightSelection('"+color+"');")
        self.isUserInteractionEnabled = false
        self.isUserInteractionEnabled = true
    }

    func copyText() {
        self.evaluateJavaScript("ssReader.copy()")
        self.isUserInteractionEnabled = false
        self.isUserInteractionEnabled = true
    }

    func shareText() {
        self.evaluateJavaScript("ssReader.share()")
        self.isUserInteractionEnabled = false
        self.isUserInteractionEnabled = true
    }
    
    func lookupText() {
        self.evaluateJavaScript("ssReader.search()")
        self.isUserInteractionEnabled = false
        self.isUserInteractionEnabled = true
    }
    
    func clearHighlight() {
        self.evaluateJavaScript("ssReader.unHighlightSelection()")
        self.isUserInteractionEnabled = false
        self.isUserInteractionEnabled = true
    }

    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(didTapHighlightGreen),
            #selector(didTapHighlightBlue),
            #selector(didTapHighlightYellow),
            #selector(didTapHighlightOrange),
            #selector(didTapClearHighlight),
            #selector(didTapCopy),
            #selector(didTapShare),
            #selector(didTapLookup),
            #selector(paste(_:)):
            return super.canPerformAction(action, withSender: sender)
        default:
            return false
        }
    }
    
    func loadContent(content: String) {
        var indexPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "sabbath-school-reader")
        
        let exists = FileManager.default.fileExists(atPath: Constants.Path.readerBundle.path)

        if exists {
            indexPath = Constants.Path.readerBundle.path
        }

        var index = try? String(contentsOfFile: indexPath!, encoding: .utf8)
        index = index?.replacingOccurrences(of: "{{content}}", with: content)


        var theme = Preferences.currentTheme()
        let typeface = Preferences.currentTypeface()
        let size = Preferences.currentSize()
        
        if theme == .auto {
            theme = Preferences.darkModeEnable() ? .dark: .light
        }

        index = index?.replacingOccurrences(of: "ss-wrapper-light", with: "ss-wrapper-"+theme.rawValue)
        index = index?.replacingOccurrences(of: "ss-wrapper-lato", with: "ss-wrapper-"+typeface.rawValue)
        index = index?.replacingOccurrences(of: "ss-wrapper-medium", with: "ss-wrapper-"+size.rawValue)
        
        guard let index = index else { return }

        if exists {
            loadFileURL(Constants.Path.readerBundle, allowingReadAccessTo: Constants.Path.readerBundleDir)
            loadHTMLString(index, baseURL: Constants.Path.readerBundleDir)
        } else {
            loadHTMLString(index, baseURL: URL(fileURLWithPath: indexPath!).deletingLastPathComponent())
        }

        self.readerViewDelegate?.didLoadContent(content: index)
    }

    func shouldStartLoad(request: URLRequest, navigationType: WKNavigationType) -> Bool {
        
        guard let url = request.url else { return false }
        
        if url.valueForParameter(key: "ready") != nil {
            self.readerViewDelegate?.ready()
            return false
        }

        if let text = url.valueForParameter(key: "copy") {
            self.readerViewDelegate?.didReceiveCopy(text: text)
            return false
        }

        if let text = url.valueForParameter(key: "share") {
            self.readerViewDelegate?.didReceiveShare(text: text)
            return false
        }
        
        if let text = url.valueForParameter(key: "search") {
            self.readerViewDelegate?.didReceiveLookup(text: text)
            return false
        }

        if let verse = url.valueForParameter(key: "verse"), let decoded = verse.base64Decode() {
            self.readerViewDelegate?.didClickVerse(verse: decoded)
            return false
        }

        if let highlights = url.valueForParameter(key: "highlights") {
            self.readerViewDelegate?.didReceiveHighlights(highlights: highlights)
            return false
        }

        if let comment = url.valueForParameter(key: "comment"), let decodedComment = comment.base64Decode() {
            if let elementId = url.valueForParameter(key: "elementId") {
                self.readerViewDelegate?.didReceiveComment(comment: decodedComment, elementId: elementId)
                return false
            }
            return false
        }

        if let scheme = url.scheme, (scheme == "http" || scheme == "https"), navigationType == .linkActivated {
            self.readerViewDelegate?.didTapExternalUrl(url: url)
            return false
        }

        return true
    }

    func setTheme(_ theme: ReaderStyle.Theme) {
        if theme == .auto {
            let readerTheme: ReaderStyle.Theme = Preferences.darkModeEnable() ? .dark:.light
            evaluateJavaScript("ssReader.setTheme('"+readerTheme.rawValue+"')")
        } else {
            evaluateJavaScript("ssReader.setTheme('"+theme.rawValue+"')")
        }
    }

    func setTypeface(_ typeface: ReaderStyle.Typeface) {
        self.evaluateJavaScript("ssReader.setFont('"+typeface.rawValue+"')")
    }

    func setSize(_ size: ReaderStyle.Size) {
        self.evaluateJavaScript("ssReader.setSize('"+size.rawValue+"')")
    }

    func setHighlights(_ highlights: String) {
        self.evaluateJavaScript("ssReader.setHighlights('"+highlights+"')")
    }

    func setComment(_ comment: Comment) {
        self.evaluateJavaScript("ssReader.setComment('"+comment.comment.base64Encode()!+"', '"+comment.elementId+"')")
    }
}
