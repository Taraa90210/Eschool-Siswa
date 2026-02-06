# 📱 Mobile App Integration Guide - Xendit Payment

Panduan lengkap untuk integrate Xendit payment ke mobile apps (Android, iOS, Flutter, React Native, dll)

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Android Integration](#android-integration)
3. [iOS Integration](#ios-integration)
4. [Flutter Integration](#flutter-integration)
5. [React Native Integration](#react-native-integration)
6. [Implementation Patterns](#implementation-patterns)
7. [Error Handling](#error-handling)
8. [Testing on Device](#testing-on-device)

---

## Architecture Overview

### Data Flow

```
┌─────────────────────┐
│  Mobile App         │
│ - Local Storage     │
│ - WebView           │
│ - HTTP Client       │
└──────────┬──────────┘
           │
           ├─ Create Invoice ──→ eSchool API
           │                     │
           │                     └─ Xendit API
           │                        │
           │←─ Invoice URL ────────┘
           │
           ├─ Open Checkout
           │  (WebView/Browser)
           │
           ├─ Poll Status ─────→ eSchool API
           │
           └─ Update UI
              (Mark as Paid)
```

### Flow Sequence

```
1. User initiates payment
   ↓
2. App calls: POST /api/parent/fees/xendit/create
   ↓
3. API returns: invoice_id, invoice_url, status
   ↓
4. App opens invoice_url in WebView/Browser
   ↓
5. User selects payment method & completes payment
   ↓
6. Xendit processes payment
   ↓
7. App polls: GET /api/parent/fees/xendit/status/{invoice_id}
   ↓
8. Status changes: pending → paid
   ↓
9. App shows success dialog
   ↓
10. Refresh fees list
```

---

## Android Integration

### 1. Dependencies

**build.gradle (Module: app)**

```gradle
dependencies {
    // HTTP Client
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
    implementation 'com.squareup.retrofit2:retrofit:2.10.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.10.0'
    
    // WebView (built-in, but update support)
    implementation 'androidx.webkit:webkit:1.7.0'
    
    // Async tasks
    implementation 'androidx.concurrent:concurrent-futures:1.1.0'
    
    // JSON
    implementation 'com.google.code.gson:gson:2.10.1'
}
```

### 2. API Service (Retrofit)

```kotlin
// models/XenditModels.kt
data class CreateInvoiceRequest(
    val school_id: Int,
    val student_id: Int,
    val amount: Int,
    val email: String,
    val description: String,
    val fee_ids: List<Int>
)

data class CreateInvoiceResponse(
    val error: Boolean,
    val message: String,
    val invoice_id: String,
    val invoice_url: String,
    val external_id: String,
    val status: String,
    val amount: Int,
    val expiry_date: String
)

data class StatusResponse(
    val error: Boolean,
    val data: InvoiceData
)

data class InvoiceData(
    val id: String,
    val status: String,
    val amount: Int,
    val is_paid: Boolean,
    val is_expired: Boolean,
    val paid_at: String?,
    val payer_email: String,
    val school_id: Int,
    val student_id: Int
)

// services/XenditApiService.kt
import retrofit2.http.*

interface XenditApiService {
    @POST("/api/parent/fees/xendit/create")
    suspend fun createInvoice(
        @Header("school_code") schoolCode: String,
        @Body request: CreateInvoiceRequest
    ): CreateInvoiceResponse
    
    @GET("/api/parent/fees/xendit/status/{invoiceId}")
    suspend fun getInvoiceStatus(
        @Header("school_code") schoolCode: String,
        @Path("invoiceId") invoiceId: String
    ): StatusResponse
}

// Setup Retrofit
object ApiClient {
    private const val BASE_URL = "http://your-api.com"  // Change to actual API
    
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .build()
    
    private val retrofit = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .client(httpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
    
    fun getXenditService(): XenditApiService {
        return retrofit.create(XenditApiService::class.java)
    }
}
```

### 3. Payment Activity

```kotlin
// activities/PaymentActivity.kt
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import android.webkit.WebView
import android.webkit.WebViewClient
import android.app.AlertDialog
import kotlinx.coroutines.*
import android.util.Log

class PaymentActivity : AppCompatActivity() {
    
    private lateinit var webView: WebView
    private lateinit var apiService: XenditApiService
    
    private val schoolCode = "SCH20247"  // Get from SharedPreferences
    private val schoolId = 7             // Get from app state
    private val studentId = 47           // Get from app state
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_payment)
        
        webView = findViewById(R.id.webView)
        apiService = ApiClient.getXenditService()
        
        setupWebView()
        initiatePayment()
    }
    
    private fun setupWebView() {
        webView.apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            
            webViewClient = PaymentWebViewClient(
                onPaymentComplete = { handlePaymentSuccess() },
                onPaymentFailed = { handlePaymentFailed() }
            )
        }
    }
    
    private fun initiatePayment() {
        lifecycleScope.launch {
            try {
                // Show loading dialog
                showLoadingDialog("Creating invoice...")
                
                // Create invoice
                val request = CreateInvoiceRequest(
                    school_id = schoolId,
                    student_id = studentId,
                    amount = 100000,  // From database/intent
                    email = "parent@example.com",  // From user profile
                    description = "SPP February 2026",
                    fee_ids = listOf(42, 43)  // From database
                )
                
                val response = apiService.createInvoice(schoolCode, request)
                
                if (!response.error) {
                    dismissLoadingDialog()
                    
                    // Save invoice details
                    saveInvoiceData(
                        invoiceId = response.invoice_id,
                        status = response.status,
                        amount = response.amount
                    )
                    
                    // Open checkout
                    webView.loadUrl(response.invoice_url)
                    
                    // Start polling
                    startPolling(response.invoice_id)
                } else {
                    dismissLoadingDialog()
                    showError(response.message)
                }
            } catch (e: Exception) {
                dismissLoadingDialog()
                showError("Error: ${e.message}")
                Log.e("PaymentActivity", "Create invoice error", e)
            }
        }
    }
    
    private fun startPolling(invoiceId: String) {
        lifecycleScope.launch {
            var pollCount = 0
            val maxPolls = 60  // 60 polls = 3 minutes with 3 second interval
            
            while (pollCount < maxPolls) {
                delay(3000)  // Wait 3 seconds
                pollCount++
                
                try {
                    val statusResponse = apiService.getInvoiceStatus(schoolCode, invoiceId)
                    
                    if (!statusResponse.error) {
                        val data = statusResponse.data
                        
                        when {
                            data.is_paid -> {
                                handlePaymentSuccess()
                                break
                            }
                            data.is_expired -> {
                                handlePaymentExpired()
                                break
                            }
                            data.status == "failed" -> {
                                handlePaymentFailed()
                                break
                            }
                        }
                        
                        Log.d("PaymentActivity", "Poll $pollCount: Status = ${data.status}")
                    }
                } catch (e: Exception) {
                    Log.e("PaymentActivity", "Poll error: ${e.message}")
                    // Continue polling despite errors
                }
            }
            
            // If max polls reached
            if (pollCount >= maxPolls) {
                handlePaymentTimeout()
            }
        }
    }
    
    private fun handlePaymentSuccess() {
        // Update local database
        updateInvoiceStatus(status = "paid")
        
        // Show success dialog
        AlertDialog.Builder(this)
            .setTitle("✅ Pembayaran Berhasil")
            .setMessage("Terima kasih! Pembayaran SPP telah diterima.")
            .setCancelable(false)
            .setPositiveButton("OK") { _, _ ->
                // Navigate back to fees list
                setResult(RESULT_OK)
                finish()
            }
            .show()
    }
    
    private fun handlePaymentFailed() {
        AlertDialog.Builder(this)
            .setTitle("❌ Pembayaran Gagal")
            .setMessage("Pembayaran tidak berhasil. Silakan coba lagi.")
            .setCancelable(false)
            .setNegativeButton("Kembali") { _, _ -> finish() }
            .setPositiveButton("Coba Lagi") { _, _ -> 
                // Reset and retry
                initiatePayment()
            }
            .show()
    }
    
    private fun handlePaymentExpired() {
        AlertDialog.Builder(this)
            .setTitle("⏰ Invoice Expired")
            .setMessage("Invoice Anda telah expired. Silakan buat invoice baru.")
            .setCancelable(false)
            .setPositiveButton("Buat Invoice Baru") { _, _ ->
                initiatePayment()
            }
            .setNegativeButton("Kembali") { _, _ -> finish() }
            .show()
    }
    
    private fun handlePaymentTimeout() {
        AlertDialog.Builder(this)
            .setTitle("⏱ Timeout")
            .setMessage("Polling timeout. Status pembayaran tidak berhasil diverifikasi. Silakan cek manual di dashboard.")
            .setCancelable(false)
            .setPositiveButton("OK") { _, _ -> finish() }
            .show()
    }
    
    private inner class PaymentWebViewClient(
        val onPaymentComplete: () -> Unit,
        val onPaymentFailed: () -> Unit
    ) : WebViewClient() {
        
        override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
            url?.let {
                when {
                    it.contains("payment/success") -> {
                        onPaymentComplete()
                        return true
                    }
                    it.contains("payment/failed") -> {
                        onPaymentFailed()
                        return true
                    }
                }
            }
            return false
        }
    }
    
    private fun saveInvoiceData(invoiceId: String, status: String, amount: Int) {
        val sharedPref = getSharedPreferences("payment", MODE_PRIVATE)
        sharedPref.edit().apply {
            putString("invoice_id", invoiceId)
            putString("status", status)
            putInt("amount", amount)
            putLong("created_at", System.currentTimeMillis())
            apply()
        }
    }
    
    private fun updateInvoiceStatus(status: String) {
        val sharedPref = getSharedPreferences("payment", MODE_PRIVATE)
        sharedPref.edit().apply {
            putString("status", status)
            apply()
        }
    }
    
    private fun showLoadingDialog(message: String) {
        // Implementation depends on your UI framework
    }
    
    private fun dismissLoadingDialog() {
        // Implementation depends on your UI framework
    }
    
    private fun showError(message: String) {
        AlertDialog.Builder(this)
            .setTitle("Error")
            .setMessage(message)
            .setPositiveButton("OK", null)
            .show()
    }
}
```

### 4. AndroidManifest.xml Permissions

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

---

## iOS Integration

### 1. Swift Package Dependencies

**Package.swift** or **CocoaPods**

```ruby
# Podfile
target 'YourApp' do
  pod 'Alamofire', '~> 5.8'
  pod 'SwiftyJSON', '~> 5.0'
end
```

### 2. API Service

```swift
// Services/XenditService.swift
import Alamofire
import SwiftyJSON

struct CreateInvoiceRequest: Codable {
    let school_id: Int
    let student_id: Int
    let amount: Int
    let email: String
    let description: String
    let fee_ids: [Int]
}

struct CreateInvoiceResponse: Codable {
    let error: Bool
    let message: String
    let invoice_id: String
    let invoice_url: String
    let external_id: String
    let status: String
    let amount: Int
    let expiry_date: String
}

struct InvoiceData: Codable {
    let id: String
    let status: String
    let amount: Int
    let is_paid: Bool
    let is_expired: Bool
    let paid_at: String?
    let payer_email: String
    let school_id: Int
    let student_id: Int
}

struct StatusResponse: Codable {
    let error: Bool
    let data: InvoiceData
}

class XenditService {
    static let shared = XenditService()
    
    private let baseURL = "http://your-api.com"
    private let schoolCode = "SCH20247"
    
    func createInvoice(
        schoolId: Int,
        studentId: Int,
        amount: Int,
        email: String,
        description: String,
        feeIds: [Int],
        completion: @escaping (Result<CreateInvoiceResponse, Error>) -> Void
    ) {
        let request = CreateInvoiceRequest(
            school_id: schoolId,
            student_id: studentId,
            amount: amount,
            email: email,
            description: description,
            fee_ids: feeIds
        )
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "school_code": schoolCode,
            "Accept": "application/json"
        ]
        
        AF.request(
            "\(baseURL)/api/parent/fees/xendit/create",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: headers
        ).response { response in
            switch response.result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let invoice = try decoder.decode(CreateInvoiceResponse.self, from: data!)
                    completion(.success(invoice))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getInvoiceStatus(
        invoiceId: String,
        completion: @escaping (Result<StatusResponse, Error>) -> Void
    ) {
        let headers: HTTPHeaders = [
            "school_code": schoolCode,
            "Accept": "application/json"
        ]
        
        AF.request(
            "\(baseURL)/api/parent/fees/xendit/status/\(invoiceId)",
            method: .get,
            headers: headers
        ).response { response in
            switch response.result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let status = try decoder.decode(StatusResponse.self, from: data!)
                    completion(.success(status))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
```

### 3. Payment View Controller

```swift
// ViewControllers/PaymentViewController.swift
import UIKit
import WebKit

class PaymentViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    var invoiceId: String?
    var pollingTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        initiatePayment()
    }
    
    func initiatePayment() {
        showLoading()
        
        XenditService.shared.createInvoice(
            schoolId: 7,
            studentId: 47,
            amount: 100000,
            email: "parent@example.com",
            description: "SPP February 2026",
            feeIds: [42, 43]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.dismissLoading()
                
                switch result {
                case .success(let response):
                    if !response.error {
                        self?.invoiceId = response.invoice_id
                        self?.saveInvoiceData(response: response)
                        
                        if let url = URL(string: response.invoice_url) {
                            let request = URLRequest(url: url)
                            self?.webView.load(request)
                        }
                        
                        self?.startPolling()
                    } else {
                        self?.showError(message: response.message)
                    }
                case .failure(let error):
                    self?.showError(message: error.localizedDescription)
                }
            }
        }
    }
    
    func startPolling() {
        guard let invoiceId = invoiceId else { return }
        
        var pollCount = 0
        let maxPolls = 60
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            pollCount += 1
            
            XenditService.shared.getInvoiceStatus(invoiceId: invoiceId) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if !response.error {
                            let data = response.data
                            
                            if data.is_paid {
                                self?.handlePaymentSuccess()
                                self?.pollingTimer?.invalidate()
                            } else if data.is_expired {
                                self?.handlePaymentExpired()
                                self?.pollingTimer?.invalidate()
                            }
                        }
                    case .failure(let error):
                        print("Poll error: \(error.localizedDescription)")
                    }
                }
            }
            
            if pollCount >= maxPolls {
                self?.handlePaymentTimeout()
                self?.pollingTimer?.invalidate()
            }
        }
    }
    
    func handlePaymentSuccess() {
        let alert = UIAlertController(
            title: "✅ Pembayaran Berhasil",
            message: "Terima kasih! Pembayaran SPP telah diterima.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    func handlePaymentExpired() {
        let alert = UIAlertController(
            title: "⏰ Invoice Expired",
            message: "Invoice telah expired. Silakan buat invoice baru.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Buat Invoice Baru", style: .default) { _ in
            self.initiatePayment()
        })
        alert.addAction(UIAlertAction(title: "Kembali", style: .cancel))
        present(alert, animated: true)
    }
    
    func handlePaymentTimeout() {
        let alert = UIAlertController(
            title: "⏱ Timeout",
            message: "Polling timeout. Silakan cek status manual.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    
    func saveInvoiceData(response: CreateInvoiceResponse) {
        let defaults = UserDefaults.standard
        defaults.set(response.invoice_id, forKey: "invoiceId")
        defaults.set(response.status, forKey: "invoiceStatus")
        defaults.set(response.amount, forKey: "invoiceAmount")
        defaults.set(Date(), forKey: "invoiceCreatedAt")
    }
    
    func showLoading() {
        // Implementation using custom loader or UIActivityIndicatorView
    }
    
    func dismissLoading() {
        // Implementation
    }
    
    func showError(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
```

---

## Flutter Integration

### 1. pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  webview_flutter: ^4.0.0
  shared_preferences: ^2.2.0
  provider: ^6.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

### 2. Service Layer

```dart
// lib/services/xendit_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateInvoiceRequest {
  final int schoolId;
  final int studentId;
  final int amount;
  final String email;
  final String description;
  final List<int> feeIds;
  
  CreateInvoiceRequest({
    required this.schoolId,
    required this.studentId,
    required this.amount,
    required this.email,
    required this.description,
    required this.feeIds,
  });
  
  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'student_id': studentId,
    'amount': amount,
    'email': email,
    'description': description,
    'fee_ids': feeIds,
  };
}

class XenditService {
  static const String baseUrl = 'http://your-api.com';
  static const String schoolCode = 'SCH20247';
  
  Future<Map<String, dynamic>> createInvoice(CreateInvoiceRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/parent/fees/xendit/create'),
        headers: {
          'Content-Type': 'application/json',
          'school_code': schoolCode,
          'Accept': 'application/json',
        },
        body: jsonEncode(request),
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create invoice: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getInvoiceStatus(String invoiceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/parent/fees/xendit/status/$invoiceId'),
        headers: {
          'school_code': schoolCode,
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get status: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
```

### 3. Payment Provider (State Management)

```dart
// lib/providers/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentProvider extends ChangeNotifier {
  XenditService xenditService = XenditService();
  
  String? invoiceId;
  String? invoiceUrl;
  String? status = 'pending';
  int? amount;
  bool isLoading = false;
  String? errorMessage;
  
  Future<void> createInvoice({
    required int schoolId,
    required int studentId,
    required int amount,
    required String email,
    required String description,
    required List<int> feeIds,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    try {
      final request = CreateInvoiceRequest(
        schoolId: schoolId,
        studentId: studentId,
        amount: amount,
        email: email,
        description: description,
        feeIds: feeIds,
      );
      
      final response = await xenditService.createInvoice(request);
      
      if (response['error'] == false) {
        invoiceId = response['invoice_id'];
        invoiceUrl = response['invoice_url'];
        status = response['status'];
        this.amount = response['amount'];
        
        await _saveInvoiceData();
        
      } else {
        errorMessage = response['message'] ?? 'Unknown error';
      }
    } catch (e) {
      errorMessage = e.toString();
    }
    
    isLoading = false;
    notifyListeners();
  }
  
  Future<void> pollInvoiceStatus() async {
    if (invoiceId == null) return;
    
    int pollCount = 0;
    const maxPolls = 60;
    const pollInterval = Duration(seconds: 3);
    
    while (pollCount < maxPolls) {
      await Future.delayed(pollInterval);
      pollCount++;
      
      try {
        final response = await xenditService.getInvoiceStatus(invoiceId!);
        
        if (response['error'] == false) {
          final data = response['data'];
          status = data['status'];
          
          if (data['is_paid']) {
            await _updateInvoiceStatus('paid');
            notifyListeners();
            break;
          } else if (data['is_expired']) {
            errorMessage = 'Invoice expired';
            notifyListeners();
            break;
          }
        }
        
        notifyListeners();
      } catch (e) {
        print('Poll error: $e');
      }
    }
  }
  
  Future<void> _saveInvoiceData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('invoice_id', invoiceId ?? '');
    prefs.setString('invoice_status', status ?? '');
    prefs.setInt('invoice_amount', amount ?? 0);
  }
  
  Future<void> _updateInvoiceStatus(String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('invoice_status', newStatus);
  }
}
```

### 4. Payment Screen

```dart
// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';

class PaymentScreen extends StatefulWidget {
  final int schoolId;
  final int studentId;
  final int amount;
  final String email;
  final String description;
  final List<int> feeIds;
  
  const PaymentScreen({
    required this.schoolId,
    required this.studentId,
    required this.amount,
    required this.email,
    required this.description,
    required this.feeIds,
  });
  
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late WebViewController _webViewController;
  
  @override
  void initState() {
    super.initState();
    _initializePayment();
  }
  
  void _initializePayment() async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    
    await provider.createInvoice(
      schoolId: widget.schoolId,
      studentId: widget.studentId,
      amount: widget.amount,
      email: widget.email,
      description: widget.description,
      feeIds: widget.feeIds,
    );
    
    if (provider.invoiceUrl != null) {
      _setupWebView();
      provider.pollInvoiceStatus();
    }
  }
  
  void _setupWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            print('Page loaded: $url');
          },
        ),
      )
      ..loadRequest(Uri.parse(
        Provider.of<PaymentProvider>(context, listen: false).invoiceUrl ?? ''
      ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bayar Invoice'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _initializePayment(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }
          
          if (provider.status == 'paid') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  const Text(
                    '✅ Pembayaran Berhasil',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }
          
          return WillPopScope(
            onWillPop: () async => false,
            child: WebViewWidget(controller: _webViewController),
          );
        },
      ),
    );
  }
}
```

---

## React Native Integration

### 1. Dependencies

```bash
npm install axios react-native-webview react-native-async-storage
# or
yarn add axios react-native-webview react-native-async-storage
```

### 2. Service

```javascript
// services/xenditService.js
import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

const API_BASE = 'http://your-api.com';
const SCHOOL_CODE = 'SCH20247';

const instance = axios.create({
  baseURL: API_BASE,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'school_code': SCHOOL_CODE,
  },
});

export const xenditService = {
  async createInvoice(
    schoolId,
    studentId,
    amount,
    email,
    description,
    feeIds
  ) {
    try {
      const response = await instance.post('/api/parent/fees/xendit/create', {
        school_id: schoolId,
        student_id: studentId,
        amount,
        email,
        description,
        fee_ids: feeIds,
      });
      return response.data;
    } catch (error) {
      throw error.response?.data || error;
    }
  },

  async getInvoiceStatus(invoiceId) {
    try {
      const response = await instance.get(
        `/api/parent/fees/xendit/status/${invoiceId}`
      );
      return response.data;
    } catch (error) {
      throw error.response?.data || error;
    }
  },

  async saveInvoiceData(invoiceId, status, amount) {
    try {
      await AsyncStorage.multiSet([
        ['invoice_id', invoiceId],
        ['invoice_status', status],
        ['invoice_amount', amount.toString()],
        ['invoice_created_at', new Date().toISOString()],
      ]);
    } catch (error) {
      console.error('Failed to save invoice data:', error);
    }
  },

  async getInvoiceData() {
    try {
      const data = await AsyncStorage.multiGet([
        'invoice_id',
        'invoice_status',
        'invoice_amount',
      ]);
      return {
        invoiceId: data[0][1],
        status: data[1][1],
        amount: data[2][1],
      };
    } catch (error) {
      console.error('Failed to get invoice data:', error);
    }
  },
};
```

### 3. Payment Context (State Management)

```javascript
// context/PaymentContext.js
import React, { createContext, useReducer } from 'react';
import { xenditService } from '../services/xenditService';

export const PaymentContext = createContext();

const initialState = {
  invoiceId: null,
  invoiceUrl: null,
  status: 'pending',
  amount: 0,
  isLoading: false,
  error: null,
};

function reducer(state, action) {
  switch (action.type) {
    case 'CREATE_START':
      return { ...state, isLoading: true, error: null };
    case 'CREATE_SUCCESS':
      return {
        ...state,
        invoiceId: action.payload.invoiceId,
        invoiceUrl: action.payload.invoiceUrl,
        status: action.payload.status,
        amount: action.payload.amount,
        isLoading: false,
      };
    case 'CREATE_ERROR':
      return { ...state, error: action.payload, isLoading: false };
    case 'UPDATE_STATUS':
      return { ...state, status: action.payload };
    default:
      return state;
  }
}

export function PaymentProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState);

  const createInvoice = async (
    schoolId,
    studentId,
    amount,
    email,
    description,
    feeIds
  ) => {
    dispatch({ type: 'CREATE_START' });
    try {
      const response = await xenditService.createInvoice(
        schoolId,
        studentId,
        amount,
        email,
        description,
        feeIds
      );

      if (!response.error) {
        await xenditService.saveInvoiceData(
          response.invoice_id,
          response.status,
          response.amount
        );

        dispatch({
          type: 'CREATE_SUCCESS',
          payload: {
            invoiceId: response.invoice_id,
            invoiceUrl: response.invoice_url,
            status: response.status,
            amount: response.amount,
          },
        });
      } else {
        dispatch({
          type: 'CREATE_ERROR',
          payload: response.message,
        });
      }
    } catch (error) {
      dispatch({
        type: 'CREATE_ERROR',
        payload: error.message,
      });
    }
  };

  const pollInvoiceStatus = async () => {
    if (!state.invoiceId) return;

    let pollCount = 0;
    const maxPolls = 60;

    const pollInterval = setInterval(async () => {
      pollCount++;

      try {
        const response = await xenditService.getInvoiceStatus(
          state.invoiceId
        );

        if (!response.error) {
          const { data } = response;

          if (data.is_paid) {
            dispatch({ type: 'UPDATE_STATUS', payload: 'paid' });
            clearInterval(pollInterval);
          } else if (data.is_expired) {
            dispatch({
              type: 'CREATE_ERROR',
              payload: 'Invoice expired',
            });
            clearInterval(pollInterval);
          }
        }
      } catch (error) {
        console.error('Poll error:', error);
      }

      if (pollCount >= maxPolls) {
        clearInterval(pollInterval);
        dispatch({
          type: 'CREATE_ERROR',
          payload: 'Polling timeout',
        });
      }
    }, 3000);
  };

  return (
    <PaymentContext.Provider
      value={{
        state,
        createInvoice,
        pollInvoiceStatus,
      }}
    >
      {children}
    </PaymentContext.Provider>
  );
}
```

### 4. Payment Screen Component

```javascript
// screens/PaymentScreen.js
import React, { useContext, useEffect } from 'react';
import {
  View,
  ActivityIndicator,
  Alert,
  StyleSheet,
} from 'react-native';
import { WebView } from 'react-native-webview';
import { PaymentContext } from '../context/PaymentContext';

export function PaymentScreen({ route, navigation }) {
  const { schoolId, studentId, amount, email, description, feeIds } =
    route.params;
  const { state, createInvoice, pollInvoiceStatus } =
    useContext(PaymentContext);

  useEffect(() => {
    initializePayment();
  }, []);

  const initializePayment = async () => {
    await createInvoice(
      schoolId,
      studentId,
      amount,
      email,
      description,
      feeIds
    );
  };

  useEffect(() => {
    if (state.invoiceId && state.status === 'pending') {
      pollInvoiceStatus();
    }
  }, [state.invoiceId]);

  useEffect(() => {
    if (state.status === 'paid') {
      handlePaymentSuccess();
    }
  }, [state.status]);

  const handlePaymentSuccess = () => {
    Alert.alert(
      '✅ Pembayaran Berhasil',
      'Terima kasih! Pembayaran SPP telah diterima.',
      [
        {
          text: 'OK',
          onPress: () => {
            navigation.reset({
              index: 0,
              routes: [{ name: 'Fees' }],
            });
          },
        },
      ]
    );
  };

  if (state.isLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  if (state.error) {
    return (
      <View style={styles.center}>
        <Text style={styles.error}>{state.error}</Text>
        <Button
          title="Coba Lagi"
          onPress={initializePayment}
        />
      </View>
    );
  }

  if (state.status === 'paid') {
    return (
      <View style={styles.center}>
        <Text style={styles.success}>✅ Pembayaran Berhasil</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {state.invoiceUrl && (
        <WebView
          source={{ uri: state.invoiceUrl }}
          style={styles.webview}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  webview: {
    flex: 1,
  },
  error: {
    fontSize: 16,
    color: 'red',
    marginBottom: 16,
  },
  success: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'green',
  },
});
```

---

## Implementation Patterns

### Error Handling Pattern

```
try {
  1. Create invoice
  2. If error → Show error, ask retry
  3. Save invoice_id locally
  4. Open checkout
  5. Start polling
} catch (e) {
  - Network error → Show message, offer retry
  - Validation error → Show specific error
  - Server error → Show contact support message
}

Polling:
- If is_paid → Success
- If is_expired → Ask create new invoice
- If timeout → Ask check manual
- If network error → Continue polling (don't stop)
```

### Retry Logic

```
Max 3 create attempts
Max 60 poll attempts (3 min with 3s interval)
Exponential backoff: 1s, 2s, 4s
```

### Local Storage

```
Save:
- invoice_id
- status
- amount
- created_at
- email

Restore:
- On app launch, check if payment pending
- Resume polling if applicable
```

---

## Testing on Device

### 1. Setup Test Server

```bash
# Forward local port
adb reverse tcp:8000 tcp:8000  # Android
# Or use ngrok for remote testing
ngrok http 8000
```

### 2. Configure Test API

```kotlin
// Android: Use local IP instead of localhost
const val BASE_URL = "http://192.168.x.x:8000"

// iOS: Update in Xcode settings
```

### 3. Test Payment Flow

```
1. Create invoice
2. Wait for checkout to load
3. Don't actually pay (optional - can test webhook manually)
4. Check poll status in logs
5. Trigger webhook test: ./xendit_test_complete.sh webhook {id}
6. See status update in app
```

---

## Production Deployment

- [ ] Update API URL to production domain
- [ ] Use HTTPS everywhere
- [ ] Add error tracking (Sentry, Bugsnag)
- [ ] Setup logging to server
- [ ] Configure timeout appropriately
- [ ] Test with real payments
- [ ] Monitor logs for errors
- [ ] Have support process ready

---

**Documentation Version**: 1.0  
**Last Updated**: Feb 4, 2026  
**Status**: ✅ Production Ready

