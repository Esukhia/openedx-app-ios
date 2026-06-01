//
//  AjaxProvider.swift
//  Core
//
//  Created by Eugene Yatsenko on 12.12.2023.
//

import Foundation
import WebKit
import Swinject

struct AjaxInjection: WebViewScriptInjectionProtocol {
    private struct AJAXCallbackData {
        private enum Keys: String {
            case url = "url"
            case statusCode = "status"
            case responseText = "response_text"
        }

        let url: String
        let statusCode: Int
        let responseText: String

        init(data: [AnyHashable: Any]) {
            url = data[Keys.url.rawValue] as? String ?? ""
            statusCode = data[Keys.statusCode.rawValue] as? Int ?? 0
            responseText = data[Keys.responseText.rawValue] as? String ?? ""
        }
    }

    private enum XBlockCompletionCallbackType: String {
        case html = "publish_completion"
        case problem = "problem_check"
        case dragAndDrop = "do_attempt"
        case ora = "render_grade"
    }

    private let AJAXCallBackHandler = "ajaxCallbackHandler"
    private let ajaxScriptFile = "ajaxHandler"

    var id: String = "AjaxInjection"
    var script: String {
        guard let url = Bundle(for: CoreBundle.self).url(forResource: ajaxScriptFile, withExtension: "js"),
              let script = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return script
    }

    var messages: [WebviewMessage]? {
        [
            WebviewMessage(name: AJAXCallBackHandler) { result, webView in
                guard let data = result as? [AnyHashable: Any] else { return }
                let callback = AJAXCallbackData(data: data)
                let requestURL = callback.url

                if callback.statusCode == 403,
                   isBlockOf(type: .problem, with: requestURL) {
                    NotificationCenter.default.post(
                        name: NSNotification.problemCheckUnauthorized,
                        object: webView
                    )
                    return
                }

                if callback.statusCode != 200 {
                    return
                }

                var complete = false
                if isBlockOf(type: .ora, with: requestURL) {
                    complete = callback.responseText.contains("is--complete")
                } else {
                    complete = isBlockOf(type: .html, with: requestURL)
                        || isBlockOf(type: .problem, with: requestURL)
                        || isBlockOf(type: .dragAndDrop, with: requestURL)
                }
                if complete {
                    NotificationCenter.default.post(
                        name: NSNotification.blockCompletion,
                        object: nil
                    )
                }
            }
         ]
    }
    var forMainFrameOnly: Bool = false
    
    var injectionTime: WKUserScriptInjectionTime = .atDocumentEnd
    
    private func isBlockOf(type: XBlockCompletionCallbackType, with requestURL: String) -> Bool {
        return requestURL.contains(type.rawValue)
    }
}

public extension NSNotification {
    static let blockCompletion = Notification.Name.init("block_completion")
    static let problemCheckUnauthorized = Notification.Name.init("problem_check_unauthorized")
    static let libraryMCQProgress = Notification.Name.init("library_mcq_progress")
    static let libraryMCQNextQuestion = Notification.Name.init("library_mcq_next_question")
}

struct LibraryMCQInjection: WebViewScriptInjectionProtocol {
    private enum Keys: String {
        case blockId = "block_id"
        case currentQuestion = "current_question"
        case totalQuestions = "total_questions"
    }

    private let blockId: String
    private let callbackHandler = "libraryMCQHandler"

    init(blockId: String) {
        self.blockId = blockId
    }

    var id: String {
        "LibraryMCQInjection_\(blockId)"
    }

    var script: String {
        let escapedBlockId = blockId
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return """
        (function() {
            const BLOCK_ID = "\(escapedBlockId)";
            const QUESTION_SELECTORS = [
                '.xblock-student_view-problem',
                '.xblock.xblock-student_view-problem',
                '[data-block-type="problem"]',
                '.problem'
            ];
            let questions = [];
            let currentState = { index: 0, total: 0 };

            function uniq(items) {
                return Array.from(new Set(items));
            }

            function collectQuestions() {
                const rawNodes = uniq(
                    QUESTION_SELECTORS
                        .flatMap(selector => Array.from(document.querySelectorAll(selector)))
                );

                const filtered = rawNodes.filter(node => {
                    if (!node || node.closest('[data-library-mcq-ignore="true"]')) {
                        return false;
                    }
                    return !rawNodes.some(other => other !== node && other.contains(node));
                });

                return filtered;
            }

            function postProgress() {
                try {
                    webkit.messageHandlers.libraryMCQHandler.postMessage({
                        block_id: BLOCK_ID,
                        current_question: currentState.index + 1,
                        total_questions: Math.max(currentState.total, 1)
                    });
                } catch (error) {
                    console.log('libraryMCQHandler is unavailable');
                }
            }

            function setVisibleQuestion() {
                questions.forEach((question, idx) => {
                    question.style.display = idx === currentState.index ? '' : 'none';
                });
                window.scrollTo(0, 0);
                postProgress();
            }

            function initQuestions() {
                questions.splice(0, questions.length, ...collectQuestions());
                currentState.total = questions.length;
                if (currentState.total <= 1) {
                    postProgress();
                    return;
                }
                currentState.index = Math.min(currentState.index, currentState.total - 1);
                setVisibleQuestion();
            }

            window.__iosLibraryMCQNextQuestion = function(blockId) {
                if (blockId !== BLOCK_ID || currentState.total <= 1) {
                    return;
                }
                if (currentState.index < currentState.total - 1) {
                    currentState.index += 1;
                    setVisibleQuestion();
                }
            };

            const initDelays = [0, 200, 500, 1000, 1500];
            initDelays.forEach(delay => {
                setTimeout(initQuestions, delay);
            });
        })();
        """
    }

    var messages: [WebviewMessage]? {
        [
            WebviewMessage(name: callbackHandler) { result, _ in
                guard let data = result as? [AnyHashable: Any] else { return }
                let blockId = data[Keys.blockId.rawValue] as? String ?? ""
                let currentQuestion = data[Keys.currentQuestion.rawValue] as? Int ?? 1
                let totalQuestions = data[Keys.totalQuestions.rawValue] as? Int ?? 1
                NotificationCenter.default.post(
                    name: NSNotification.libraryMCQProgress,
                    object: nil,
                    userInfo: [
                        Keys.blockId.rawValue: blockId,
                        Keys.currentQuestion.rawValue: currentQuestion,
                        Keys.totalQuestions.rawValue: totalQuestions
                    ]
                )
            }
        ]
    }

    var injectionTime: WKUserScriptInjectionTime = .atDocumentEnd

    var forMainFrameOnly: Bool = false
}
