//
//  ShowNotesView.swift
//  Secret Peas
//
//  Created by Elizabeth Berry on 10/22/20.
//

import Foundation
import WebKit
import SwiftUI

struct ShowNotes:UIViewRepresentable {
    let showNotesString:String
    let navDelegate = ShowNotesNavigationDelegate()
    
    func makeUIView(context: Context) -> some UIView {
        let webview = WKWebView()
        webview.loadHTMLString(showNotesString, baseURL: nil)
        webview.navigationDelegate = navDelegate
        return webview
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
}

class ShowNotesNavigationDelegate:NSObject, WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
        return
    }
}
