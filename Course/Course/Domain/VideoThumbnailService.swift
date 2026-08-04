//
//  VideoThumbnailService.swift
//  Course
//
//  Created by Ivan Stepanok on 30.07.2025.
//

import UIKit
import AVFoundation
import Kingfisher

public protocol VideoThumbnailServiceProtocol: Sendable {
    func generateVideoThumbnailIfNeeded(from url: URL) async -> UIImage?
    func preloadThumbnail(from url: URL) async
}

public actor VideoThumbnailService: VideoThumbnailServiceProtocol {
    
    private var generatingURLs: Set<String> = []
    
    public init() {}
    
    public func generateVideoThumbnailIfNeeded(from url: URL) async -> UIImage? {
        let cacheKey = generateCacheKey(for: url)
        
        // Check if thumbnail is already cached (both memory and disk)
        do {
            let cacheResult = try await ImageCache.default.retrieveImage(forKey: cacheKey)
            if let cachedImage = cacheResult.image {
                return cachedImage
            }
        } catch {
            // Cache retrieval failed, continue to generate new thumbnail
        }
        
        // Wait if already generating this thumbnail
        while generatingURLs.contains(cacheKey) {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        // Check cache again after waiting
        do {
            let cacheResult = try await ImageCache.default.retrieveImage(forKey: cacheKey)
            if let cachedImage = cacheResult.image {
                return cachedImage
            }
        } catch {
            // Continue to generate
        }
        
        // Mark as generating
        generatingURLs.insert(cacheKey)
        defer { generatingURLs.remove(cacheKey) }
        
        // Generate thumbnail
        do {
            let image = try await generateVideoThumbnail(from: url)
            
            // Cache the generated thumbnail to both memory and disk
            try await ImageCache.default.store(
                image,
                forKey: cacheKey,
                toDisk: true
            )
            
            return image
        } catch {
            return nil
        }
    }
    
    public func preloadThumbnail(from url: URL) async {
        let cacheKey = generateCacheKey(for: url)
        
        // Check if already cached
        do {
            let cacheResult = try await ImageCache.default.retrieveImage(forKey: cacheKey)
            if cacheResult.image != nil {
                return
            }
        } catch {
            // Continue to preload
        }
        
        // Don't wait for preload to complete, just start it
        Task.detached { [weak self] in
            _ = await self?.generateVideoThumbnailIfNeeded(from: url)
        }
    }
    
    private func generateVideoThumbnail(from url: URL) async throws -> UIImage {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        // Increase tolerance for faster generation
        imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(
                forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "VideoThumbnailError", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to generate thumbnail"]
                        )
                    )
                    return
                }
                
                let image = UIImage(cgImage: cgImage)
                continuation.resume(returning: image)
            }
        }
    }
    
    private func generateCacheKey(for url: URL) -> String {
        // Use the full URL string for better cache key uniqueness
        return "video_thumbnail_\(url.absoluteString)"
    }
}
