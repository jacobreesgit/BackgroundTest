//
//  ContentView.swift
//  BackgroundTest
//
//  Created by Jacob Rees on 28/06/2025.
//

import SwiftUI
import BackgroundTasks

struct ContentView: View {
    @State private var testResult = "Testing background monitoring..."
    @State private var resultColor: Color = .secondary
    @State private var resultIcon = "clock.arrow.circlepath"
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: resultIcon)
                .imageScale(.large)
                .foregroundStyle(resultColor)
                .font(.system(size: 50))
            
            Text("Background Monitoring Test")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(testResult)
                .font(.body)
                .foregroundColor(resultColor)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Retest") {
                retestBackgroundMonitoring()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
        }
        .padding()
        .onAppear {
            testBackgroundMonitoring()
        }
    }
    
    private func retestBackgroundMonitoring() {
        print("🔄 [RETEST] User requested retest of background monitoring")
        testResult = "Testing background monitoring..."
        resultColor = .secondary
        resultIcon = "clock.arrow.circlepath"
        testBackgroundMonitoring()
    }
    
    private func testBackgroundMonitoring() {
        print("🚀 [INIT] Starting background monitoring test...")
        print("📱 [INFO] Device: \(UIDevice.current.model)")
        print("📋 [INFO] iOS Version: \(UIDevice.current.systemVersion)")
        print("🏗️ [INFO] Build Configuration: DEBUG")
        
        let identifier = "com.backgroundtest.monitor"
        print("🆔 [INFO] Task identifier: \(identifier)")
        
        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        print("⚙️ [CONFIG] Background task request created:")
        print("   - Network connectivity required: \(request.requiresNetworkConnectivity)")
        print("   - External power required: \(request.requiresExternalPower)")
        
        do {
            print("📤 [ATTEMPT] Submitting background task request...")
            try BGTaskScheduler.shared.submit(request)
            print("✅ [SUCCESS] Background task submitted successfully!")
            showSuccessResult()
        } catch BGTaskScheduler.Error.unavailable {
            print("❌ [ERROR] BGTaskScheduler.Error.unavailable")
            print("   - Background task scheduling is unavailable")
            print("   - This usually happens in simulator or when background refresh is disabled")
            showUnavailableResult()
        } catch BGTaskScheduler.Error.tooManyPendingTaskRequests {
            print("❌ [ERROR] BGTaskScheduler.Error.tooManyPendingTaskRequests")
            print("   - Too many pending background task requests")
            print("   - Clear pending tasks or wait for them to execute")
            showTooManyRequestsResult()
        } catch BGTaskScheduler.Error.notPermitted {
            print("❌ [ERROR] BGTaskScheduler.Error.notPermitted")
            print("   - Background task scheduling is not permitted")
            print("   - Check if identifier is registered in Info.plist")
            showNotPermittedResult()
        } catch {
            print("❌ [ERROR] Unknown error occurred:")
            print("   - Error type: \(type(of: error))")
            print("   - Error description: \(error.localizedDescription)")
            print("   - Error code: \((error as NSError).code)")
            print("   - Error domain: \((error as NSError).domain)")
            
            if error.localizedDescription.contains("backgroundTaskFailed") {
                print("🔍 [DETECTED] backgroundTaskFailed error detected")
                showBackgroundTaskFailedResult()
            } else {
                print("🔍 [FALLBACK] Generic error handling")
                showGenericErrorResult(error: error)
            }
        }
        
        print("📊 [STATUS] Background monitoring test completed")
        print("🔍 [DEBUG] Current BGTaskScheduler state inspection:")
        
        BGTaskScheduler.shared.getPendingTaskRequests { requests in
            DispatchQueue.main.async {
                print("📋 [PENDING] Found \(requests.count) pending background task requests:")
                for (index, request) in requests.enumerated() {
                    print("   \(index + 1). \(request.identifier)")
                }
                if requests.isEmpty {
                    print("   (No pending requests)")
                }
            }
        }
    }
    
    private func showSuccessResult() {
        testResult = "✅ Background monitoring started successfully"
        resultColor = .green
        resultIcon = "checkmark.circle.fill"
        print("🎉 [UI] Displaying success result")
    }
    
    private func showBackgroundTaskFailedResult() {
        testResult = "❌ Background monitoring not supported on this device"
        resultColor = .red
        resultIcon = "xmark.circle.fill"
        print("🚫 [UI] Displaying backgroundTaskFailed result")
    }
    
    private func showUnavailableResult() {
        testResult = "⚠️ Background task scheduling is unavailable\n(Common in simulator)"
        resultColor = .orange
        resultIcon = "exclamationmark.triangle.fill"
        print("⚠️ [UI] Displaying unavailable result")
    }
    
    private func showTooManyRequestsResult() {
        testResult = "⚠️ Too many pending background task requests"
        resultColor = .orange
        resultIcon = "exclamationmark.triangle.fill"
        print("⚠️ [UI] Displaying too many requests result")
    }
    
    private func showNotPermittedResult() {
        testResult = "❌ Background task scheduling is not permitted\n(Check Info.plist configuration)"
        resultColor = .red
        resultIcon = "xmark.circle.fill"
        print("🚫 [UI] Displaying not permitted result")
    }
    
    private func showGenericErrorResult(error: Error) {
        testResult = "❌ Error: \(error.localizedDescription)"
        resultColor = .red
        resultIcon = "xmark.circle.fill"
        print("🚫 [UI] Displaying generic error result")
    }
}

#Preview {
    ContentView()
}
