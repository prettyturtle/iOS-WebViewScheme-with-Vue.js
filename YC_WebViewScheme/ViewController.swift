//
//  ViewController.swift
//  YC_WebViewScheme
//
//  Created by yc on 2023/07/13.
//

import UIKit
import WebKit

import SnapKit
import Then

final class ViewController: UIViewController {
    
    private let webViewBridgeName = "WEBVIEW_BRIDGE"
    
    private lazy var userController = WKUserContentController().then {
        $0.add(self, name: webViewBridgeName)
    }
    private lazy var webViewConfiguration = WKWebViewConfiguration().then {
        $0.preferences.javaScriptEnabled = true
        $0.mediaTypesRequiringUserActionForPlayback = []
        $0.allowsInlineMediaPlayback = true
        $0.setURLSchemeHandler(webViewScheme, forURLScheme: WebViewScheme.scheme)
        $0.userContentController = userController
    }
    private lazy var webView = WKWebView(frame: .zero, configuration: webViewConfiguration).then {
        $0.customUserAgent = "Mozilla/5.0 (iPad; CPU iPhone OS 13_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)"
        $0.uiDelegate = self
    }
    
    let webViewScheme = WebViewScheme()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 웹뷰 레이아웃 설정
        view.addSubview(webView)
        webView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 웹뷰 로드
        let urlString = "http://172.30.1.23:8080/"
        let url = URL(string: urlString)!
        let urlRequest = URLRequest(url: url)
        webView.load(urlRequest)
    }
    
}

extension ViewController {
    func didTapDownloadVideoButton(_ urlString: String) {
        let url = URL(string: urlString)!
        let urlRequest = URLRequest(url: url)
        
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let downloadTask = urlSession.downloadTask(with: urlRequest)
        
        downloadTask.resume()
    }
}

extension ViewController: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let videoData = try! Data(contentsOf: location)
        
        let fm = FileManager.default
        
        let documentDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosDir = documentDir.appendingPathComponent("videos")
        
        try? fm.createDirectory(at: videosDir, withIntermediateDirectories: false)
        
        let fileName = "VideoName1.mp4"
        let videoFileURL = videosDir.appendingPathComponent(fileName)
        
        try? videoData.write(to: videoFileURL)
        
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("window.yc.methods.saveLocalVideoURL('\(WebViewScheme.scheme)://\(videoFileURL.absoluteString)')")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let currentProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        
        print("current Progress : \(currentProgress * 100)% / totalSize : \(totalSize)")
    }
}

final class WebViewScheme: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let urlString = urlSchemeTask.request.url?.absoluteString.replacingOccurrences(of: "\(WebViewScheme.scheme)://", with: "").replacingOccurrences(of: "file///", with: "file:///")
        let url = URL(string: urlString!)!
        
        let videoData = try! Data(contentsOf: url)
        
        urlSchemeTask.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Access-Control-Allow-Origin": "*"])!)
        urlSchemeTask.didReceive(videoData)
        urlSchemeTask.didFinish()
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        
    }
    
    
    
    static let scheme = "yc-webview-scheme"
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if webViewBridgeName == message.name,
           let msg = message.body as? String {
            
            if msg == "didTapDownloadVideoButton" {
                let videoURL1 = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
//                let videoURL1 = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
//                let videoURL1 = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
//                let videoURL1 = "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
                
                didTapDownloadVideoButton(videoURL1)
            }
            
        }
    }
}

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert).then {
            $0.addAction(UIAlertAction(title: "OK", style: .default))
        }
        
        present(alert, animated: true)
    }
}
