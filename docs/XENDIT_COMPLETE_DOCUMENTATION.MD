# 📱 Xendit Payment Integration - Complete Documentation

> Complete guide untuk mengintegrasikan Xendit payment gateway dengan eSchool API dan mobile apps

**Last Updated**: February 4, 2026
**Status**: ✅ Production Ready
**Version**: 1.0

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
3. [Setup & Configuration](#setup--configuration)
4. [How to Use - Web/Testing](#how-to-use---webtesting)
5. [Mobile App Integration](#mobile-app-integration)
6. [Error Handling](#error-handling)
7. [Testing Checklist](#testing-checklist)
8. [Troubleshooting](#troubleshooting)
9. [Production Deployment](#production-deployment)

---

## Overview

### What is This?

Xendit payment endpoint untuk school fees (SPP) payments. Orang tua bisa membayar invoice via berbagai metode pembayaran tanpa meninggalkan aplikasi.

### Supported Payment Methods

- 💳 **E-wallets**: DANA, OVO, LinkAja, ShopeePay
- 🏦 **Virtual Accounts**: BCA, Mandiri, BNI, BRI, Permata
- 🛒 **Retail**: Alfamart, Indomaret
- 📱 **QR Code**: QRIS
- 💰 **Cards**: Credit/Debit Card

### Architecture

```
┌─────────────┐
│ Mobile App  │
└──────┬──────┘
       │ school_code + student_id + amount
       ▼
┌─────────────────────────────────────┐
│ eSchool API                         │
│ POST /api/parent/fees/xendit/create │
└──────┬──────────────────────────────┘
       │ Create invoice
       ▼
┌─────────────────────────────────────┐
│ Xendit Gateway                      │
│ - Generate invoice_url              │
│ - Return invoice details            │
└──────┬──────────────────────────────┘
       │ invoice_url
       ▼
┌─────────────────────────────────────┐
│ Mobile App                          │
│ - Show payment options              │
│ - Redirect to Xendit checkout       │
│ - Poll status endpoint              │
└─────────────────────────────────────┘
```

---

## API Endpoints

### 1️⃣ Create Invoice / Initiate Payment

**Endpoint**: `POST /api/parent/fees/xendit/create`

**Purpose**: Create Xendit invoice untuk payment initiation

**Headers**:
```http
Content-Type: application/json
school_code: SCH20247
Accept: application/json
```

**Request Body**:
```json
{
  "school_id": 7,
  "student_id": 47,
  "amount": 100000,
  "email": "parent@example.com",
  "description": "SPP February 2026",
  "fee_ids": [42, 43]
}
```

**Request Field Details**:

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `school_id` | integer | ✅ | School ID in central database | 7 |
| `student_id` | integer | ✅ | Student ID dari school database | 47 |
| `amount` | integer | ✅ | Jumlah dalam IDR | 100000 |
| `email` | string | ✅ | Email penerima invoice | parent@email.com |
| `description` | string | ✅ | Deskripsi invoice | "SPP Feb 2026" |
| `fee_ids` | array | ✅ | Fee record IDs yang dibayar | [42, 43] |

**Response - Success (200 OK)**:
```json
{
  "error": false,
  "message": "Invoice created successfully",
  "invoice_id": "6981be8fe71121ff4d70d1a1",
  "invoice_url": "https://checkout-staging.xendit.co/web/6981be8fe71121ff4d70d1a1",
  "external_id": "SCHOOL_7_STUDENT_47_1707025408",
  "status": "pending",
  "amount": 100000,
  "expiry_date": "2026-02-05 09:23:27"
}
```

**Response - Error (400/500)**:
```json
{
  "error": true,
  "message": "Student 47 not found in school 7",
  "status": 400
}
```

**Possible Errors**:
- `school_code header required` (400) - Missing school_code header
- `Invalid school code` (400) - school_code tidak ditemukan
- `Xendit payment is not enabled for this school` (400) - Xendit belum diaktifkan untuk sekolah
- `Student X not found in school Y` (400) - Student ID tidak valid
- `Xendit API key not configured` (400) - API key tidak tersimpan di database
- `Failed to create invoice: ...` (500) - Xendit API error

---

### 2️⃣ Get Invoice Status

**Endpoint**: `GET /api/parent/fees/xendit/status/{invoiceId}`

**Purpose**: Check status pembayaran invoice

**Headers**:
```http
school_code: SCH20247
Accept: application/json
```

**URL Parameters**:
```
invoiceId: string (required) - Invoice ID dari endpoint #1
```

**Example Request**:
```bash
GET http://localhost:8000/api/parent/fees/xendit/status/6981be8fe71121ff4d70d1a1
Headers:
  school_code: SCH20247
```

**Response - Success (200 OK)**:
```json
{
  "error": false,
  "data": {
    "id": "6981be8fe71121ff4d70d1a1",
    "external_id": "SCHOOL_7_STUDENT_47_1770110607",
    "status": "paid",
    "amount": 100000,
    "invoice_url": "https://checkout-staging.xendit.co/web/6981be8fe71121ff4d70d1a1",
    "expiry_date": "2026-02-04 09:23:27",
    "payer_email": "test@example.com",
    "description": "Test SPP",
    "created_at": "2026-02-03 16:23:28",
    "paid_at": "2026-02-03 19:33:23",
    "is_expired": false,
    "is_paid": true,
    "school_id": 7,
    "student_id": 47
  }
}
```

**Status Values**:
- `pending` - Invoice created, waiting for payment
- `paid` - Payment received successfully
- `settled` - Payment settled to bank account
- `expired` - Invoice expired (24 hours)
- `failed` - Payment failed

**Response - Not Found (404)**:
```json
{
  "error": true,
  "message": "Invoice not found"
}
```

---

### 3️⃣ Webhook Callback (Internal)

**Endpoint**: `POST /api/parent/fees/xendit/webhook`

**Purpose**: Receive payment status updates dari Xendit (automatic callback)

**Important**: 
- ⚠️ **Xendit calls this automatically**, jangan dipanggil dari client
- Bukan untuk manual testing (gunakan test_webhook.sh)
- Validate callback token untuk security

**Headers Dari Xendit**:
```http
Content-Type: application/json
x-callback-token: Dicq7WWbo4Txr5nBHgUiE3W57aAAwvYlWn26CBTK1HwcStuC
```

**Payload From Xendit**:
```json
{
  "id": "6981be8fe71121ff4d70d1a1",
  "external_id": "SCHOOL_7_STUDENT_47_1770110607",
  "user_id": "user_123",
  "status": "PAID",
  "merchant_name": "Test School",
  "amount": 100000,
  "paid_amount": 100000,
  "bank_account_id": "ba_123",
  "payment_channel": "BANK_TRANSFER",
  "payment_method": "BANK_TRANSFER",
  "reference_id": "ref_123",
  "fees": 0,
  "currency": "IDR",
  "description": "Test SPP",
  "updated": "2026-02-04T00:00:00+00:00"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Webhook processed"
}
```

---

## Setup & Configuration

### Prerequisites

1. ✅ **Xendit Account**: Sudah ada
2. ✅ **API Keys**: Test dan Live keys tersimpan
3. ✅ **eSchool Database**: Central + per-school setup
4. ✅ **School Configuration**: xendit_enabled = 1

### Step 1: Set Environment Variables (.env)

```env
# Xendit Configuration
XENDIT_MODE=test                    # test atau live
XENDIT_SECRET_KEY=xnd_development_... # Global test key
XENDIT_CALLBACK_TOKEN=Dicq7WWbo4Tx... # Webhook security token
XENDIT_WEBHOOK_URL=https://yourdomain.com/api/parent/fees/xendit/webhook
```

### Step 2: Configure Per-School API Keys (Database)

Update `schools` table untuk setiap sekolah yang akan menggunakan Xendit:

```sql
UPDATE schools SET 
  xendit_enabled = 1,
  xendit_api_key_test = '[encrypted_test_key]',
  xendit_api_key_live = '[encrypted_live_key]',
  xendit_callback_token = 'Dicq7WWbo4Txr5nBHgUiE3W57aAAwvYlWn26CBTK1HwcStuC'
WHERE id = 7;
```

**How to Get Encrypted Keys**:
```php
// Di Laravel Tinker
$plainKey = 'xnd_development_...';
$encrypted = encrypt($plainKey);
echo $encrypted;

// Paste hasil ke database
```

### Step 3: Configure Xendit Webhook URL

1. Login ke **Xendit Dashboard** (https://dashboard.xendit.co)
2. Go to **Settings** → **Webhooks**
3. Add webhook URL:
   ```
   https://yourdomain.com/api/parent/fees/xendit/webhook
   ```
4. Select events:
   - ✅ Invoice paid
   - ✅ Invoice settled
   - ✅ Invoice expired
4. Verify callback token matches `.env` file

### Step 4: Verify Installation

```bash
# Test create invoice
curl -X POST http://localhost:8000/api/parent/fees/xendit/create \
  -H "Content-Type: application/json" \
  -H "school_code: SCH20247" \
  -d '{
    "school_id": 7,
    "student_id": 47,
    "amount": 100000,
    "email": "test@example.com",
    "description": "Test Payment",
    "fee_ids": [42, 43]
  }'

# Should return invoice_id and invoice_url
```

---

## How to Use - Web/Testing

### Using Insomnia (API Client)

#### 1. Create Invoice Request

**Set up Insomnia**:
1. Create new request → POST
2. URL: `http://localhost:8000/api/parent/fees/xendit/create`
3. Method: POST

**Headers Tab**:
```
school_code: SCH20247
Content-Type: application/json
Accept: application/json
```

**Body Tab** (JSON):
```json
{
  "school_id": 7,
  "student_id": 47,
  "amount": 100000,
  "email": "parent@example.com",
  "description": "SPP February 2026",
  "fee_ids": [42, 43]
}
```

**Send** → Get response dengan `invoice_id` dan `invoice_url`

#### 2. Check Status Request

**New Request** → GET

**URL**: `http://localhost:8000/api/parent/fees/xendit/status/6981be8fe71121ff4d70d1a1`

**Headers Tab**:
```
school_code: SCH20247
Accept: application/json
```

**Send** → Get invoice details dengan status "pending"

#### 3. Test Webhook Locally

```bash
# Run webhook test script
./test_webhook.sh

# Or manual curl:
curl -X POST http://localhost:8000/api/parent/fees/xendit/webhook \
  -H "Content-Type: application/json" \
  -H "x-callback-token: Dicq7WWbo4Txr5nBHgUiE3W57aAAwvYlWn26CBTK1HwcStuC" \
  -d '{
    "id": "6981be8fe71121ff4d70d1a1",
    "status": "PAID",
    "external_id": "SCHOOL_7_STUDENT_47_1770110607",
    "amount": 100000
  }'
```

---

## Mobile App Integration

### 📱 Android Integration (Kotlin/Java)

#### Step 1: Create Invoice

```kotlin
// 1. Prepare payment data
val paymentData = mapOf(
    "school_id" to 7,
    "student_id" to 47,
    "amount" to 100000,
    "email" to userEmail,
    "description" to "SPP February 2026",
    "fee_ids" to listOf(42, 43)
)

// 2. Call API to create invoice
val createInvoiceUrl = "$API_BASE_URL/api/parent/fees/xendit/create"

// Using Retrofit or HttpClient
val request = Request.Builder()
    .url(createInvoiceUrl)
    .post(RequestBody.create(
        MediaType.parse("application/json"),
        JSONObject(paymentData).toString()
    ))
    .addHeader("school_code", "SCH20247")
    .addHeader("Content-Type", "application/json")
    .build()

// 3. Execute request
client.newCall(request).enqueue(object : Callback {
    override fun onResponse(call: Call, response: Response) {
        if (response.isSuccessful) {
            val responseBody = response.body()?.string()
            val jsonResponse = JSONObject(responseBody)
            
            // Extract invoice details
            val invoiceId = jsonResponse.getString("invoice_id")
            val invoiceUrl = jsonResponse.getString("invoice_url")
            val status = jsonResponse.getString("status")
            
            // Save to local database for later reference
            saveInvoiceToLocal(invoiceId, status)
            
            // Open payment URL in WebView or redirect to browser
            openPaymentURL(invoiceUrl)
        } else {
            showError(response.message())
        }
    }
    
    override fun onFailure(call: Call, e: IOException) {
        showError("Network error: ${e.message}")
    }
})
```

#### Step 2: Display Payment Options

```kotlin
// Open Xendit checkout in WebView
private fun openPaymentURL(invoiceUrl: String) {
    val webView = WebView(this)
    webView.webViewClient = object : WebViewClient() {
        override fun onPageFinished(view: WebView?, url: String?) {
            super.onPageFinished(view, url)
            // Page loaded, show to user
        }
        
        override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
            // Handle redirect after payment
            if (url?.contains("payment/success") == true) {
                handlePaymentSuccess(view)
                return true
            }
            if (url?.contains("payment/failed") == true) {
                handlePaymentFailed(view)
                return true
            }
            return false
        }
    }
    
    webView.loadUrl(invoiceUrl)
    setContentView(webView)
}
```

#### Step 3: Poll Invoice Status

```kotlin
// Poll status setiap 3 detik
private fun pollInvoiceStatus(invoiceId: String) {
    val statusUrl = "$API_BASE_URL/api/parent/fees/xendit/status/$invoiceId"
    
    val pollTimer = Timer()
    pollTimer.scheduleAtFixedRate(object : TimerTask() {
        override fun run() {
            val request = Request.Builder()
                .url(statusUrl)
                .get()
                .addHeader("school_code", "SCH20247")
                .build()
            
            client.newCall(request).enqueue(object : Callback {
                override fun onResponse(call: Call, response: Response) {
                    val jsonResponse = JSONObject(response.body()?.string())
                    val status = jsonResponse.getJSONObject("data").getString("status")
                    val isPaid = jsonResponse.getJSONObject("data").getBoolean("is_paid")
                    
                    when {
                        isPaid -> {
                            pollTimer.cancel()
                            handlePaymentSuccess(invoiceId)
                        }
                        status == "expired" -> {
                            pollTimer.cancel()
                            showError("Invoice expired")
                        }
                    }
                }
                
                override fun onFailure(call: Call, e: IOException) {
                    Log.e("PaymentPoll", "Error: ${e.message}")
                }
            })
        }
    }, 0, 3000) // Start immediately, repeat every 3 seconds
}
```

#### Step 4: Handle Payment Result

```kotlin
private fun handlePaymentSuccess(invoiceId: String) {
    // Update local database
    updateInvoiceStatus(invoiceId, "paid")
    
    // Show success dialog
    AlertDialog.Builder(this)
        .setTitle("✅ Pembayaran Berhasil")
        .setMessage("Terima kasih! Pembayaran SPP telah diterima.")
        .setPositiveButton("OK") { _, _ ->
            // Refresh fees list or navigate to dashboard
            refreshFeesData()
        }
        .show()
}

private fun handlePaymentFailed(invoiceId: String) {
    AlertDialog.Builder(this)
        .setTitle("❌ Pembayaran Gagal")
        .setMessage("Pembayaran tidak berhasil. Silakan coba lagi.")
        .setPositiveButton("Coba Lagi") { _, _ ->
            // Retry payment flow
            createNewInvoice()
        }
        .show()
}
```

---

### 📱 Flutter Integration

#### Step 1: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  webview_flutter: ^4.0.0
  shared_preferences: ^2.0.0
```

#### Step 2: Payment Service

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class XenditPaymentService {
  final String apiBaseUrl;
  final String schoolCode;
  
  XenditPaymentService({
    required this.apiBaseUrl,
    required this.schoolCode,
  });
  
  // Create invoice
  Future<Map<String, dynamic>> createInvoice({
    required int schoolId,
    required int studentId,
    required int amount,
    required String email,
    required String description,
    required List<int> feeIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/parent/fees/xendit/create'),
        headers: {
          'Content-Type': 'application/json',
          'school_code': schoolCode,
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'school_id': schoolId,
          'student_id': studentId,
          'amount': amount,
          'email': email,
          'description': description,
          'fee_ids': feeIds,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create invoice: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Get invoice status
  Future<Map<String, dynamic>> getInvoiceStatus(String invoiceId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/parent/fees/xendit/status/$invoiceId'),
        headers: {
          'school_code': schoolCode,
          'Accept': 'application/json',
        },
      );
      
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

#### Step 3: Payment Screen Widget

```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class XenditPaymentScreen extends StatefulWidget {
  final String invoiceUrl;
  final String invoiceId;
  final VoidCallback onSuccess;
  
  const XenditPaymentScreen({
    required this.invoiceUrl,
    required this.invoiceId,
    required this.onSuccess,
  });

  @override
  State<XenditPaymentScreen> createState() => _XenditPaymentScreenState();
}

class _XenditPaymentScreenState extends State<XenditPaymentScreen> {
  late WebViewController _webViewController;
  
  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Check if payment completed
            if (url.contains('payment/success')) {
              _handlePaymentSuccess();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.invoiceUrl));
  }
  
  void _handlePaymentSuccess() {
    widget.onSuccess();
    Navigator.pop(context, true);
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        appBar: AppBar(title: const Text('Bayar Invoice')),
        body: WebViewWidget(controller: _webViewController),
      ),
    );
  }
}
```

#### Step 4: Usage in App

```dart
// In your payment flow
void initiatePayment() async {
  try {
    // Create invoice
    final result = await paymentService.createInvoice(
      schoolId: 7,
      studentId: 47,
      amount: 100000,
      email: userEmail,
      description: 'SPP February 2026',
      feeIds: [42, 43],
    );
    
    final invoiceId = result['invoice_id'];
    final invoiceUrl = result['invoice_url'];
    
    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => XenditPaymentScreen(
          invoiceUrl: invoiceUrl,
          invoiceId: invoiceId,
          onSuccess: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('✅ Berhasil'),
                content: const Text('Pembayaran telah diterima.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      refreshFeesList();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

### 📱 React Native Integration

#### Step 1: Install Dependencies

```bash
npm install axios react-native-webview
# or
yarn add axios react-native-webview
```

#### Step 2: Payment Service

```javascript
// services/xenditService.js
import axios from 'axios';

const API_BASE = 'http://your-api.com';
const SCHOOL_CODE = 'SCH20247';

export const xenditService = {
  // Create invoice
  async createInvoice(schoolId, studentId, amount, email, description, feeIds) {
    try {
      const response = await axios.post(
        `${API_BASE}/api/parent/fees/xendit/create`,
        {
          school_id: schoolId,
          student_id: studentId,
          amount: amount,
          email: email,
          description: description,
          fee_ids: feeIds,
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'school_code': SCHOOL_CODE,
            'Accept': 'application/json',
          },
        }
      );
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || error.message);
    }
  },

  // Get invoice status
  async getInvoiceStatus(invoiceId) {
    try {
      const response = await axios.get(
        `${API_BASE}/api/parent/fees/xendit/status/${invoiceId}`,
        {
          headers: {
            'school_code': SCHOOL_CODE,
            'Accept': 'application/json',
          },
        }
      );
      return response.data;
    } catch (error) {
      throw new Error(error.response?.data?.message || error.message);
    }
  },
};
```

#### Step 3: Payment Screen Component

```javascript
// screens/PaymentScreen.js
import React, { useState, useEffect } from 'react';
import { View, Alert, ActivityIndicator } from 'react-native';
import { WebView } from 'react-native-webview';
import { xenditService } from '../services/xenditService';

export const PaymentScreen = ({ route, navigation }) => {
  const { invoiceId, invoiceUrl } = route.params;
  const [loading, setLoading] = useState(true);
  const [pollInterval, setPollInterval] = useState(null);

  useEffect(() => {
    // Start polling invoice status
    const interval = setInterval(async () => {
      try {
        const result = await xenditService.getInvoiceStatus(invoiceId);
        if (result.data.is_paid) {
          clearInterval(interval);
          handlePaymentSuccess();
        }
      } catch (error) {
        console.error('Poll error:', error);
      }
    }, 3000); // Poll every 3 seconds

    setPollInterval(interval);

    return () => clearInterval(interval);
  }, [invoiceId]);

  const handlePaymentSuccess = () => {
    Alert.alert(
      'Pembayaran Berhasil',
      'Terima kasih! Pembayaran SPP telah diterima.',
      [
        {
          text: 'OK',
          onPress: () => {
            navigation.reset({
              index: 0,
              routes: [{ name: 'Dashboard' }],
            });
          },
        },
      ]
    );
  };

  return (
    <View style={{ flex: 1 }}>
      {loading && <ActivityIndicator size="large" />}
      <WebView
        source={{ uri: invoiceUrl }}
        onLoadEnd={() => setLoading(false)}
        javaScriptEnabled={true}
        domStorageEnabled={true}
      />
    </View>
  );
};
```

#### Step 4: Integration Flow

```javascript
// screens/FeesScreen.js
const handlePayNow = async (fee) => {
  try {
    setLoading(true);
    const result = await xenditService.createInvoice(
      schoolId,
      studentId,
      fee.amount,
      userEmail,
      `SPP ${fee.month}`,
      [fee.id]
    );

    navigation.navigate('Payment', {
      invoiceId: result.invoice_id,
      invoiceUrl: result.invoice_url,
    });
  } catch (error) {
    Alert.alert('Error', error.message);
  } finally {
    setLoading(false);
  }
};
```

---

## Error Handling

### Common Errors & Solutions

| Error | Status | Cause | Solution |
|-------|--------|-------|----------|
| `school_code header required` | 400 | Header tidak ada | Tambah `school_code` header |
| `Invalid school code` | 400 | school_code tidak ada di DB | Gunakan school code yang benar |
| `Student X not found` | 400 | Student ID salah | Verifikasi student_id milik sekolah |
| `Xendit not enabled` | 400 | xendit_enabled = 0 | Set xendit_enabled = 1 di database |
| `API key not configured` | 400 | Belum ada API key di DB | Simpan encrypted API key |
| `Payload invalid` | 500 | API key salah | Gunakan API key yang correct |
| `Network timeout` | - | Xendit service down | Retry atau hubungi support |
| `Invoice expired` | - | Invoice sudah 24 jam | Buat invoice baru |

### Error Response Format

```json
{
  "error": true,
  "message": "Detailed error message here",
  "status": 400
}
```

### Retry Logic (Recommended)

```kotlin
// Exponential backoff retry
fun <T> retryWithBackoff(
    maxRetries: Int = 3,
    block: suspend () -> T
): T {
    var lastException: Exception? = null
    
    repeat(maxRetries) { attempt ->
        try {
            return runBlocking { block() }
        } catch (e: Exception) {
            lastException = e
            if (attempt < maxRetries - 1) {
                val delay = (Math.pow(2.0, attempt.toDouble()) * 1000).toLong()
                Thread.sleep(delay)
            }
        }
    }
    
    throw lastException ?: Exception("Unknown error")
}

// Usage
val result = retryWithBackoff {
    paymentService.createInvoice(...)
}
```

---

## Testing Checklist

### Pre-Launch Testing

- [ ] **Authentication**
  - [ ] Test dengan school_code yang valid
  - [ ] Test tanpa school_code header → error 400
  - [ ] Test dengan school_code invalid → error 400

- [ ] **Invoice Creation**
  - [ ] Create invoice dengan data lengkap → success
  - [ ] Create dengan invalid student_id → error
  - [ ] Create dengan xendit_enabled=0 → error
  - [ ] Verify invoice tersimpan di database
  - [ ] Verify invoice_url bisa dibuka

- [ ] **Payment Simulation**
  - [ ] Click checkout → buka Xendit page
  - [ ] Simulasikan pembayaran di Xendit
  - [ ] Webhook callback terkirim otomatis
  - [ ] Status berubah menjadi "paid"
  - [ ] Database record terupdate

- [ ] **Status Polling**
  - [ ] Poll status setiap 3 detik
  - [ ] Status berubah saat payment received
  - [ ] Expired status setelah 24 jam

- [ ] **Mobile App**
  - [ ] Create invoice dari app
  - [ ] Open checkout di WebView
  - [ ] Simulate payment
  - [ ] Status updated dalam app
  - [ ] Success dialog muncul

### Performance Testing

- [ ] Response time < 2 seconds
- [ ] Handle 100 concurrent requests
- [ ] Database connection pooling works
- [ ] No memory leaks in polling

### Security Testing

- [ ] API key tidak terlihat di client
- [ ] Webhook token validated
- [ ] SQL injection prevention
- [ ] HTTPS enforced in production
- [ ] Rate limiting implemented

---

## Troubleshooting

### Invoice Creation Fails

**Problem**: "Failed to create invoice: payload invalid"

**Solution**:
1. Verify API key is correct: `php artisan tinker`
   ```php
   $school = App\Models\School::find(7);
   echo $school->xendit_api_key_test;
   ```
2. Check if key is encrypted properly
3. Try with global .env key first
4. Check Xendit API status page

### Webhook Not Received

**Problem**: Status stays "pending" after payment

**Solution**:
1. Check webhook URL configured in Xendit dashboard
2. Verify callback token matches `.env`
3. Check firewall allows Xendit IPs
4. Monitor logs: `tail -f storage/logs/laravel.log | grep webhook`
5. Test webhook manually: `./test_webhook.sh`

### Status Polling Timeout

**Problem**: Status never updates after 30+ seconds

**Solution**:
1. Verify webhook is working (check Xendit dashboard logs)
2. Check database transaction commit
3. Increase polling timeout to 60 seconds
4. Check if invoice exists: GET /api/parent/fees/xendit/status/{id}

### API Timeout in Mobile App

**Problem**: Create invoice request timeout after 10 seconds

**Solution**:
1. Increase timeout to 30 seconds
2. Check if server is running: `curl -I http://localhost:8000`
3. Check server logs for errors
4. Implement retry logic
5. Monitor network connection

---

## Production Deployment

### Pre-Production Checklist

- [ ] API key sudah di database (encrypted)
- [ ] Webhook URL updated ke production domain
- [ ] HTTPS enabled everywhere
- [ ] Rate limiting configured
- [ ] Error logging configured
- [ ] Database backups scheduled
- [ ] Monitoring/alerting setup
- [ ] Load testing completed

### Deployment Steps

```bash
# 1. Update .env
XENDIT_MODE=live
XENDIT_SECRET_KEY=xnd_production_...
XENDIT_WEBHOOK_URL=https://prod-domain.com/api/parent/fees/xendit/webhook

# 2. Update database for each school
UPDATE schools SET 
  xendit_api_key_test = encrypt('xnd_development_...'),
  xendit_api_key_live = encrypt('xnd_production_...'),
  xendit_callback_token = 'your_callback_token'
WHERE id IN (1, 2, 3, ...);

# 3. Clear caches
php artisan config:clear
php artisan cache:clear

# 4. Verify configuration
php artisan tinker
>>> config('app.env')     // Should be "production"
>>> config('services.xendit.mode')  // Should be "live"

# 5. Test create invoice
curl -X POST https://prod-domain.com/api/parent/fees/xendit/create ...

# 6. Monitor logs
tail -f storage/logs/laravel.log

# 7. Inform stakeholders
```

### Production Monitoring

```bash
# Monitor invoice creation
grep "Invoice created successfully" storage/logs/laravel.log | tail -20

# Monitor payment received
grep "Xendit payment marked as paid" storage/logs/laravel.log | tail -20

# Monitor errors
grep "ERROR" storage/logs/laravel.log | tail -50

# Database check
SELECT COUNT(*) FROM xendit_invoices WHERE created_at > NOW() - INTERVAL 1 HOUR;
SELECT COUNT(*) FROM xendit_invoices WHERE status = 'paid' AND created_at > NOW() - INTERVAL 1 HOUR;
```

### Scaling Considerations

- Enable database connection pooling
- Setup Redis for session caching
- Implement invoice caching (5 min TTL)
- Use async job processing for webhooks
- Setup CDN for invoice_url redirects

---

## FAQ

### Q: Berapa biaya per transaksi?

A: Sesuai pricing Xendit. Biasanya 1-2% dari jumlah. Cek di https://xendit.co/pricing

### Q: Berapa lama invoice valid?

A: Default 24 jam dari creation time. Bisa diubah di XenditService.php line 72.

### Q: Bisa pay now, pay later?

A: Xendit mendukung BNPL (SoftPay, Akulaku, dll). Tambahkan ke `payment_methods` array.

### Q: Gimana kalau orang tua bayar sebagian?

A: Buat beberapa invoice dengan amount berbeda, atau gunakan Xendit splitting feature.

### Q: Bisa refund?

A: Ya, lewat Xendit dashboard atau API. Implement di refund endpoint terpisah.

### Q: Gimana tracking orang tua?

A: Orang tua bisa lihat status via app dengan polling getInvoiceStatus endpoint.

### Q: Database usage gimana?

A: 1 row per invoice di xendit_invoices. Cleanup after 90 days recommended.

### Q: Timezone?

A: Already handled by SetSchoolTimezone middleware. Check app/config/app.php

---

## Support & Resources

- **Xendit API Docs**: https://xendit.co/developers
- **eSchool API Docs**: See XENDIT_FIX_COMPLETE.md
- **Test Endpoint**: http://localhost:8000/api/parent/fees/xendit/status/{id}
- **Logs Location**: storage/logs/laravel.log

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-04 | Initial release - All 3 endpoints working |

---

**Last Updated**: Feb 4, 2026  
**Status**: ✅ Production Ready  
**Maintained By**: Engineering Team

