//
//  WebviewInjection.swift
//  Core
//
//  Created by Vadim Kuznetsov on 4.01.24.
//

import WebKit
public struct WebviewInjection: WebViewScriptInjectionProtocol {
    public var id: String
    public var script: String
    public var messages: [WebviewMessage]?
    public var injectionTime: WKUserScriptInjectionTime
    public var forMainFrameOnly: Bool
    init(
        id: String,
        script: String,
        messages: [WebviewMessage]? = nil,
        injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
        forMainFrameOnly: Bool = true
    ) {
        self.id = id
        self.script = script
        self.messages = messages
        self.injectionTime = injectionTime
        self.forMainFrameOnly = forMainFrameOnly
    }
    
    public static func == (lhs: WebviewInjection, rhs: WebviewInjection) -> Bool {
        lhs.id == rhs.id &&
        lhs.script == rhs.script &&
        lhs.injectionTime == rhs.injectionTime &&
        lhs.messages == rhs.messages &&
        lhs.forMainFrameOnly == rhs.forMainFrameOnly
    }
}

public extension WebviewInjection {

    static var surveyCSS: WebviewInjection {
        SurveyCssInjection()
            .webviewInjection()
    }
    
    static var dragAndDropCss: WebviewInjection {
        DragAndDropCssInjection()
            .webviewInjection()
    }

    static var colorInversionCss: WebviewInjection {
        ColorInversionInjection()
            .webviewInjection()
    }

    static var ajaxCallback: WebviewInjection {
        AjaxInjection()
            .webviewInjection()
    }
    
    static var readability: WebviewInjection {
        ReadabilityInjection()
            .webviewInjection()
    }
    
    static var accessibility: WebviewInjection {
        AccessibilityInjection()
            .webviewInjection()
    }

    static var hideCertificatePrintBanner: WebviewInjection {
        let script = """
        (function() {
            window.__openedxHideCertBanner = function() {
                try {
                    var selectors = [
                        ".accomplishment-action",
                        ".wrapper-accomplishment-action",
                        ".btn-print",
                        ".certificate-introduction",
                        ".print-certificate-banner",
                        ".accomplishment-intro"
                    ];
                    var hasSelectorMatch = false;
                    selectors.forEach(function(sel) {
                        var elements = document.querySelectorAll(sel);
                        if (elements.length > 0) {
                            hasSelectorMatch = true;
                        }
                        elements.forEach(function(el) {
                            el.style.setProperty("display", "none", "important");
                        });
                    });
                    if (hasSelectorMatch) {
                        return;
                    }
                    var blocks = document.querySelectorAll(
                        "div, section, article, aside"
                    );
                    var banner = null;
                    var bannerSize = 0;
                    for (var i = 0; i < blocks.length; i++) {
                        var html = blocks[i].outerHTML;
                        var text = (blocks[i].textContent || "").trim();
                        if (
                            html.length < 3000 &&
                            html.length > bannerSize &&
                            /print/i.test(text) &&
                            /certificate/i.test(text)
                        ) {
                            banner = blocks[i];
                            bannerSize = html.length;
                        }
                    }
                    if (banner) {
                        banner.style.setProperty("display", "none", "important");
                    }
                } catch (e) {}
            };
            document.addEventListener("DOMContentLoaded", window.__openedxHideCertBanner);
        })();
        """
        return WebviewInjection(
            id: "HideCertificatePrintBannerInjection",
            script: script,
            messages: nil,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
    }

    // Hide common headers/footers in external pages (e.g., policy pages)
    static var hideHeaderFooter: WebviewInjection {
        let css = """
            /* Hide common site headers/footers */
            header, footer,
            [role=\"banner\"], [role=\"contentinfo\"],
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
        let script = """
        window.addEventListener("load", () => {
            var css = `\(css)`,
                head = document.head || document.getElementsByTagName('head')[0],
                style = document.createElement('style');
            head.appendChild(style);
            style.type = 'text/css';
            if (style.styleSheet) {
                style.styleSheet.cssText = css;
            } else {
                style.appendChild(document.createTextNode(css));
            }
        })
        """
        return WebviewInjection(
            id: "HideHeaderFooterInlineInjection",
            script: script,
            messages: nil,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }
}
