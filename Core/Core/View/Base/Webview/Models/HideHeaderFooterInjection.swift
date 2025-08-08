//
//  HideHeaderFooterInjection.swift
//  Core
//

import WebKit

public struct HideHeaderFooterInjection: WebViewScriptInjectionProtocol, CSSInjectionProtocol {
    public var id: String = "HideHeaderFooterInjection"
    public var script: String {
        let css = """
            /* Hide common site headers/footers */
            header, footer,
            [role="banner"], [role="contentinfo"],
            .site-header, .site-footer,
            .global-header, .global-footer,
            .header, .footer,
            .navbar-fixed-top, .navbar, .topbar,
            .bottom-bar, .cookie-banner, .gdpr-banner,
            #header, #footer, #masthead, #site-footer, #site-header {
                display: none !important;
                visibility: hidden !important;
                height: 0 !important;
                min-height: 0 !important;
                max-height: 0 !important;
                margin: 0 !important;
                padding: 0 !important;
                border: 0 !important;
            }

            /* Remove empty space created by fixed headers */
            body {
                padding-top: 0 !important;
                padding-bottom: 0 !important;
                margin-top: 0 !important;
                margin-bottom: 0 !important;
            }
        """
        return cssScript(with: css)
    }
    public var messages: [WebviewMessage]?
    public var injectionTime: WKUserScriptInjectionTime = .atDocumentEnd
    public var forMainFrameOnly: Bool = true
}
